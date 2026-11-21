
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const { pool } = require('../config/database');
const { sendResetOtp } = require('../services/email');

const SALT_ROUNDS = 12;
const OTP_EXPIRES_MINUTES = 5;
const MAX_OTP_ATTEMPTS = 5;

function createAccessToken(user) {
    return jwt.sign(
        {
            id: user.id,
            username: user.username,
            email: user.email,
        },
        process.env.JWT_SECRET,
        {
            expiresIn: process.env.JWT_EXPIRES_IN || '7d',
        }
    );
}

function generateOtp() {
    return crypto.randomInt(100000, 1000000).toString();
}

function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// ======================================================
// REGISTER
// POST /api/auth/register
// ======================================================

async function register(req, res) {
    let conn;

    try {
        const { username, email, password } = req.body;

        if (!username || !email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ thông tin',
            });
        }

        const normalizedUsername = String(username).trim();
        const normalizedEmail = String(email).trim().toLowerCase();

        if (normalizedUsername.length < 4 ||
            normalizedUsername.length > 100) {
            return res.status(400).json({
                message: 'Username phải có từ 4 đến 100 ký tự',
            });
        }

        if (!isValidEmail(normalizedEmail) ||
            normalizedEmail.length > 255) {
            return res.status(400).json({
                message: 'Email không hợp lệ',
            });
        }

        if (typeof password !== 'string' || password.length < 8) {
            return res.status(400).json({
                message: 'Mật khẩu phải có ít nhất 8 ký tự',
            });
        }

        const passwordHash = await bcrypt.hash(
            password,
            SALT_ROUNDS
        );

        conn = await pool.getConnection();

        await conn.query(
            `INSERT INTO users
                (username, email, password_hash)
             VALUES (?, ?, ?)`,
            [
                normalizedUsername,
                normalizedEmail,
                passwordHash,
            ]
        );

        return res.status(201).json({
            message: 'Đăng ký tài khoản thành công',
        });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Username hoặc email đã tồn tại',
            });
        }

        console.error('[AUTH] Register error:', error);

        return res.status(500).json({
            message: 'Không thể đăng ký tài khoản',
        });
    } finally {
        if (conn) conn.release();
    }
}

// ======================================================
// LOGIN
// POST /api/auth/login
// ======================================================

async function login(req, res) {
    let conn;

    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập tài khoản và mật khẩu',
            });
        }

        conn = await pool.getConnection();

        const users = await conn.query(
            `SELECT id, username, email, password_hash
             FROM users
             WHERE username = ? OR email = ?
             LIMIT 1`,
            [
                String(username).trim(),
                String(username).trim().toLowerCase(),
            ]
        );

        if (users.length === 0) {
            return res.status(401).json({
                message: 'Tài khoản hoặc mật khẩu không chính xác',
            });
        }

        const user = users[0];

        const passwordValid = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!passwordValid) {
            return res.status(401).json({
                message: 'Tài khoản hoặc mật khẩu không chính xác',
            });
        }

        const token = createAccessToken(user);

        return res.json({
            message: 'Đăng nhập thành công',
            token,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
            },
        });
    } catch (error) {
        console.error('[AUTH] Login error:', error);

        return res.status(500).json({
            message: 'Không thể đăng nhập',
        });
    } finally {
        if (conn) conn.release();
    }
}

// ======================================================
// SEND RESET OTP
// POST /api/auth/forgot-password
// ======================================================

async function sendOtp(req, res) {
    let conn;

    // Trả cùng một thông báo để tránh tiết lộ email
    // nào đã đăng ký trong hệ thống.
    const genericResponse = {
        message: 'Nếu email tồn tại, mã OTP sẽ được gửi đến email đó',
    };

    try {
        const email = String(req.body.email || '')
            .trim()
            .toLowerCase();

        if (!isValidEmail(email)) {
            return res.status(400).json({
                message: 'Email không hợp lệ',
            });
        }

        conn = await pool.getConnection();

        const users = await conn.query(
            `SELECT id, email
             FROM users
             WHERE email = ?
             LIMIT 1`,
            [email]
        );

        if (users.length === 0) {
            return res.json(genericResponse);
        }

        const user = users[0];

        // Hủy các OTP cũ chưa sử dụng của tài khoản.
        await conn.query(
            `DELETE FROM password_reset_otps
             WHERE user_id = ?`,
            [user.id]
        );

        const otp = generateOtp();
        const otpHash = await bcrypt.hash(otp, SALT_ROUNDS);

        const expiresAt = new Date(
            Date.now() + OTP_EXPIRES_MINUTES * 60 * 1000
        );

        const expiresAtSql = expiresAt
            .toISOString()
            .slice(0, 19)
            .replace('T', ' ');

        await conn.query(
            `INSERT INTO password_reset_otps
                (user_id, otp_hash, expires_at)
             VALUES (?, ?, ?)`,
            [
                user.id,
                otpHash,
                expiresAtSql,
            ]
        );

        try {
            await sendResetOtp(user.email, otp);
        } catch (emailError) {
            await conn.query(
                `DELETE FROM password_reset_otps
                 WHERE user_id = ?`,
                [user.id]
            );

            console.error('[AUTH] Email error:', emailError);

            return res.status(500).json({
                message: 'Không thể gửi email OTP',
            });
        }

        return res.json(genericResponse);
    } catch (error) {
        console.error('[AUTH] Send OTP error:', error);

        return res.status(500).json({
            message: 'Không thể xử lý yêu cầu',
        });
    } finally {
        if (conn) conn.release();
    }
}

