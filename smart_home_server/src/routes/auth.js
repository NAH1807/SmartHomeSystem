const express = require('express');

const {
    register,
    login,
    sendOtp,
    verifyOtp,
    resetPassword,
    getMe,
} = require('../controllers/auth');

const {
    authenticateToken,
} = require('../middleware/auth');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);

router.post('/forgot-password', sendOtp);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);

router.get('/me', authenticateToken, getMe);
module.exports = router;