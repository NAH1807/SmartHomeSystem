// Control relay, fan 
const {
    TOPICS,
    publish,
    isConnected,
} = require('../services/mqtt');

const { pool } = require('../config/database');

async function mqttStatus(req, res) {
    res.json({
        connected: isConnected(),
        broker: {
            host: process.env.MQTT_HOST || '100.127.206.76',
            port: Number(process.env.MQTT_PORT || 1883),
        },
    });
}

/*
 * RELAY CHANNEL
 *
 * POST /api/mqtt/relay/channel
 *
 * {
 *   "device_uid": "ESP32-RELAY-01",
 *   "channel": 1,
 *   "state": true
 * }
 */
async function relayChannel(req, res) {
    try {
        const {
            device_uid,
            channel,
            state,
        } = req.body;

        if (!device_uid) {
            return res.status(400).json({
                message: 'device_uid is required',
            });
        }

        const channelNumber =
            Number(channel);

        if (
            !Number.isInteger(channelNumber) ||
            channelNumber < 1 ||
            channelNumber > 4
        ) {
            return res.status(400).json({
                message:
                    'channel must be between 1 and 4',
            });
        }

        const topic =
            await getControlTopic(
                device_uid,
                TOPICS.relayControl,
            );

        const payload = {
            action: 'SET_CHANNEL',
            channel: channelNumber,
            state: Boolean(state),
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: error.message,
        });
    }
}

/*
 * RELAY ALL
 */