// ======================================================
// VERIFY RESET OTP
// POST /api/auth/verify-otp
// ======================================================

async function verifyOtp(req, res) {
    let conn;

    try {
        const email = String(req.body.email || '')
            .trim()
            .toLowerCase();

        const otp = String(req.body.otp || '').trim();

        if (!isValidEmail(email) || !/^\d{6}$/.test(otp)) {
            return res.status(400).json({
                message: 'Email hoặc OTP không hợp lệ',
            });
        }

        conn = await pool.getConnection();

        const rows = await conn.query(
            `SELECT
                r.id,
                r.user_id,
                r.otp_hash,
                r.attempts
             FROM password_reset_otps r
             JOIN users u ON u.id = r.user_id
             WHERE u.email = ?
               AND r.expires_at > UTC_TIMESTAMP()
               AND r.used_at IS NULL
               AND r.verified_at IS NULL
             ORDER BY r.id DESC
             LIMIT 1`,
            [email]
        );

        if (rows.length === 0) {
            return res.status(400).json({
                message: 'OTP không hợp lệ hoặc đã hết hạn',
            });
        }

        const record = rows[0];

        if (record.attempts >= MAX_OTP_ATTEMPTS) {
            return res.status(429).json({
                message: 'Bạn đã nhập sai OTP quá số lần cho phép',
            });
        }

        const valid = await bcrypt.compare(
            otp,
            record.otp_hash
        );

        if (!valid) {
            await conn.query(
                `UPDATE password_reset_otps
                 SET attempts = attempts + 1
                 WHERE id = ?`,
                [record.id]
            );

            return res.status(400).json({
                message: 'OTP không chính xác',
            });
        }

        await conn.query(
            `UPDATE password_reset_otps
             SET verified_at = UTC_TIMESTAMP()
             WHERE id = ?`,
            [record.id]
        );

        const resetToken = jwt.sign(
            {
                userId: record.user_id,
                otpId: record.id,
                purpose: 'password_reset',
            },
            process.env.JWT_SECRET,
            {
                expiresIn: '5m',
            }
        );

        return res.json({
            message: 'Xác thực OTP thành công',
            resetToken,
        });
    } catch (error) {
        console.error('[AUTH] Verify OTP error:', error);

        return res.status(500).json({
            message: 'Không thể xác thực OTP',
        });
    } finally {
        if (conn) conn.release();
    }
}

// ======================================================
// RESET PASSWORD
// POST /api/auth/reset-password
// ======================================================

async function resetPassword(req, res) {
    let conn;

    try {
        const { resetToken, newPassword } = req.body;

        if (!resetToken || !newPassword) {
            return res.status(400).json({
                message: 'Thiếu thông tin đặt lại mật khẩu',
            });
        }

        if (typeof newPassword !== 'string' ||
            newPassword.length < 8) {
            return res.status(400).json({
                message: 'Mật khẩu phải có ít nhất 8 ký tự',
            });
        }

        let decoded;

        try {
            decoded = jwt.verify(
                resetToken,
                process.env.JWT_SECRET
            );
        } catch (_) {
            return res.status(401).json({
                message: 'Phiên đặt lại mật khẩu không hợp lệ hoặc đã hết hạn',
            });
        }

        if (decoded.purpose !== 'password_reset') {
            return res.status(401).json({
                message: 'Token không hợp lệ',
            });
        }

        const passwordHash = await bcrypt.hash(
            newPassword,
            SALT_ROUNDS
        );

        conn = await pool.getConnection();

        await conn.beginTransaction();

        const records = await conn.query(
            `SELECT id, user_id
             FROM password_reset_otps
             WHERE id = ?
               AND user_id = ?
               AND verified_at IS NOT NULL
               AND used_at IS NULL
               AND expires_at > UTC_TIMESTAMP()
             FOR UPDATE`,
            [
                decoded.otpId,
                decoded.userId,
            ]
        );

        if (records.length === 0) {
            await conn.rollback();

            return res.status(400).json({
                message: 'Yêu cầu đặt lại mật khẩu không còn hợp lệ',
            });
        }

        await conn.query(
            `UPDATE users
             SET password_hash = ?
             WHERE id = ?`,
            [
                passwordHash,
                decoded.userId,
            ]
        );

        await conn.query(
            `UPDATE password_reset_otps
             SET used_at = UTC_TIMESTAMP()
             WHERE id = ?`,
            [decoded.otpId]
        );

        await conn.commit();

        return res.json({
            message: 'Đặt lại mật khẩu thành công',
        });
    } catch (error) {
        if (conn) {
            await conn.rollback();
        }

        console.error('[AUTH] Reset password error:', error);

        return res.status(500).json({
            message: 'Không thể đặt lại mật khẩu',
        });
    } finally {
        if (conn) conn.release();
    }
}

function getMe(req, res) {
    return res.json({
        user: {
            id: req.user.id,
            username: req.user.username,
            email: req.user.email,
        },
    });
}

module.exports = {
    register,
    login,
    sendOtp,
    verifyOtp,
    resetPassword,
    getMe,
};
