const Bid = require('../models/Bid');
const Car = require('../models/Car');
const User = require('../models/User');
const { invalidateSummaryCache } = require('./car.controller');

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

async function maybeAutoWin(bidDoc) {
  const car = await Car.findById(bidDoc.carId);
  if (!car || String(car.availability || '').toLowerCase() === 'outstock') {
    return false;
  }

  const bidAmount = Math.round(Number(bidDoc.amount));
  const askPrice = Math.round(Number(car.sellPrice));
  if (!Number.isFinite(bidAmount) || !Number.isFinite(askPrice) || bidAmount !== askPrice) {
    return false;
  }

  bidDoc.status = 'accepted';
  await bidDoc.save();

  car.availability = 'outstock';
  car.saleDate = car.saleDate || new Date();
  await car.save();

  await Bid.updateMany(
    { carId: car._id, _id: { $ne: bidDoc._id }, status: 'pending' },
    { $set: { status: 'rejected' } },
  );

  invalidateSummaryCache();
  return true;
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
    if (!car.liveBidEnabled) {
      return res.status(400).json({ error: 'Live bidding is not open for this car yet' });
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

    const instantWin = await maybeAutoWin(doc);
    const fresh = await Bid.findById(doc._id).lean();
    return res.status(201).json({
      bid: toDto(fresh),
      instantWin,
    });
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

async function updateBid(req, res) {
  try {
    const doc = await Bid.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Bid not found' });
    }

    if (req.body?.amount != null) {
      const amount = Number(req.body.amount);
      if (!Number.isFinite(amount) || amount < 1) {
        return res.status(400).json({ error: 'Enter a valid bid amount' });
      }
      doc.amount = amount;
    }

    if (req.body?.status != null) {
      const status = String(req.body.status || '').trim().toLowerCase();
      if (!['pending', 'accepted', 'rejected'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
      }
      doc.status = status;

      if (status === 'accepted') {
        const car = await Car.findById(doc.carId);
        if (car && String(car.availability).toLowerCase() !== 'outstock') {
          car.availability = 'outstock';
          car.saleDate = car.saleDate || new Date();
          await car.save();
          await Bid.updateMany(
            { carId: car._id, _id: { $ne: doc._id }, status: 'pending' },
            { $set: { status: 'rejected' } },
          );
          invalidateSummaryCache();
        }
      }
    }

    await doc.save();
    const instantWin = doc.status === 'pending' ? await maybeAutoWin(doc) : false;
    const fresh = await Bid.findById(doc._id).lean();
    return res.json({ bid: toDto(fresh), instantWin });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to update bid' });
  }
}

async function updateMyBid(req, res) {
  try {
    const doc = await Bid.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Bid not found' });
    }
    if (String(doc.userId) !== String(req.userId)) {
      return res.status(403).json({ error: 'Not your bid' });
    }
    if (doc.status !== 'pending') {
      return res.status(400).json({ error: 'Only pending bids can be updated' });
    }

    const amount = Number(req.body?.amount);
    if (!Number.isFinite(amount) || amount < 1) {
      return res.status(400).json({ error: 'Enter a valid bid amount' });
    }

    const car = await Car.findById(doc.carId).lean();
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }
    if (String(car.availability || '').toLowerCase() === 'outstock') {
      return res.status(400).json({ error: 'This car is no longer available' });
    }

    doc.amount = amount;
    await doc.save();
    const instantWin = await maybeAutoWin(doc);
    const fresh = await Bid.findById(doc._id).lean();
    return res.json({ bid: toDto(fresh), instantWin });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to update bid' });
  }
}

async function deleteBid(req, res) {
  try {
    const doc = await Bid.findByIdAndDelete(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Bid not found' });
    }
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to delete bid' });
  }
}

module.exports = { createBid, listMine, listAll, updateBid, updateMyBid, deleteBid };
