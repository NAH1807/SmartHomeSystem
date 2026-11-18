const { pool } = require('../config/database');
const {
    publishFanProfile,
    publishRelayProfile,
    isConnected,
} = require('../services/mqtt');

const VALID_DAYS = [1, 2, 3, 4, 5, 6, 7];

function normalizeDays(days, required = false) {
    let values = [];

    if (Array.isArray(days)) {
        values = days;
    } else if (typeof days === 'string' && days.trim() !== '') {
        values = days.split(',');
    } else if (days === null || days === undefined || days === '') {
        values = [];
    } else {
        throw new Error('day_on_week must be an array or comma-separated string');
    }

    const result = [...new Set(
        values.map((value) => {
            const text = String(value).trim();

            if (!/^[1-7]$/.test(text)) {
                return NaN;
            }

            return Number(text);
        }),
    )].sort((a, b) => a - b);

    if (result.some((day) => !VALID_DAYS.includes(day))) {
        throw new Error('day_on_week must contain values from 1 to 7');
    }

    if (required && result.length === 0) {
        throw new Error('At least one day must be selected');
    }

    return result;
}

/**
 * Database lưu ngày dưới dạng VARCHAR:
 * [1, 2, 3] -> "1,2,3"
 */
function formatDays(days) {
    return days.join(',');
}

/**
 * Chuyển chuỗi ngày trong database thành mảng.
 */
function parseDays(value) {
    if (value === null || value === undefined || value === '') {
        return [];
    }

    return normalizeDays(String(value));
}

/**
 * Chuẩn hóa thời gian đầu vào thành HH:mm:ss.
 *
 * Hỗ trợ:
 * HH:mm
 * HH:mm:ss
 *
 * Giá trị null/chuỗi rỗng được giữ là null.
 */
function normalizeTime(value, fieldName) {
    if (value === null || value === undefined || value === '') {
        return null;
    }

    if (typeof value !== 'string') {
        throw new Error(`${fieldName} must be a string in HH:mm or HH:mm:ss format`);
    }

    const text = value.trim();

    const match = text.match(
        /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/,
    );

    if (!match) {
        throw new Error(
            `${fieldName} must have format HH:mm or HH:mm:ss`,
        );
    }

    const seconds = match[3] ?? '00';

    return `${match[1]}:${match[2]}:${seconds}`;
}

/**
 * Chuyển giá trị boolean từ JSON thành boolean thực sự.
 */
function parseBoolean(value, defaultValue = false) {
    if (value === undefined || value === null) {
        return defaultValue;
    }

    if (typeof value === 'boolean') {
        return value;
    }

    if (value === 1 || value === '1' || value === 'true') {
        return true;
    }

    if (value === 0 || value === '0' || value === 'false') {
        return false;
    }

    throw new Error('Boolean field must be true or false');
}

/**
 * Chuẩn hóa dữ liệu trả về cho Flutter.
 */
function formatAutomation(automation) {
    if (!automation) {
        return null;
    }

    return {
        id: automation.id,
        device_id: automation.device_id,
        enabled: Boolean(Number(automation.enabled)),
        time_on: automation.time_on,
        time_off: automation.time_off,
        day_on_week: parseDays(automation.day_on_week),
        default_level: automation.default_level,
        auto_mode: Boolean(Number(automation.auto_mode)),
        temperature_on: automation.temperature_on,
        temperature_off: automation.temperature_off,

        // Cấu hình các kênh Relay
        relay_channels: automation.relay_channels
            ? (
                typeof automation.relay_channels === 'string'
                    ? JSON.parse(automation.relay_channels)
                    : automation.relay_channels
            )
            : [],
    };
}

/**
 * Kiểm tra thiết bị theo device_uid.
 */
async function findDevice(conn, deviceId) {
    const rows = await conn.query(
        `
        SELECT
            id,
            device_type,
            profile_version
        FROM devices
        WHERE id = ?
        LIMIT 1
        `,
        [deviceId],
    );

    return rows.length > 0 ? rows[0] : null;
}

