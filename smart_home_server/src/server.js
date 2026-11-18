require('dotenv').config();

const app =
    require('./app');

const {
    connectMqtt,
} = require('./services/mqtt');

const {
    processAutomations,
} = require('./services/automation');

const PORT =
    Number(process.env.PORT || 3000);

app.listen(
    PORT,
    '0.0.0.0',
    async () => {
        console.log(
            `Smart Home server running on port ${PORT}`,
        );

        console.log(
            `http://localhost:${PORT}`,
        );

        try {
            await connectMqtt();

            console.log(
                '[MQTT] MQTT service started',
            );
        } catch (error) {
            console.error(
                '[MQTT] Startup error:',
                error,
            );
        }

        console.log(
            '[Automation] Scheduler started',
        );

        processAutomations();

        setInterval(
            processAutomations,
            60 * 1000,
        );
    },
);