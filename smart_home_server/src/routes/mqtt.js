const express = require('express');

const {
    mqttStatus,
    relayChannel,
    relayAll,
    fanLevel,
    motion,
    cameraSecurity,
    quarantine,
    release,
    syncProfile,
} = require('../controllers/mqtt');

const router = express.Router();

router.get(
    '/status',
    mqttStatus,
);

router.post(
    '/relay/channel',
    relayChannel,
);

router.post(
    '/relay/all',
    relayAll,
);

router.post(
    '/fan/level',
    fanLevel,
);

router.post(
    '/camera/security',
    cameraSecurity,
);

router.post(
    '/security/:deviceUid/quarantine',
    quarantine,
);

router.post(
    '/security/:deviceUid/release',
    release,
);

router.post(
    '/profile/:deviceId/sync',
    syncProfile,
);

router.post(
    '/motion/:deviceId',
    motion
);

module.exports = router;