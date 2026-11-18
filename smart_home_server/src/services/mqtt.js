const mqtt = require('mqtt');
const { pool } = require('../config/database');

const MQTT_HOST = process.env.MQTT_HOST || '100.127.206.76';
const MQTT_PORT = Number(process.env.MQTT_PORT || 1883);

const TOPICS = {
    relayStatus: 'smarthome/device/relay01/status',
    relayTelemetry: 'smarthome/device/relay01/telemetry',
    relayControl: 'smarthome/device/relay01/control',

    fanStatus: 'smarthome/device/fan01/status',
    fanTelemetry: 'smarthome/device/fan01/telemetry',
    fanControl: 'smarthome/device/fan01/control',

    cameraStatus: 'smarthome/device/cam01/status',
    cameraSecurity: 'smarthome/device/cam01/security',

    security: 'smarthome/security/#',

    announce: 'smarthome/device/announce',
    register: 'smarthome/device/register',

    configAck: 'smarthome/device/+/config_ack',
};

let client = null;
let connected = false;

function getClient() {
    return client;
}

function isConnected() {
    return connected && client?.connected;
}

async function connectMqtt() {
    if (client) {
        return;
    }

    const options = {
        clientId: `SmartHome-Server-${Date.now()}`,
        username: process.env.MQTT_USERNAME || '',
        password: process.env.MQTT_PASSWORD || '',
        clean: true,
        reconnectPeriod: 0,
        connectTimeout: 10000,
    };

    const url = `mqtt://${MQTT_HOST}:${MQTT_PORT}`;
    console.log(`[MQTT] Connecting ${url}`);
    client = mqtt.connect(url, options);
    client.on('connect', async () => {
        connected = true;

        console.log(
            `[MQTT] Connected ${MQTT_HOST}:${MQTT_PORT}`,
        );

        await subscribeTopics();
    });

    client.on('reconnect', () => {
        console.log('[MQTT] Reconnecting...');
    });

    client.on('close', () => {
        connected = false;
        console.log('[MQTT] Disconnected');
    });

    client.on('error', (error) => {
        console.error('[MQTT] Error:', error.message);
    });

    client.on('message', async (topic, payload, packet) => {
        try {
            await handleMessage(
                topic,
                payload,
                packet,
            );
        } catch (error) {
            console.error(
                '[MQTT] Message handler error:',
                error,
            );
        }
    });
}

function subscribeTopics() {
    return new Promise((resolve) => {
        if (!client) {
            resolve();
            return;
        }

        const topics = [
            TOPICS.relayStatus,
            TOPICS.relayTelemetry,
            TOPICS.fanStatus,
            TOPICS.fanTelemetry,
            TOPICS.cameraStatus,
            TOPICS.cameraSecurity,
            TOPICS.security,
            TOPICS.announce,
            TOPICS.register,
            TOPICS.configAck,
        ];

        client.subscribe(
            topics,
            { qos: 0 },
            (error, granted) => {
                if (error) {
                    console.error(
                        '[MQTT] Subscribe error:',
                        error,
                    );
                } else {
                    console.log(
                        '[MQTT] Subscribed:',
                        granted,
                    );
                }

                resolve();
            },
        );
    });
}

function publish(
    topic,
    payload,
    options = {},
) {
    return new Promise((resolve, reject) => {
        if (!isConnected()) {
            reject(
                new Error('MQTT broker is not connected'),
            );
            return;
        }

        const data =
            typeof payload === 'string'
                ? payload
                : JSON.stringify(payload);

        client.publish(
            topic,
            data,
            {
                qos: options.qos ?? 0,
                retain: options.retain ?? false,
            },
            (error) => {
                if (error) {
                    reject(error);
                    return;
                }

                console.log(
                    `[MQTT] PUB ${topic}: ${data}`,
                );

                resolve();
            },
        );
    });
}