/**
 * GET /api/devices/:deviceId/automation
 *
 * Lấy cấu hình automation của thiết bị.
 */
const getAutomation = async (req, res, next) => {
    let conn;

    try {
        const deviceId = Number(req.params.deviceId);

        if (!deviceId || deviceId.length > 100) {
            return res.status(400).json({
                message: 'Invalid device ID',
            });
        }

        conn = await pool.getConnection();

        const device = await findDevice(conn, deviceId);

        if (!device) {
            return res.status(404).json({
                message: 'Device not founds',
            });
        }

        const rows = await conn.query(
            `
            SELECT
                id,
                device_id,
                enabled,
                time_on,
                time_off,
                day_on_week,
                default_level,
                auto_mode,
                temperature_on,
                temperature_off,
                relay_channels,
                created_at,
                updated_at
            FROM automations
            WHERE device_id = ?
            ORDER BY id ASC
            LIMIT 1
            `,
            [deviceId],
        );

        if (rows.length === 0) {
            return res.json(null);
        }

        return res.json(formatAutomation(rows[0]));
    } catch (error) {
        next(error);
    } finally {
        if (conn) {
            conn.release();
        }
    }
};

/**
 * PUT /api/devices/:deviceId/automation
 *
 * Tạo hoặc cập nhật cấu hình automation.
 *
 */
