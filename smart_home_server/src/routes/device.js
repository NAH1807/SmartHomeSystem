const express = require('express');

const {
    getDevices,
    getDeviceById,
    createDevice,
    updateDevice,
    deleteDevice,
} = require('../controllers/device');

const router = express.Router();


// ============================================================
// DEVICE CRUD
// ============================================================

// GET /api/devices
router.get('/', getDevices);

// GET /api/devices/:id
router.get('/:id', getDeviceById);

// POST /api/devices
router.post('/', createDevice);

// PUT /api/devices/:id
router.put('/:id', updateDevice);

// DELETE /api/devices/:id
router.delete('/:id', deleteDevice);


// ============================================================
// DEVICE CONTROL
// ============================================================


module.exports = router;