async function handleMessage(
    topic,
    payloadBuffer,
    packet,
) {
    const raw = payloadBuffer
        .toString()
        .trim();

    console.log(
        `[MQTT] MSG ${topic}: ${raw}`,
    );

    let data;

    try {
        data = JSON.parse(raw);
    } catch {
        return;
    }

    /*
     * Discovery
     */
    if (
        topic === TOPICS.announce ||
        topic === TOPICS.register
    ) {
        if (packet?.retain) {
            return;
        }

        await handleDiscovery(data);
        return;
    }

    /*
     * Config ACK
     */
    if (topic.endsWith('/config_ack')) {
        await handleConfigAck(data);
        return;
    }

    /*
     * Relay
     */
    if (
        topic === TOPICS.relayStatus ||
        topic === TOPICS.relayTelemetry
    ) {
        await handleRelay(data);
        return;
    }

    /*
     * Fan
     */
    if (
        topic === TOPICS.fanStatus ||
        topic === TOPICS.fanTelemetry
    ) {
        await handleFan(data);
        return;
    }

    /*
     * Camera
     */
    if (topic === TOPICS.cameraStatus) {
        await handleCameraStatus(data);
        return;
    }

    if (topic === TOPICS.cameraSecurity) {
        await handleCameraSecurity(data);
        return;
    }

    /*
     * Security / quarantine
     */
    if (topic.startsWith('smarthome/security/')) {
        await handleSecurity(data);
    }
}

async function handleDiscovery(data) {
    const deviceUid =
        data.device_id?.toString();

    if (!deviceUid) {
        return;
    }

    const deviceType =
        normalizeDeviceType(data.type);

    const name =
        data.name?.toString() ||
        deviceUid;

    const ip =
        data.ip?.toString() || null;

    const configTopic =
        data.config_topic?.toString() ||
        null;

    const controlTopic =
        data.control_topic?.toString() ||
        null;

    const securityTopic =
        data.security_topic?.toString() ||
        null;

    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            INSERT INTO devices (
                name,
                device_type,
                icon,
                mqtt_topic,
                device_uid,
                device_ip,
                config_topic,
                control_topic,
                security_topic,
                is_online
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE
                name = VALUES(name),
                device_ip = VALUES(device_ip),
                config_topic = VALUES(config_topic),
                control_topic = VALUES(control_topic),
                security_topic = VALUES(security_topic),
                is_online = 1
            `,
            [
                name,
                deviceType,
                'devices',
                controlTopic,
                deviceUid,
                ip,
                configTopic,
                controlTopic,
                securityTopic,
            ],
        );

        console.log(
            `[MQTT] Device discovered: ${deviceUid}`,
        );
    } finally {
        conn.release();
    }
}

async function handleConfigAck(data) {
    const deviceUid =
        data.device_id?.toString();

    if (!deviceUid) {
        return;
    }

    const version =
        Number(data.version || 0);

    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            UPDATE devices
            SET
                device_version = ?,
                profile_version = ?,
                is_online = 1
            WHERE device_uid = ?
            `,
            [
                version,
                version,
                deviceUid,
            ],
        );
    } finally {
        conn.release();
    }
}


