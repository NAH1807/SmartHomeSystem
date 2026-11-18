const { pool } = require('../config/database');

/*
 * Ngăn một automation thực thi nhiều lần
 * cho cùng một sự kiện trong cùng một phút.
 */
const lastExecutionKeys = new Set();


function getCurrentDayOfWeek() {
    return new Date().getDay()+1;
}

/**
 * Lấy giờ hiện tại theo HH:mm.
 */
function getCurrentTime() {
    const now = new Date();

    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');

    return `${hours}:${minutes}`;
}

/**
 * Chuyển day_on_week thành mảng số nguyên.
 *
 * Ví dụ: "1,2,3,4,5" -> [1, 2, 3, 4, 5]
 */
function parseDaysOfWeek(value) {
    if (Array.isArray(value)) {
        return value
            .map(Number)
            .filter(
                (day) =>
                    Number.isInteger(day) &&
                    day >= 1 &&
                    day <= 7,
            );
    }

    if (typeof value !== 'string' || value.trim() === '') {
        return [];
    }

    return value
        .split(',')
        .map((item) => Number(item.trim()))
        .filter(
            (day) =>
                Number.isInteger(day) &&
                day >= 1 &&
                day <= 7,
        );
}

/**
 * Chuẩn hóa TIME của MariaDB thành HH:mm.
 *
 * Ví dụ:
 * "08:30:00" -> "08:30"
 * "08:30"    -> "08:30"
 */
function normalizeTime(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }

    const text = String(value);

    const match = text.match(/^(\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$/);

    if (!match) {
        return null;
    }

    const hours = Number(match[1]);
    const minutes = Number(match[2]);

    if (hours > 23 || minutes > 59) {
        return null;
    }

    return `${match[1]}:${match[2]}`;
}

/**
 * Thực thi automation cho một thiết bị.
 *
 * action:
 * - on:  bật thiết bị
 * - off: tắt thiết bị
 *
 * device_id được dùng để xác định thiết bị.
 * device_id nội bộ vẫn được sử dụng khi ghi device_states.
 */
async function executeAutomation(automation, action = 'on') {
    if (!['on', 'off'].includes(action)) {
        throw new Error(`Invalid automation action: ${action}`);
    }

    if (!automation.device_id) {
        throw new Error('Automation is missing device_id');
    }

    const conn = await pool.getConnection();

    try {
        const devices = await conn.query(
            `
            SELECT
                id,
                device_uid,
                name,
                device_type,
                is_online
            FROM devices
            WHERE device_uid = ?
            LIMIT 1
            `,
            [automation.device_id],
        );

        if (!devices.length) {
            throw new Error(
                `Device not found: ${automation.device_id}`,
            );
        }

        const device = devices[0];
        const deviceId = Number(device.id);
        const isOn = action === 'on' ? 1 : 0;

        /*
         * Cập nhật trạng thái bật/tắt.
         * Dùng device.id vì device_states hiện liên kết
         * với khóa id nội bộ của bảng devices.
         */
        await conn.query(
            `
            INSERT INTO device_states (
                device_id,
                is_on
            )
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE
                is_on = VALUES(is_on)
            `,
            [deviceId, isOn],
        );

        /*
         * Chỉ cập nhật nhiệt độ mục tiêu khi bật thiết bị.
         * Không ghi đè nhiệt độ nếu automation nhiệt độ tắt.
         */
        if (
            action === 'on' &&
            Number(automation.temperature_enabled) === 1 &&
            automation.target_temperature !== null &&
            automation.target_temperature !== undefined
        ) {
            const targetTemperature = Number(
                automation.target_temperature,
            );

            if (
                Number.isFinite(targetTemperature) &&
                targetTemperature >= 16 &&
                targetTemperature <= 30
            ) {
                await conn.query(
                    `
                    INSERT INTO device_states (
                        device_id,
                        is_on,
                        target_temperature
                    )
                    VALUES (?, 1, ?)
                    ON DUPLICATE KEY UPDATE
                        is_on = 1,
                        target_temperature = VALUES(target_temperature)
                    `,
                    [deviceId, targetTemperature],
                );
            }
        }

        console.log(
            `[Automation] ${action.toUpperCase()} | ` +
            `device_id=${automation.device_id} | ` +
            `device=${device.name}`,
        );

        return {
            success: true,
            action,
            device_uid: device.device_uid,
            device_id: deviceId,
        };
    } finally {
        conn.release();
    }
}

/**
 * Kiểm tra và thực thi tất cả automation
 * phù hợp với giờ và ngày hiện tại.
 *
 * time_on  -> bật thiết bị
 * time_off -> tắt thiết bị
 */
async function processAutomations() {
    const currentTime = getCurrentTime();
    const currentDay = getCurrentDayOfWeek();

    try {
        const rows = await pool.query(
            `
            SELECT
                a.id,
                a.device_id,
                a.enabled,
                a.time_on,
                a.time_off,
                a.day_on_week,
                a.default_level,
                a.auto_mode,
                a.temperature_on,
                a.temperature_off,

                d.name,
                d.device_type,
                d.is_online

            FROM automations a

            INNER JOIN devices d
                ON d.id = a.device_id

            WHERE a.enabled = 1
            `,
        );

        for (const automation of rows) {
            const days = parseDaysOfWeek(
                automation.day_on_week,
            );

            if (!days.includes(currentDay)) {
                continue;
            }

            /*
             * Kiểm tra cả thời gian bật và thời gian tắt.
             */
            const events = [
                {
                    time: normalizeTime(automation.time_on),
                    action: 'on',
                },
                {
                    time: normalizeTime(automation.time_off),
                    action: 'off',
                },
            ];

            for (const event of events) {
                if (!event.time || event.time !== currentTime) {
                    continue;
                }

                /*
                 * Mỗi automation có thể có hai sự kiện
                 * trong một ngày: on và off.
                 */
                const executionKey = [
                    automation.id,
                    currentDay,
                    currentTime,
                    event.action,
                ].join('-');

                if (lastExecutionKeys.has(executionKey)) {
                    continue;
                }

                /*
                 * Đánh dấu trước khi thực thi để tránh
                 * chạy trùng khi scheduler được gọi liên tục.
                 */
                lastExecutionKeys.add(executionKey);

                try {
                    await executeAutomation(
                        automation,
                        event.action,
                    );
                } catch (error) {
                    // Cho phép thử lại ở lần kiểm tra tiếp theo.
                    lastExecutionKeys.delete(executionKey);

                    console.error(
                        `[Automation] Failed | ` +
                        `id=${automation.id} | ` +
                        `action=${event.action}:`,
                        error,
                    );
                }
            }
        }

        cleanupExecutionKeys();
    } catch (error) {
        console.error(
            '[Automation] Scheduler error:',
            error,
        );
    }
}

/**
 * Giới hạn bộ nhớ dành cho execution keys.
 */
function cleanupExecutionKeys() {
    if (lastExecutionKeys.size > 1000) {
        lastExecutionKeys.clear();
    }
}

module.exports = {
    processAutomations,
};
