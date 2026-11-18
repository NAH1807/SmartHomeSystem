const { pool } = require('../config/database');

// ============================================================
// HELPER
// ============================================================

function normalizeValue(value) {
    if (typeof value === 'bigint') {
        return Number(value);
    }

    if (Array.isArray(value)) {
        return value.map(normalizeValue);
    }

    if (value !== null && typeof value === 'object') {
        const result = {};

        for (const key of Object.keys(value)) {
            result[key] = normalizeValue(value[key]);
        }

        return result;
    }

    return value;
}

function toBoolean(value) {
    return Boolean(Number(value));
}

function toNumber(value) {
    if (value === null || value === undefined) {
        return null;
    }

    const number = Number(value);

    return Number.isNaN(number) ? null : number;
}


// ============================================================
// ALLOWED DEVICE TYPES
// ============================================================

const ALLOWED_DEVICE_TYPES = [
    'relay',
    'fan',
    'camera',
];


// ============================================================
// GET ALL DEVICES
// GET /api/devices
// ============================================================

async function getDevices(req, res) {
    let connection;

    try {
        connection = await pool.getConnection();

        const rows = await connection.query(`
            SELECT
                d.id,
                d.name,
                d.device_type,
                d.icon,

                d.device_uid,
                d.device_ip,

                d.mqtt_topic,
                d.config_topic,
                d.control_topic,
                d.security_topic,
                d.security_state,
                d.profile_version,
                d.device_version,
                d.is_online,

                ds.is_on,
                ds.temperature,
                ds.fan_speed


            FROM devices d

            LEFT JOIN device_states ds
                ON ds.device_id = d.id

            ORDER BY d.id ASC
        `);

        const devices = rows
            .filter(row => row.id !== undefined)
            .map(row => getDeviceJson(row));

        res.json(devices);

    } catch (error) {
        console.error('getDevices error:', error);

        res.status(500).json({
            message: 'Failed to load devices',
        });

    } finally {
        if (connection) {
            connection.release();
        }
    }
}


// ============================================================
// GET DEVICE BY ID
// GET /api/devices/:id
// ============================================================

async function getDeviceById(req, res) {
    const deviceId = Number(req.params.id);

    if (!Number.isInteger(deviceId)) {
        return res.status(400).json({
            message: 'Invalid device ID',
        });
    }

    let connection;

    try {
        connection = await pool.getConnection();

        const rows = await connection.query(`
            SELECT
                d.id,
                d.name,
                d.device_type,
                d.icon,

                d.device_uid,
                d.device_ip,

                d.mqtt_topic,
                d.config_topic,
                d.control_topic,
                d.security_topic,
                d.security_state,
                d.profile_version,
                d.device_version,

                d.is_online,

                ds.is_on,
                ds.temperature,
                ds.fan_speed

            FROM devices d

            LEFT JOIN device_states ds
                ON ds.device_id = d.id

            WHERE d.id = ?

            LIMIT 1
        `, [deviceId]);

        if (!rows.length) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        const row = normalizeValue(rows[0]);

        res.json(getDeviceJson(row));

    } catch (error) {
        console.error('getDeviceById error:', error);

        res.status(500).json({
            message: 'Failed to load device',
        });

    } finally {
        if (connection) {
            connection.release();
        }
    }
}


// ============================================================
// CREATE DEVICE
// POST /api/devices
// ============================================================

const createDevice = async (req, res, next) => {
    let conn;

    try {
        const {
            name,
            device_type,
            icon = 'devices',
        } = req.body;

        if (!name || !device_type) {
            return res.status(400).json({
                message: 'name and device_type are required',
            });
        }

        if (!ALLOWED_DEVICE_TYPES.includes(device_type)) {
            return res.status(400).json({
                message:
                    'Invalid device_type. Allowed: relay, fan, camera',
            });
        }

        conn = await pool.getConnection();

        await conn.beginTransaction();

        const result = await conn.query(
            `
            INSERT INTO devices
                (
                    name,
                    device_type,
                    icon,
                    is_online
                )
            VALUES
                (?, ?, ?, 0)
            `,
            [
                name.trim(),
                device_type,
                icon,
            ],
        );

        const deviceId = Number(result.insertId);

        /*
         * Topic do backend tạo.
         * Không cần nhập từ Flutter.
         */
        let mqttTopic = null;

        if (device_type === 'relay') {
            mqttTopic = `smarthome/device/relay${deviceId}/control`;
        } else if (device_type === 'fan') {
            mqttTopic = `smarthome/device/fan${deviceId}/control`;
        } else if (device_type === 'camera') {
            mqttTopic = `smarthome/device/cam${deviceId}/control`;
        }

        await conn.query(
            `
            UPDATE devices
            SET mqtt_topic = ?
            WHERE id = ?
            `,
            [
                mqttTopic,
                deviceId,
            ],
        );

        /*
         * Tạo trạng thái ban đầu.
         */
        await conn.query(
            `
            INSERT INTO device_states
                (
                    device_id,
                    is_on,
                    fan_speed,
                    security_state
                )
            VALUES
                (?, 0, 0, 'normal')
            `,
            [deviceId],
        );

        await conn.commit();

        const device = await getDeviceObject(
            conn,
            deviceId,
        );

        return res.status(201).json(device);

    } catch (error) {
        if (conn) {
            await conn.rollback();
        }

        console.error('createDevice error:', error);

        next(error);

    } finally {
        if (conn) {
            conn.release();
        }
    }
};


// ============================================================
// UPDATE DEVICE
// PUT /api/devices/:id
// ============================================================