async function handleRelay(data) {
    const deviceUid =
        data.device_id?.toString() ||
        'ESP32-RELAY-01';

    const online =
        data.online !== false;

    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            UPDATE devices
            SET is_online = ?
            WHERE device_uid = ?
            `,
            [
                online ? 1 : 0,
                deviceUid,
            ],
        );

        /*
         * Relay test app supports:
         *
         * relay1
         * relay2
         * relay3
         * relay4
         *
         * or:
         *
         * channels: [
         *   { id: 1, state: true }
         * ]
         *
         * Current SmartHome DB has one is_on state.
         * Therefore the first active channel is used
         * as the aggregate device state.
         */
        let isOn = null;

        for (let i = 1; i <= 4; i++) {
            const key = `relay${i}`;

            if (
                Object.prototype.hasOwnProperty.call(
                    data,
                    key,
                )
            ) {
                if (data[key] === true) {
                    isOn = true;
                    break;
                }

                if (isOn === null) {
                    isOn = false;
                }
            }
        }

        if (Array.isArray(data.channels)) {
            for (const channel of data.channels) {
                if (channel?.state === true) {
                    isOn = true;
                    break;
                }

                if (
                    isOn === null &&
                    channel?.state === false
                ) {
                    isOn = false;
                }
            }
        }

        if (isOn !== null) {
            await conn.query(
                `
                INSERT INTO device_states (
                    device_id,
                    is_on
                )
                SELECT id, ?
                FROM devices
                WHERE device_uid = ?
                ON DUPLICATE KEY UPDATE
                    is_on = VALUES(is_on)
                `,
                [
                    isOn ? 1 : 0,
                    deviceUid,
                ],
            );
        }
    } finally {
        conn.release();
    }
}

async function handleFan(data) {
    const deviceUid =
        data.device_id?.toString() ||
        'ESP32-FAN-01';

    const online =
        data.online !== false;

    const temperature =
        toNumberOrNull(data.temperature);

    const humidity =
        toNumberOrNull(data.humidity);

    const fanLevel =
        toNumberOrNull(data.fan_level);

    const fanPercent =
        toNumberOrNull(data.fan_percent);

    const isOn =
        fanLevel !== null
            ? fanLevel > 0
            : fanPercent !== null
                ? fanPercent > 0
                : null;

    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            UPDATE devices
            SET is_online = ?
            WHERE device_uid = ?
            `,
            [
                online ? 1 : 0,
                deviceUid,
            ],
        );

        const deviceResult =
            await conn.query(
                `
                SELECT id
                FROM devices
                WHERE device_uid = ?
                LIMIT 1
                `,
                [deviceUid],
            );

        if (!deviceResult.length) {
            return;
        }

        const deviceId =
            Number(deviceResult[0].id);

        await conn.query(
            `
            INSERT INTO device_states (
                device_id,
                is_on,
                intensity,
                temperature,
                humidity,
                fan_speed
            )
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                is_on = VALUES(is_on),
                intensity = VALUES(intensity),
                temperature = VALUES(temperature),
                humidity = VALUES(humidity),
                fan_speed = VALUES(fan_speed)
            `,
            [
                deviceId,
                isOn === null ? 0 : isOn ? 1 : 0,
                fanPercent ?? 0,
                temperature,
                humidity,
                fanLevel,
            ],
        );
    } finally {
        conn.release();
    }
}

