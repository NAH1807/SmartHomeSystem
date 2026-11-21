
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

async function sendResetOtp(email, otp) {
    await transporter.sendMail({
        from: process.env.SMTP_FROM || process.env.SMTP_USER,
        to: email,
        subject: 'Smart Home - Password Reset OTP',
        html: `
            <div style="font-family: Arial, sans-serif;">
                <h2>Smart Home</h2>
                <p>Bạn vừa yêu cầu đặt lại mật khẩu.</p>
                <p>Mã xác thực OTP của bạn là:</p>
                <h1 style="letter-spacing: 8px;">${otp}</h1>
                <p>Mã có hiệu lực trong 5 phút.</p>
                <p>Nếu bạn không thực hiện yêu cầu này,
                   hãy bỏ qua email.</p>
            </div>
        `,
    });
}

module.exports = {
    sendResetOtp,
};
