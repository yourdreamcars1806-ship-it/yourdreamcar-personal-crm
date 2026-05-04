const jwt = require('jsonwebtoken');

function getJwtSecret() {
  const s = process.env.JWT_SECRET;
  if (!s) {
    throw new Error('JWT_SECRET is not set');
  }
  return s;
}

/** Express middleware: sets req.userId from Bearer JWT */
function requireAuth(req, res, next) {
  try {
    const h = req.headers.authorization || '';
    const m = h.match(/^Bearer\s+(.+)$/i);
    if (!m) {
      return res.status(401).json({ error: 'Missing Authorization: Bearer <token>' });
    }
    const payload = jwt.verify(m[1], getJwtSecret());
    const sub = payload.sub;
    if (!sub) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    req.userId = sub;
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth, getJwtSecret };