async function handleCameraStatus(data) {
    const deviceUid =
        data.device_id?.toString() ||
        'ESP32-CAM-01';

    const online =
        data.online !== false;

    const securityState =
        data.security_state?.toString() ||
        'NORMAL';

    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            UPDATE devices
            SET
                is_online = ?,
                security_state = ?
            WHERE device_uid = ?
            `,
            [
                online ? 1 : 0,
                securityState,
                deviceUid,
            ],
        );
    } finally {
        conn.release();
    }
}

async function handleCameraSecurity(data) {
    const deviceUid =
        data.device_id?.toString() ||
        'ESP32-CAM-01';

    const state =
        data.state?.toString() ||
        data.security_state?.toString() ||
        'NORMAL';

    await updateSecurityState(
        deviceUid,
        state,
    );
}

async function handleSecurity(data) {
    const deviceUid =
        data.device_id?.toString();

    if (!deviceUid) {
        return;
    }

    const action =
        data.action?.toString();

    if (action === 'QUARANTINE') {
        await updateSecurityState(
            deviceUid,
            'ATTACKED',
        );
    }

    if (action === 'RELEASE') {
        await updateSecurityState(
            deviceUid,
            'NORMAL',
        );
    }
}

async function updateSecurityState(
    deviceUid,
    state,
) {
    const conn = await pool.getConnection();

    try {
        await conn.query(
            `
            UPDATE devices
            SET security_state = ?
            WHERE device_uid = ?
            `,
            [
                state,
                deviceUid,
            ],
        );
    } finally {
        conn.release();
    }
}

function normalizeDeviceType(type) {
    const value =
        String(type || '')
            .toLowerCase();

    if (value === 'relay') {
        return 'relay';
    }

    if (value === 'fan') {
        return 'fan';
    }

    if (value === 'camera') {
        return 'camera';
    }

    return 'relay';
}

function toNumberOrNull(value) {
    if (
        value === null ||
        value === undefined
    ) {
        return null;
    }

    const number =
        Number(value);

    return Number.isFinite(number)
        ? number
        : null;
}

// Automation
const WEEKDAY_NAMES = [
    'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'
];

function normalizeRelayDays(days) {
    if (!Array.isArray(days) || days.length === 0) {
        return [...WEEKDAY_NAMES];
    }

    return [...new Set(
        days
            .map(Number)
            .filter(day => day >= 1 && day <= 7)
            .map(day => WEEKDAY_NAMES[day - 1]),
    )];
}

function normalizeMotion(motion = {}, isRelay = false) {
    const holdSeconds = Number(motion.hold_seconds);
    const cooldownSeconds = Number(motion.cooldown_seconds);
    const result = {
        hold_seconds:
            Number.isInteger(holdSeconds) && holdSeconds > 0
                ? holdSeconds
                : 120,
        cooldown_seconds:
            Number.isInteger(cooldownSeconds) &&
                cooldownSeconds > 0
                ? cooldownSeconds
                : 3,
    };

    if (isRelay) {
        result.configured = motion.enabled
    } else {
        result.enabled = motion.enabled
    }

    return result;
}

async function publishRelayProfile(deviceId, profile) {
    if (!isConnected()) {
        throw new Error('MQTT broker is not connected');
    }

    const conn = await pool.getConnection();

    try {
        const rows = await conn.query(
            `
            SELECT
                id,
                name,
                device_uid,
                device_type,
                config_topic
            FROM devices
            WHERE id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        if (!rows.length) {
            throw new Error('Device not found');
        }

        const device = rows[0];

        if (device.device_type !== 'relay') {
            throw new Error('Device is not a relay');
        }

        if (!device.device_uid || !device.config_topic) {
            throw new Error(
                'Device UID or config_topic is missing',
            );
        }

        const incomingChannels = Array.isArray(profile.relayChannels)
            ? profile.relayChannels
            : [];

        const channelMap = new Map();

        for (const item of incomingChannels) {
            const id = Number(item.channel ?? item.id);

            if (Number.isInteger(id) && id >= 1 && id <= 4) {
                channelMap.set(id, item);
            }
        }

        // Firmware requires exactly four channels.
        const channels = [];

        for (let id = 1; id <= 4; id++) {
            const item = channelMap.get(id) || {};
            const selected = item.enabled === true;

            const days = normalizeRelayDays(
                item.daysOnWeek ?? profile.daysOnWeek,
            );

            const motion = normalizeMotion(
                item.motion || {},
                true,
            );
            const motionMode = (motion.enabled === true && selected === 'schedule') ? 'schedule_motion' : 'manual';
            channels.push({
                name: item.name || `Relay ${id}`,
                room: item.room || '',
                automation_mode: motionMode,
                motion,
                mode: selected ? 'schedule' : 'manual',
                default_state: item.defaultState === true,
                schedule_on:
                    item.timeOn ||
                    profile.timeOn ||
                    '08:00',
                schedule_off:
                    item.timeOff ||
                    profile.timeOff ||
                    '22:00',
                schedule_days: days,
            });
        }



        const payload = {
            device_id: device.id,
            version: Number(profile.profileVersion),
            name: device.name || device.device_uid,
            room: '',
            settings: {
                channels,
            },
        };

        if (
            !Number.isInteger(payload.version) ||
            payload.version < 1
        ) {
            throw new Error('Invalid profile version');
        }

        await publish(device.config_topic, payload, {
            qos: 1,
            retain: true,
        });

        return {
            topic: device.config_topic,
            version: payload.version,
        };
    } finally {
        conn.release();
    }
}

