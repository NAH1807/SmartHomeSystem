
const express = require('express');

const {
    getAutomation,
    saveAutomation,
    deleteAutomation,
} = require('../controllers/automation');

const router = express.Router();
router.get(
    '/devices/:deviceId/automation',
    getAutomation,
);
router.put(
    '/devices/:deviceId/automation',
    saveAutomation,
);
router.delete(
    '/devices/:deviceId/automation',
    deleteAutomation,
);

module.exports = router;