const saveAutomation = async (req, res, next) => {
    let conn;

    try {
        const deviceId = Number(req.params.deviceId);
        if (!Number.isInteger(deviceId) || deviceId <= 0) {
            return res.status(400).json({
                message: 'Invalid device ID',
            });
        }

        const body = req.body ?? {};

        /*
         * Chấp nhận cả tên cột database dạng snake_case
         * và tên camelCase nếu Flutter đang sử dụng.
         */
        const enabled = parseBoolean(
            body.enabled,
            false,
        );

        const rawTimeOn =
            body.time_on ??
            null;

        const rawTimeOff =
            body.time_off ??
            null;

        const rawDays =
            body.day_on_week ??
            undefined;

        /*
         * Kiểm tra thời gian.
         */
        const timeOn = normalizeTime(
            rawTimeOn,
            'time_on',
        );

        const timeOff = normalizeTime(
            rawTimeOff,
            'time_off',
        );

        const defaultLevel = body.default_level;
        const autoMode = body.auto_mode;
        const temperatureOn = body.temperature_on;
        const temperatureOff = body.temperature_off;

        const rawRelayChannels =
            body.relay_channels ??
            body.relayChannels ??
            [];
        /*
         * Chuẩn hóa ngày.
         * Nếu không gửi trường ngày, dùng mặc định tất cả
         * các ngày trong tuần để tương thích schema database.
         */
        let days;

        try {
            days = normalizeDays(
                rawDays === undefined
                    ? [1, 2, 3, 4, 5, 6, 7]
                    : rawDays,
                enabled,
            );
        } catch (error) {
            return res.status(400).json({
                message: error.message,
            });
        }

        const dayOnWeek = formatDays(days);

        conn = await pool.getConnection();

        /*
         * Kiểm tra thiết bị tồn tại theo device_uid.
         */
        const device = await findDevice(conn, deviceId);

        if (!device) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        /*
        * Chuẩn hóa cấu hình từng kênh Relay.
        */
        let normalizedRelayChannels = [];

        if (device.device_type === 'relay') {
            try {
                if (!Array.isArray(rawRelayChannels)) {
                    return res.status(400).json({
                        message: 'relay_channels must be an array',
                    });
                }

                normalizedRelayChannels = rawRelayChannels.map((item) => {
                    const channel = Number(item.channel ?? item.id);

                    if (!Number.isInteger(channel) || channel <= 0) {
                        throw new Error('Invalid relay channel');
                    }

                    return {
                        channel,
                        name: String(item.name ?? `Kênh ${channel}`),
                        enabled: parseBoolean(item.enabled, false),

                        time_on: normalizeTime(
                            item.time_on ?? item.timeOn ?? null,
                            'channel time_on',
                        ),

                        time_off: normalizeTime(
                            item.time_off ?? item.timeOff ?? null,
                            'channel time_off',
                        ),

                        day_on_week: normalizeDays(
                            item.day_on_week ??
                            item.daysOnWeek ??
                            days,
                        ),
                    };
                });

                // Không cho phép trùng số kênh.
                const channelIds = normalizedRelayChannels.map(
                    (item) => item.channel,
                );

                if (new Set(channelIds).size !== channelIds.length) {
                    throw new Error('Duplicate relay channel');
                }
            } catch (error) {
                return res.status(400).json({
                    message: error.message,
                });
            }
        }

        /*
         * Kiểm tra cấu hình đã tồn tại theo device_uid.
         */
        const existingRows = await conn.query(
            `
            SELECT id
            FROM automations
            WHERE device_id = ?
            ORDER BY id ASC
            LIMIT 1
            `,
            [deviceId],
        );

        if (existingRows.length > 0) {
            /*
             * Cập nhật cấu hình hiện tại.
             */
            await conn.query(
                `
                UPDATE automations
                SET
                    enabled = ?,
                    time_on = ?,
                    time_off = ?,
                    day_on_week = ?,
                    default_level = ?,
                    auto_mode = ?,
                    temperature_on = ?, 
                    temperature_off = ?,
                    relay_channels = ?
                WHERE device_id = ?
                `,
                [
                    enabled ? 1 : 0,
                    timeOn,
                    timeOff,
                    dayOnWeek,
                    defaultLevel,
                    autoMode,
                    temperatureOn,
                    temperatureOff,
                    device.device_type === 'relay'
                        ? JSON.stringify(normalizedRelayChannels)
                        : null,
                    deviceId,
                ],
            );
        } else {
            /*
             * Tạo cấu hình mới.
             */
            await conn.query(
                `
                INSERT INTO automations (
                    device_id,
                    enabled,
                    time_on,
                    time_off,
                    day_on_week,
                    default_level,
                    auto_mode,
                    temperature_on,
                    temperature_off,
                    relay_channels
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                `,
                [
                    deviceId,
                    enabled ? 1 : 0,
                    timeOn,
                    timeOff,
                    dayOnWeek,
                    defaultLevel,
                    autoMode,
                    temperatureOn,
                    temperatureOff,
                    device.device_type === 'relay'
                        ? JSON.stringify(normalizedRelayChannels)
                        : null,
                ],
            );
        }

        /*
         * Đọc lại cấu hình sau khi lưu.
         */
        const savedRows = await conn.query(
            `
            SELECT
                id,
                device_id,
                enabled,
                time_on,
                time_off,
                day_on_week,
                default_level,
                auto_mode,
                temperature_on,
                temperature_off,
                relay_channels,
                created_at,
                updated_at
            FROM automations
            WHERE device_id = ?
            ORDER BY id ASC
            LIMIT 1
            `,
            [deviceId],
        );

        const savedAutomation = formatAutomation(savedRows[0]);

        let mqttSync = {
            attempted: false,
            success: null,
            message: 'MQTT sync not required for this device type',
        };

        let relayChannels = [];
        if (device.device_type === 'relay') {
            mqttSync.attempted = true;

            try {
                if (!isConnected()) {
                    throw new Error('MQTT broker is not connected');
                }

                // const rawRelayChannels =
                //     body.relayChannels ??
                //     body.relay_channels;
                if (!Array.isArray(rawRelayChannels)) {
                    throw new Error(
                        'Missing relayChannels array in automation request',
                    );
                }

                const profileVersion =
                    Number(device.profile_version || 0) + 1;

                /*
                 * Chỉ những kênh được chọn mới chạy lịch.
                 * Nếu automation tổng bị tắt, tất cả kênh trở về manual.
                 */
                relayChannels = normalizedRelayChannels.map((item) => ({
                    channel: Number(item.channel),
                    name: String(item.name ?? ''),
                    enabled: parseBoolean(item.enabled, false),
                    time_on: normalizeTime(item.time_on ?? null, 'channel time_on'),
                    time_off: normalizeTime(item.time_off ?? null, 'channel time_off'),
                    day_on_week: normalizeDays(item.day_on_week ?? []),
                }));

                const relayChannelsMQTT = rawRelayChannels.map((item) => ({
                    id: item.channel,
                    enabled:
                        enabled &&
                        (
                            item.enabled === true ||
                            item.enabled === 1 ||
                            item.enabled === '1'
                        ),
                    daysOnWeek: days,
                    timeOn: timeOn ? timeOn.slice(0, 5) : null,
                    timeOff: timeOff ? timeOff.slice(0, 5) : null,
                }));
                /*
                 * Không giữ connection DB hiện tại trong khi
                 * publishRelayProfile mở connection riêng.
                 */
                if (conn) {
                    conn.release();
                    conn = null;
                }

                const mqttResult = await publishRelayProfile(
                    deviceId,
                    {
                        profileVersion,
                        relayChannelsMQTT,
                        daysOnWeek: days,
                        timeOn: timeOn ? timeOn.slice(0, 5) : null,
                        timeOff: timeOff ? timeOff.slice(0, 5) : null,
                    },
                );

                await pool.query(
                    `
            UPDATE devices
            SET profile_version = ?
            WHERE id = ?
            `,
                    [profileVersion, deviceId],
                );

                mqttSync = {
                    attempted: true,
                    success: true,
                    topic: mqttResult.topic,
                    version: mqttResult.version,
                    message: 'Automation profile published to MQTT',
                };

                console.log(
                    `[AUTOMATION] MQTT profile sent: device=${deviceId}, ` +
                    `topic=${mqttResult.topic}, version=${mqttResult.version}`,
                );
            } catch (mqttError) {
                console.error(
                    `[AUTOMATION] MQTT profile failed for device ${deviceId}:`,
                    mqttError.message,
                );

                mqttSync = {
                    attempted: true,
                    success: false,
                    message: mqttError.message,
                };
            }
        } else if (device.device_type === 'fan') {
            mqttSync.attempted = true;

            try {
                if (!isConnected()) {
                    throw new Error('MQTT broker is not connected');
                }

                /*
                 * Xác định chế độ tự động từ auto_mode trong database.
                 *
                 * schedule     : Chỉ hẹn giờ
                 * temperature  : Chỉ theo nhiệt độ
                 * both         : Hẹn giờ và nhiệt độ
                 */
                const validModes = [
                    'schedule',
                    'temperature',
                    'both',
                ];

                const requestedMode = String(
                    autoMode || 'both',
                ).toLowerCase();

                if (!validModes.includes(requestedMode)) {
                    throw new Error('Invalid fan automation mode');
                }

                /*
                 * Nếu automation bị tắt thì chuyển về manual.
                 */
                const scenarioMode = enabled
                    ? requestedMode
                    : 'manual';

                /*
                 * Xác định chức năng cần đồng bộ dựa trên auto_mode.
                 */
                const scheduleEnabled = [
                    'schedule',
                    'both',
                ].includes(scenarioMode);

                const temperatureEnabled = [
                    'temperature',
                    'both',
                ].includes(scenarioMode);

                /*
                 * Kiểm tra lịch hoạt động.
                 */
                if (
                    scheduleEnabled &&
                    !timeOn &&
                    !timeOff
                ) {
                    throw new Error(
                        'At least one of time_on or time_off is required for fan schedule',
                    );
                }

                /*
                 * Kiểm tra mức quạt mặc định.
                 */
                const fanLevel = Number(defaultLevel);

                if (
                    !Number.isInteger(fanLevel) ||
                    fanLevel < 0 ||
                    fanLevel > 3
                ) {
                    throw new Error('Invalid default fan level');
                }

                /*
                 * Kiểm tra ngưỡng nhiệt độ.
                 */
                const tempOn = temperatureOn != null
                    ? Number(temperatureOn)
                    : null;

                const tempOff = temperatureOff != null
                    ? Number(temperatureOff)
                    : null;

                if (temperatureEnabled) {
                    if (
                        tempOn === null ||
                        tempOff === null ||
                        !Number.isFinite(tempOn) ||
                        !Number.isFinite(tempOff)
                    ) {
                        throw new Error(
                            'Invalid fan temperature configuration',
                        );
                    }

                    if (tempOn <= tempOff) {
                        throw new Error(
                            'temperature_on must be greater than temperature_off',
                        );
                    }
                }

                /*
                 * Tăng phiên bản cấu hình.
                 */
                const profileVersion =
                    Number(device.profile_version || 0) + 1;

                /*
                 * Giải phóng connection trước khi publish MQTT.
                 */
                if (conn) {
                    conn.release();
                    conn = null;
                }

                /*
                 * Đồng bộ cấu hình Fan qua MQTT.
                 */

                const mqttResult = await publishFanProfile(
                    deviceId,
                    {
                        profileVersion,
                        defaultLevel: fanLevel,
                        mode: scenarioMode,
                        scheduleEnabled,
                        temperatureEnabled,
                        timeOn: scheduleEnabled && timeOn
                            ? timeOn.slice(0, 5)
                            : null,
                        timeOff: scheduleEnabled && timeOff
                            ? timeOff.slice(0, 5)
                            : null,
                        daysOnWeek: scheduleEnabled
                            ? days
                            : [],
                        temperatureOn: temperatureEnabled
                            ? tempOn
                            : null,
                        temperatureOff: temperatureEnabled
                            ? tempOff
                            : null,
                    },
                );

                /*
                 * Cập nhật phiên bản cấu hình trên database.
                 */
                await pool.query(
                    `
            UPDATE devices
            SET profile_version = ?
            WHERE id = ?
            `,
                    [profileVersion, deviceId],
                );

                mqttSync = {
                    attempted: true,
                    success: true,
                    topic: mqttResult.topic,
                    version: mqttResult.version,
                    message: 'Fan automation profile published to MQTT',
                };

                console.log(
                    `[AUTOMATION] Fan MQTT profile sent: device=${deviceId}, ` +
                    `mode=${scenarioMode}, ` +
                    `topic=${mqttResult.topic}, ` +
                    `version=${mqttResult.version}`,
                );

            } catch (mqttError) {
                console.error(
                    `[AUTOMATION] Fan MQTT profile failed for device ${deviceId}:`,
                    mqttError.message,
                );

                mqttSync = {
                    attempted: true,
                    success: false,
                    message: mqttError.message,
                };
            }
        }
        return res.json({
            ...savedAutomation,
            mqtt_sync: mqttSync,
        });
    } catch (error) {
        if (
            error.message &&
            (
                error.message.includes('time_on must') ||
                error.message.includes('time_off must') ||
                error.message.includes('Boolean field')
            )
        ) {
            return res.status(400).json({
                message: error.message,
            });
        }

        next(error);
    } finally {
        if (conn) {
            conn.release();
        }
    }
};

/**
 * DELETE /api/devices/:deviceId/automation
 *
 * Xóa cấu hình automation theo device_uid.
 */
const deleteAutomation = async (req, res, next) => {
    let conn;

    try {
        const deviceId = String(
            req.params.deviceId ?? '',
        ).trim();

        if (!deviceId || deviceId.length > 100) {
            return res.status(400).json({
                message: 'Invalid device UID',
            });
        }

        conn = await pool.getConnection();

        const result = await conn.query(
            `
            DELETE FROM automations
            WHERE device_id = ?
            `,
            [deviceId],
        );

        return res.json({
            message: 'Automation deleted successfully',
            device_uid: deviceId,
            affectedRows: Number(result.affectedRows),
        });
    } catch (error) {
        next(error);
    } finally {
        if (conn) {
            conn.release();
        }
    }
};

module.exports = {
    getAutomation,
    saveAutomation,
    deleteAutomation,
};