async function publishFanProfile(deviceId, profile) {
    if (!isConnected()) {
        throw new Error('MQTT broker is not connected');
    }

    const conn = await pool.getConnection();

    try {
        // 1. Lấy thông tin thiết bị từ database
        const rows = await conn.query(
            `
            SELECT
                id,
                name,
                device_uid,
                device_type,
                config_topic
            FROM devices
            WHERE id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        if (!rows.length) {
            throw new Error('Device not found');
        }

        const device = rows[0];

        // 2. Kiểm tra loại thiết bị
        if (device.device_type !== 'fan') {
            throw new Error('Device is not a fan');
        }

        if (!device.device_uid || !device.config_topic) {
            throw new Error(
                'Device UID or config_topic is missing',
            );
        }

        // 3. Chuẩn hóa cấu hình
        const defaultLevel = Number(
            profile.defaultLevel ?? 0,
        );

        if (
            !Number.isInteger(defaultLevel) ||
            defaultLevel < 0 ||
            defaultLevel > 3
        ) {
            throw new Error('Invalid default fan level');
        }

        const autoEnabled = profile.mode !== 'manual' ? true : false;
        const autoMode = profile.mode;
        const temperatureEnabled = profile.mode === 'both' || profile.mode === 'temperature';
        const scheduleEnabled = profile.mode === 'both' || profile.mode === 'schedule';
        const temperatureOn =
            profile.temperatureOn != null
                ? Number(profile.temperatureOn)
                : null;

        const temperatureOff =
            profile.temperatureOff != null
                ? Number(profile.temperatureOff)
                : null;

        // 4. Kiểm tra cấu hình nhiệt độ
        if (autoMode === 'both' || autoMode === 'temperature') {
            if (
                temperatureOn === null ||
                temperatureOff === null ||
                !Number.isFinite(temperatureOn) ||
                !Number.isFinite(temperatureOff)
            ) {
                throw new Error(
                    'Invalid temperature configuration',
                );
            }

            if (temperatureOn <= temperatureOff) {
                throw new Error(
                    'temperature_on must be greater than temperature_off',
                );
            }
        }

        // 5. Chuẩn hóa chế độ hoạt động
        let mode = 'both';

        if (temperatureEnabled && scheduleEnabled) {
            mode = 'both';
        } else if (scheduleEnabled) {
            mode = 'schedule';
        } else if (temperatureEnabled) {
            mode = 'temperature';
        }

        // 6. Chuẩn hóa danh sách ngày
        const days = normalizeRelayDays(
            profile.daysOnWeek,
        );

        // 7. Xây dựng Payload
        const payload = {
            device_id: device.device_uid,
            type: device.device_type,
            name: device.name || device.device_uid,
            room: '',

            settings: {
                default_level: defaultLevel,
                auto_mode: autoEnabled,
                scenario_mode: mode,
                temperature_enabled: temperatureEnabled,
                temperature_on: temperatureEnabled ? temperatureOn : null,
                temperature_off: temperatureEnabled ? temperatureOff : null,
                schedule_enabled: scheduleEnabled,
                schedule_on: scheduleEnabled
                    ? profile.timeOn || '08:00'
                    : null,
                schedule_off: scheduleEnabled
                    ? profile.timeOff || '22:00'
                    : null,
                schedule_days: scheduleEnabled
                    ? days
                    : [],
                motion: normalizeMotion(
                    profile.motion || {},
                    false,
                ),
            },
            config_topic: device.config_topic,
            version: Number(profile.profileVersion),
        };

        // 8. Kiểm tra phiên bản cấu hình
        if (
            !Number.isInteger(payload.version) ||
            payload.version < 1
        ) {
            throw new Error('Invalid profile version');
        }

        // 9. Publish MQTT
        await publish(device.config_topic, payload, {
            qos: 1,
            retain: true,
        });

        return {
            topic: device.config_topic,
            version: payload.version,
        };

    } finally {
        conn.release();
    }
}
module.exports = {
    TOPICS,
    connectMqtt,
    publish,
    publishRelayProfile,
    publishFanProfile,
    getClient,
    isConnected,
};