async function relayAll(req, res) {
    try {
        const {
            device_uid,
            state,
        } = req.body;

        if (!device_uid) {
            return res.status(400).json({
                message: 'device_uid is required',
            });
        }

        const topic =
            await getControlTopic(
                device_uid,
                TOPICS.relayControl,
            );

        const payload = {
            action: 'SET_ALL',
            state: Boolean(state),
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
}

/*
 * FAN
 *
 * POST /api/mqtt/fan/level
 *
 * {
 *   "device_uid": "ESP32-FAN-01",
 *   "level": 2
 * }
 */
async function fanLevel(req, res) {
    try {
        const {
            device_uid,
            level,
        } = req.body;

        if (!device_uid) {
            return res.status(400).json({
                message: 'device_uid is required',
            });
        }

        const fanLevel =
            Number(level);

        if (
            !Number.isInteger(fanLevel) ||
            fanLevel < 0 ||
            fanLevel > 3
        ) {
            return res.status(400).json({
                message:
                    'level must be between 0 and 3',
            });
        }

        const topic =
            await getControlTopic(
                device_uid,
                TOPICS.fanControl,
            );

        const payload = {
            action: 'SET_LEVEL',
            level: fanLevel,
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
}


/*
 * MOTION
 */
async function motion(req, res) {
    try {
        const deviceId = Number(req.params.deviceId);
        const { name, settings } = req.body;

        // Validate device ID
        if (!Number.isInteger(deviceId) || deviceId <= 0) {
            return res.status(400).json({
                message: 'Invalid device ID',
            });
        }

        // Validate settings
        if (
            !settings ||
            typeof settings !== 'object' ||
            Array.isArray(settings)
        ) {
            return res.status(400).json({
                message: 'Invalid device settings',
            });
        }

        if (!isConnected()) {
            return res.status(503).json({
                message: 'MQTT broker is not connected',
            });
        }

        // Get device information
        const rows = await pool.query(
            `
            SELECT
                device_uid,
                device_type,
                config_topic,
                profile_version
            FROM devices
            WHERE id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        if (!rows.length) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        const device = rows[0];

        if (!device.device_uid) {
            return res.status(400).json({
                message: 'Device is not linked to MQTT',
            });
        }

        // Convert value to boolean
        const toBoolean = (value) =>
            value === true ||
            value === 1 ||
            value === '1' ||
            value === 'true';

        // Copy all settings to avoid losing other configurations
        const mqttSettings = {
            ...settings,
        };

        // ==========================================
        // FAN MOTION
        // ==========================================
        if (device.device_type === 'fan') {
            if (!settings.motion) {
                return res.status(400).json({
                    message: 'Fan motion configuration is required',
                });
            }

            // Lấy default_level từ bảng automations
            const automationRows = await pool.query(
                `
                SELECT default_level
                FROM automations
                WHERE device_id = ?
                `,
                [deviceId]
            );
            
            const motionConfig = settings.motion;
            defaultLevel = motionConfig.enabled === false ? 0 : automationRows[0]?.default_level;
            mqttSettings.default_level = defaultLevel;
            mqttSettings.motion = {
                enabled: toBoolean(motionConfig.enabled),
                sensor_id: 'PIR-FAN-01',
                gpio: 22,
                hold_seconds: Number(motionConfig.hold_seconds),
                cooldown_seconds: Number(motionConfig.cooldown_seconds),
            };
        }

        // ==========================================
        // RELAY MOTION
        // ==========================================
        else if (device.device_type === 'relay') {
            if (!Array.isArray(settings.channels)) {
                return res.status(400).json({
                    message: 'Relay channels configuration is required',
                });
            }

            const gpioMap = {
                1: 16,
                2: 17,
                3: 25,
                4: 26,
            };

            mqttSettings.channels = settings.channels.map((channel) => {
                const motionConfig = channel.motion || {};

                return {
                    id: channel.id,
                    automation_mode: channel.automation_mode,
                    motion: {
                        sensor_id: motionConfig.sensor_id || null,
                        // GPIO được xác định theo số kênh
                        gpio: gpioMap[channel.id] ?? null,
                        configured: true,
                        hold_seconds: Number(
                            motionConfig.hold_seconds ?? 120,
                        ),
                        cooldown_seconds: Number(
                            motionConfig.cooldown_seconds ?? 3,
                        ),
                    },
                };
            });
        } else {
            return res.status(400).json({
                message: 'Motion is not supported for this device type',
            });
        }

        // ==========================================
        // CREATE MQTT PROFILE
        // ==========================================
        const version =
            Number(device.profile_version || 0) + 1;

        const topic =
            device.config_topic ||
            `smarthome/device/${device.device_uid
                .toLowerCase()
                .replace('esp32-', '')}/config`;

        const payload = {
            device_id: device.device_uid,
            version,
            name: name || device.device_uid,
            settings: mqttSettings,
        };

        // Publish configuration to MQTT
        await publish(
            topic,
            payload,
            {
                qos: 1,
                retain: true,
            },
        );

        // Update profile version
        await pool.query(
            `
            UPDATE devices
            SET profile_version = ?
            WHERE id = ?
            `,
            [version, deviceId],
        );

        return res.json({
            success: true,
            message: 'Motion configuration published successfully',
            version,
            topic,
            payload,
        });

    } catch (error) {
        console.error('MQTT Motion Error:', error);

        return res.status(500).json({
            message: error.message,
        });
    }
}

/*
 * CAMERA SECURITY
 *
 * POST /api/mqtt/camera/security
 */
async function cameraSecurity(req, res) {
    try {
        const {
            device_uid,
            state,
        } = req.body;

        const allowed = [
            'NORMAL',
            'SUSPICIOUS',
            'ATTACKED',
        ];

        if (!device_uid) {
            return res.status(400).json({
                message: 'device_uid is required',
            });
        }

        if (!allowed.includes(state)) {
            return res.status(400).json({
                message:
                    'Invalid security state',
            });
        }

        const topic =
            await getSecurityTopic(
                device_uid,
            );

        const payload = {
            action: 'SET_SECURITY_STATE',
            state,
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
}

/*
 * QUARANTINE
 */
async function quarantine(req, res) {
    try {
        const deviceUid =
            req.params.deviceUid;

        const reason =
            req.body?.reason ||
            'Manual test';

        const topic =
            `smarthome/security/${deviceUid}`;

        const payload = {
            device_id: deviceUid,
            action: 'QUARANTINE',
            reason,
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
}

/*
 * RELEASE
 */
async function release(req, res) {
    try {
        const deviceUid =
            req.params.deviceUid;

        const reason =
            req.body?.reason ||
            'Manual test';

        const topic =
            `smarthome/security/${deviceUid}`;

        const payload = {
            device_id: deviceUid,
            action: 'RELEASE',
            reason,
        };

        await publish(
            topic,
            payload,
        );

        res.json({
            success: true,
            topic,
            payload,
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
}



async function syncProfile(req, res) {
    try {
        const deviceId = Number(req.params.deviceId);

        const {
            name,
            settings,
        } = req.body;

        // Validate device ID
        if (!Number.isInteger(deviceId) || deviceId <= 0) {
            return res.status(400).json({
                message: 'Invalid device ID',
            });
        }

        // Validate settings
        if (
            !settings ||
            typeof settings !== 'object' ||
            Array.isArray(settings)
        ) {
            return res.status(400).json({
                message: 'Invalid device settings',
            });
        }

        // Get device information
        const rows = await pool.query(
            `
            SELECT
                device_uid,
                device_type,
                config_topic,
                profile_version
            FROM devices
            WHERE id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        if (!rows.length) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        const device = rows[0];

        if (!device.device_uid) {
            return res.status(400).json({
                message: 'Device is not linked to MQTT',
            });
        }

        // Create settings payload
        const mqttSettings = {
            ...settings,
        };

        // ==========================================
        // MOTION CONFIGURATION
        // ==========================================

        // FAN: Motion configuration
        if (device.device_type === 'fan') {
            if (settings.motion) {
                const motion = settings.motion;

                mqttSettings.motion = {
                    enabled: motion.enabled === true ||
                        motion.enabled === 1 ||
                        motion.enabled === '1',
                    hold_seconds: Number(motion.hold_seconds),
                    cooldown_seconds: Number(motion.cooldown_seconds),
                };
            }
        }

        // RELAY: Motion configuration for each channel
        if (device.device_type === 'relay') {
            if (Array.isArray(settings.channels)) {
                mqttSettings.channels = settings.channels.map(
                    (channel) => {
                        const motion = channel.motion || {};

                        return {
                            ...channel,

                            motion: {
                                sensor_id: motion.sensor_id || '',

                                gpio: motion.gpio ?? null,

                                configured:
                                    motion.configured === true ||
                                    motion.configured === 1 ||
                                    motion.configured === '1',

                                hold_seconds: Number(
                                    motion.hold_seconds ?? 120
                                ),

                                cooldown_seconds: Number(
                                    motion.cooldown_seconds ?? 3
                                ),
                            },
                        };
                    }
                );
            }
        }

        // ==========================================
        // MQTT PROFILE
        // ==========================================

        const version =
            Number(device.profile_version || 0) + 1;

        const topic =
            device.config_topic ||
            `smarthome/device/${device.device_uid
                .toLowerCase()
                .replace('esp32-', '')}/config`;

        const payload = {
            device_id: device.device_uid,
            version,
            name: name || device.device_uid,
            settings: mqttSettings,
        };

        // Publish MQTT
        await publish(
            topic,
            payload,
            {
                qos: 1,
                retain: true,
            },
        );

        // Update profile version
        await pool.query(
            `
            UPDATE devices
            SET profile_version = ?
            WHERE id = ?
            `,
            [
                version,
                deviceId,
            ],
        );

        res.json({
            success: true,
            version,
            topic,
            payload,
        });

    } catch (error) {
        console.error('MQTT Profile Sync Error:', error);

        res.status(500).json({
            message: error.message,
        });
    }
}



async function getControlTopic(
    deviceUid,
    fallback,
) {
    const rows =
        await pool.query(
            `
            SELECT control_topic
            FROM devices
            WHERE device_uid = ?
            LIMIT 1
            `,
            [deviceUid],
        );

    return (
        rows[0]?.control_topic ||
        fallback
    );
}

async function getSecurityTopic(
    deviceUid,
) {
    const rows =
        await pool.query(
            `
            SELECT security_topic
            FROM devices
            WHERE device_uid = ?
            LIMIT 1
            `,
            [deviceUid],
        );

    return (
        rows[0]?.security_topic ||
        `smarthome/device/${shortDeviceId(deviceUid)}/security`
    );
}

function shortDeviceId(deviceUid) {
    return String(deviceUid)
        .toLowerCase()
        .replace('esp32-', '')
        .replace(/_/g, '')
        .replace(/-/g, '');
}

module.exports = {
    mqttStatus,
    relayChannel,
    relayAll,
    fanLevel,
    motion,
    cameraSecurity,
    quarantine,
    release,
    syncProfile,
};