const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
        return res.status(401).json({
            message: 'Bạn cần đăng nhập để thực hiện chức năng này',
        });
    }

    const token = authorization.split(' ')[1];

    try {
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        req.user = decoded;

        next();
    } catch (error) {
        return res.status(401).json({
            message: 'Token không hợp lệ hoặc đã hết hạn',
        });
    }
}

module.exports = {
    authenticateToken,
};