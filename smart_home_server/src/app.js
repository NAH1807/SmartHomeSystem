const express = require('express');
const cors = require('cors');

const deviceRoutes = require('./routes/device');
const automationRoutes = require('./routes/automation');
const mqttRoutes = require('./routes/mqtt');
const motionRoutes = require('./routes/motion');

const app = express();

app.use(
    cors({
        origin: '*',
    }),
);

app.use(express.json());
app.use(
    express.urlencoded({
        extended: true,
    }),
);

app.get('/', (req, res) => {
    res.json({
        message:
            'Smart Home API is running',
    });
});

app.use(
    '/api/devices',
    deviceRoutes,
);

app.use(
    '/api',
    automationRoutes,
);

app.use(
    '/api/mqtt',
    mqttRoutes,
);

app.use(
    '/api',
    motionRoutes
);

app.use((req, res) => {
    res.status(404).json({
        message:
            'API endpoint not found',
    });
});

app.use(
    (err, req, res, next) => {
        console.error(err);

        res.status(500).json({
            message:
                err.message ||
                'Internal server error',
        });
    },
);

module.exports = app;