const Notification = require('../models/Notification');
const { subscribe, broadcast, toPublic } = require('../services/notificationHub');

async function notifyCarAdded(car) {
  if (!car) return null;
  if (String(car.availability || '').toLowerCase() === 'outstock') {
    return null;
  }
  const title = String(car.title || `${car.brand || ''} ${car.model || ''}`).trim();
  const year = car.year ? String(car.year) : '';
  const label = [title, year].filter(Boolean).join(' ');
  const doc = await Notification.create({
    type: 'car_added',
    title: 'New Car Added!',
    body: `${label} is now available. Tap to view details.`,
    carId: car._id,
    carTitle: title,
    imageUrl: car.imageUrl || '',
  });
  broadcast(doc);
  return doc;
}

async function listNotifications(req, res) {
  try {
    const sinceRaw = String(req.query.since || '').trim();
    const limitRaw = Number(req.query.limit);
    const limit = Number.isFinite(limitRaw)
      ? Math.max(1, Math.min(80, Math.floor(limitRaw)))
      : 40;
    const q = {};
    if (sinceRaw) {
      const since = new Date(sinceRaw);
      if (!Number.isNaN(since.getTime())) {
        q.createdAt = { $gt: since };
      }
    }
    const rows = await Notification.find(q)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    return res.json({ notifications: rows.map(toPublic) });
  } catch (err) {
    return res
      .status(500)
      .json({ error: err.message || 'Failed to list notifications' });
  }
}

function streamNotifications(req, res) {
  subscribe(req, res);
}

module.exports = {
  notifyCarAdded,
  listNotifications,
  streamNotifications,
};
