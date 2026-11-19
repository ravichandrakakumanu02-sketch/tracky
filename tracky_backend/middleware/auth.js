const jwt = require('jsonwebtoken');

/**
 * Authentication middleware that verifies JWT tokens.
 * Extracts token from 'Authorization: Bearer <token>' header.
 * Attaches decoded user info (req.userId, req.userEmail) to request object.
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Access denied. No authentication token provided.'
    });
  }

  const token = authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      error: 'Access denied. Authentication token missing.'
    });
  }

  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      console.error('FATAL: JWT_SECRET environment variable is not defined.');
      return res.status(500).json({ error: 'Server authentication configuration error.' });
    }

    const decoded = jwt.verify(token, secret);
    req.userId = decoded.userId;
    req.userEmail = decoded.email;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Authentication token has expired. Please log in again.' });
    }
    return res.status(401).json({ error: 'Invalid authentication token.' });
  }
}

module.exports = authMiddleware;
