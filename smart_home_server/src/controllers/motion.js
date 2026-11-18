const { pool } = require('../config/database');

/**
 * Chuẩn hóa giá trị boolean.
 */
function parseBoolean(value) {
    if (typeof value === 'boolean') {
        return value;
    }

    if (value === 1 || value === '1' || value === 'true') {
        return true;
    }

    if (value === 0 || value === '0' || value === 'false') {
        return false;
    }

    throw new Error('enabled must be true or false');
}

/**
 * Chuẩn hóa giá trị thời gian.
 */
function parseTimeValue(value, fieldName) {
    const number = Number(value);

    if (
        value === null ||
        value === undefined ||
        value === '' ||
        !Number.isInteger(number) ||
        number < 0
    ) {
        throw new Error(`${fieldName} must be a non-negative integer`);
    }

    return number;
}

/**
 * Chuẩn hóa dữ liệu trả về cho Flutter.
 */
function formatMotion(motion) {
    if (!motion) {
        return null;
    }

    return {
        id: Number(motion.id),
        device_id: Number(motion.device_id),
        enabled: Boolean(Number(motion.motion_enabled)),
        hold_seconds: Number(motion.hold_seconds),
        cooldown_seconds: Number(motion.cooldown_seconds),
    };
}

/**
 * Kiểm tra thiết bị có tồn tại hay không.
 */
async function findDevice(conn, deviceId) {
    const rows = await conn.query(
        `
        SELECT
            id,
            device_type
        FROM devices
        WHERE id = ?
        LIMIT 1
        `,
        [deviceId],
    );

    return rows.length > 0 ? rows[0] : null;
}

/**
 * GET /api/devices/:deviceId/motion
 *
 * Lấy cấu hình Motion Sensor.
 */
const getMotion = async (req, res, next) => {
    let conn;

    try {
        const deviceId = Number(req.params.deviceId);

        if (!Number.isInteger(deviceId) || deviceId <= 0) {
            return res.status(400).json({
                message: 'Invalid device ID',
            });
        }

        conn = await pool.getConnection();

        const device = await findDevice(conn, deviceId);

        if (!device) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        const rows = await conn.query(
            `
            SELECT
                id,
                device_id,
                motion_enabled,
                hold_seconds,
                cooldown_seconds
            FROM motion_configs
            WHERE device_id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        if (rows.length === 0) {
            return res.json(null);
        }

        return res.json(formatMotion(rows[0]));
    } catch (error) {
        next(error);
    } finally {
        if (conn) {
            conn.release();
        }
    }
};

/**
 * PUT /api/devices/:deviceId/motion
 *
 * Tạo hoặc cập nhật cấu hình Motion Sensor.
 */
const saveMotion = async (req, res, next) => {
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
         * Kiểm tra dữ liệu đầu vào.
         */
        if (
            body.enabled === undefined ||
            body.hold_seconds === undefined ||
            body.cooldown_seconds === undefined
        ) {
            return res.status(400).json({
                message: 'Missing required Motion configuration fields',
            });
        }

        const enabled = parseBoolean(body.enabled);
        
        const holdTime = parseTimeValue(
            body.hold_seconds,
            'hold_seconds',
        );

        const cooldownTime = parseTimeValue(
            body.cooldown_seconds,
            'cooldown_seconds',
        );

        if (holdTime <= 0) {
            return res.status(400).json({
                message: 'hold_seconds must be greater than 0',
            });
        }

        conn = await pool.getConnection();

        /*
         * Kiểm tra thiết bị tồn tại.
         */
        const device = await findDevice(conn, deviceId);

        if (!device) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        /*
         * Kiểm tra cấu hình Motion đã tồn tại.
         */
        const existingRows = await conn.query(
            `
            SELECT id
            FROM motion_configs
            WHERE device_id = ?
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
                UPDATE motion_configs
                SET
                    motion_enabled = ?,
                    hold_seconds = ?,
                    cooldown_seconds = ?
                WHERE device_id = ?
                `,
                [
                    enabled ? 1 : 0,
                    holdTime,
                    cooldownTime,
                    deviceId,
                ],
            );
        } else {
            /*
             * Tạo cấu hình mới.
             */
            await conn.query(
                `
                INSERT INTO motion_configs (
                    device_id,
                    motion_enabled,
                    hold_seconds,
                    cooldown_seconds
                )
                VALUES (?, ?, ?, ?)
                `,
                [
                    deviceId,
                    enabled ? 1 : 0,
                    holdTime,
                    cooldownTime,
                ],
            );
        }

        /*
         * Đọc lại dữ liệu sau khi lưu.
         */
        const savedRows = await conn.query(
            `
            SELECT
                id,
                device_id,
                motion_enabled,
                hold_seconds,
                cooldown_seconds
            FROM motion_configs
            WHERE device_id = ?
            LIMIT 1
            `,
            [deviceId],
        );

        return res.json(formatMotion(savedRows[0]));
    } catch (error) {
        if (
            error.message &&
            (
                error.message.includes('enabled must') ||
                error.message.includes('hold_seconds') ||
                error.message.includes('cooldown_seconds')
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

module.exports = {
    getMotion,
    saveMotion,
};