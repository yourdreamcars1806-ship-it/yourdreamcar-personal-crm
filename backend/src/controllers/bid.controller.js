const Bid = require('../models/Bid');
const Car = require('../models/Car');
const User = require('../models/User');

function toDto(doc, extra = {}) {
  return {
    id: String(doc._id),
    carId: doc.carId ? String(doc.carId) : '',
    amount: doc.amount,
    name: doc.name || '',
    phone: doc.phone || '',
    city: doc.city || '',
    message: doc.message || '',
    carTitle: doc.carTitle || '',
    carImageUrl: doc.carImageUrl || '',
    askPrice: doc.askPrice || 0,
    status: doc.status,
    createdAt: doc.createdAt,
    ...extra,
  };
}

async function createBid(req, res) {
  try {
    const carId = String(req.body?.carId || '').trim();
    const name = String(req.body?.name || '').trim();
    const phone = String(req.body?.phone || '').trim();
    const city = String(req.body?.city || '').trim();
    const message = String(req.body?.message || '').trim();
    const amount = Number(req.body?.amount);

    if (!carId) {
      return res.status(400).json({ error: 'Car is required' });
    }
    if (!phone || phone.length < 8) {
      return res.status(400).json({ error: 'Enter a valid phone number' });
    }
    if (!Number.isFinite(amount) || amount < 1) {
      return res.status(400).json({ error: 'Enter a valid bid amount' });
    }

    const car = await Car.findById(carId).lean();
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }
    if (String(car.availability || '').toLowerCase() === 'outstock') {
      return res.status(400).json({ error: 'This car is no longer available' });
    }

    const title = String(car.title || `${car.brand} ${car.model}`).trim();
    const doc = await Bid.create({
      userId: req.userId,
      carId: car._id,
      amount,
      name,
      phone,
      city,
      message,
      carTitle: title,
      carImageUrl: car.imageUrl || '',
      askPrice: car.sellPrice || 0,
    });
    return res.status(201).json({ bid: toDto(doc) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to submit bid' });
  }
}

async function listMine(req, res) {
  try {
    const docs = await Bid.find({ userId: req.userId })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();
    return res.json({ bids: docs.map((d) => toDto(d)) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load bids' });
  }
}

async function listAll(req, res) {
  try {
    const docs = await Bid.find({})
      .sort({ createdAt: -1 })
      .limit(300)
      .lean();
    const userIds = [...new Set(docs.map((d) => String(d.userId)))];
    const users = await User.find({ _id: { $in: userIds } })
      .select('email name')
      .lean();
    const byId = Object.fromEntries(users.map((u) => [String(u._id), u]));
    return res.json({
      bids: docs.map((d) => {
        const u = byId[String(d.userId)] || {};
        return toDto(d, {
          userEmail: u.email || '',
          userName: u.name || '',
        });
      }),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load bids' });
  }
}

async function updateStatus(req, res) {
  try {
    const status = String(req.body?.status || '').trim().toLowerCase();
    if (!['pending', 'accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    const doc = await Bid.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Bid not found' });
    }
    doc.status = status;
    await doc.save();
    return res.json({ bid: toDto(doc.toObject()) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to update bid' });
  }
}

module.exports = { createBid, listMine, listAll, updateStatus };