async function updateDevice(req, res) {
    const deviceId = Number(req.params.id);

    if (!Number.isInteger(deviceId)) {
        return res.status(400).json({
            message: 'Invalid device ID',
        });
    }

    const {
        name,
        device_type,
        icon,
    } = req.body;

    if (!name || !device_type) {
        return res.status(400).json({
            message: 'name and device_type are required',
        });
    }

    if (!ALLOWED_DEVICE_TYPES.includes(device_type)) {
        return res.status(400).json({
            message:
                'Invalid device_type. Allowed: relay, fan, camera',
        });
    }

    let connection;

    try {
        connection = await pool.getConnection();

        const existing = await connection.query(`
            SELECT
                id,
                device_uid
            FROM devices
            WHERE id = ?
            LIMIT 1
        `, [deviceId]);

        if (!existing.length) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        /*
         * Không cho Flutter tự nhập mqtt_topic.
         * Topic do backend quản lý.
         */
        await connection.query(`
            UPDATE devices
            SET
                name = ?,
                device_type = ?,
                icon = ?
            WHERE id = ?
        `, [
            name.trim(),
            device_type,
            icon || 'devices',
            deviceId,
        ]);

        /*
         * Nếu đổi sang thiết bị không phải fan,
         * reset fan_speed.
         */
        if (device_type !== 'fan') {
            await connection.query(`
                UPDATE device_states
                SET fan_speed = 0
                WHERE device_id = ?
            `, [deviceId]);
        }

        /*
         * Camera có security_state.
         * Relay/Fan cũng giữ normal.
         */
        if (device_type !== 'camera') {
            await connection.query(`
                UPDATE device_states
                SET security_state = 'normal'
                WHERE device_id = ?
            `, [deviceId]);
        }

        const rows = await connection.query(`
            SELECT
                d.id,
                d.name,
                d.device_type,
                d.icon,

                d.device_uid,
                d.device_ip,

                d.mqtt_topic,
                d.config_topic,
                d.control_topic,
                d.security_topic,

                d.is_online,

                ds.is_on,
                ds.temperature,
                ds.fan_speed,
                ds.security_state,
                ds.profile_version,
                ds.device_version

            FROM devices d

            LEFT JOIN device_states ds
                ON ds.device_id = d.id

            WHERE d.id = ?

            LIMIT 1
        `, [deviceId]);

        if (!rows.length) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        const row = normalizeValue(rows[0]);

        res.json({
            data: getDeviceJson(row),
        });

    } catch (error) {
        console.error('updateDevice error:', error);

        res.status(500).json({
            message: 'Failed to update device',
        });

    } finally {
        if (connection) {
            connection.release();
        }
    }
}


// ============================================================
// DELETE DEVICE
// DELETE /api/devices/:id
// ============================================================

async function deleteDevice(req, res) {
    const deviceId = Number(req.params.id);

    if (!Number.isInteger(deviceId)) {
        return res.status(400).json({
            message: 'Invalid device ID',
        });
    }

    let connection;

    try {
        connection = await pool.getConnection();

        const result = await connection.query(`
            DELETE FROM devices
            WHERE id = ?
        `, [deviceId]);

        if (Number(result.affectedRows) === 0) {
            return res.status(404).json({
                message: 'Device not found',
            });
        }

        res.json({
            message: 'Device deleted successfully',
        });

    } catch (error) {
        console.error('deleteDevice error:', error);

        res.status(500).json({
            message: 'Failed to delete device',
        });

    } finally {
        if (connection) {
            connection.release();
        }
    }
}


// ============================================================
// GET DEVICE OBJECT
// ============================================================

async function getDeviceObject(
    connection,
    deviceId,
) {
    const rows = await connection.query(`
        SELECT
            d.id,
            d.name,
            d.device_type,
            d.icon,

            d.device_uid,
            d.device_ip,

            d.mqtt_topic,
            d.config_topic,
            d.control_topic,
            d.security_topic,

            d.is_online,

            ds.is_on,
            ds.temperature,
            ds.fan_speed,
            ds.security_state,
            ds.profile_version,
            ds.device_version

        FROM devices d

        LEFT JOIN device_states ds
            ON ds.device_id = d.id

        WHERE d.id = ?

        LIMIT 1
    `, [deviceId]);

    if (!rows.length) {
        return null;
    }

    const row = normalizeValue(rows[0]);

    return getDeviceJson(row);
}


// ============================================================
// FORMAT DEVICE JSON
// ============================================================

function getDeviceJson(row) {
    return {
        id: Number(row.id),

        name: row.name,

        device_type: row.device_type,

        icon: row.icon || 'devices',

        // ================================================
        // MQTT / DEVICE INFORMATION
        // ================================================

        device_uid: row.device_uid || null,

        device_ip: row.device_ip || null,

        mqtt_topic: row.mqtt_topic || null,

        config_topic: row.config_topic || null,

        control_topic: row.control_topic || null,

        security_topic: row.security_topic || null,

        // ================================================
        // STATUS
        // ================================================

        is_online: toBoolean(row.is_online),

        is_on: toBoolean(row.is_on),

        // ================================================
        // FAN
        // ================================================

        fan_speed:
            row.fan_speed !== null &&
            row.fan_speed !== undefined
                ? Number(row.fan_speed)
                : 0,

        temperature:
            toNumber(row.temperature),

        // ================================================
        // CAMERA
        // ================================================

        security_state:
            row.security_state || 'normal',

        // ================================================
        // PROFILE
        // ================================================

        profile_version:
            row.profile_version !== null &&
            row.profile_version !== undefined
                ? Number(row.profile_version)
                : 0,

        device_version:
            row.device_version !== null &&
            row.device_version !== undefined
                ? Number(row.device_version)
                : 0,
    };
}


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getDevices,
    getDeviceById,
    createDevice,
    updateDevice,
    deleteDevice,
};