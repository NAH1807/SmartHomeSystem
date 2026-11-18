const express = require('express');

const {
    getMotion,
    saveMotion,
} = require('../controllers/motion');

const router = express.Router();

router.get(
    '/devices/:deviceId/motion',
    getMotion,
);

router.put(
    '/devices/:deviceId/motion',
    saveMotion,
);

module.exports = router;