const jwt = require('jsonwebtoken');
const User = require('../models/User');

const activityThrottleMs = 2 * 60 * 1000;
const lastTouchByUser = new Map();

function touchUserActivity(userId) {
  if (!userId) return;
  const key = String(userId);
  const now = Date.now();
  const prev = lastTouchByUser.get(key) || 0;
  if (now - prev < activityThrottleMs) return;
  lastTouchByUser.set(key, now);
  User.updateOne({ _id: userId }, { $set: { lastActiveAt: new Date() } }).catch(() => {});
}

function getJwtSecret() {
  const s = process.env.JWT_SECRET;
  if (!s) {
    throw new Error('JWT_SECRET is not set');
  }
  return s;
}

/** Express middleware: sets req.userId and req.userRole from Bearer JWT */
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
    req.userRole = payload.role === 'user' ? 'user' : 'admin';
    touchUserActivity(sub);
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireAdmin(req, res, next) {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  return next();
}

/** Attaches user if a valid Bearer token is present; never fails the request. */
function optionalAuth(req, _res, next) {
  try {
    const h = req.headers.authorization || '';
    const m = h.match(/^Bearer\s+(.+)$/i);
    if (!m) return next();
    const payload = jwt.verify(m[1], getJwtSecret());
    if (payload.sub) {
      req.userId = payload.sub;
      req.userRole = payload.role === 'user' ? 'user' : 'admin';
    }
  } catch (_err) {
    // ignore invalid tokens on public reads
  }
  return next();
}

module.exports = { requireAuth, requireAdmin, optionalAuth, getJwtSecret, touchUserActivity };
