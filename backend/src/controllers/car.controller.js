const Car = require('../models/Car');
const SUMMARY_CACHE_TTL_MS = Math.min(
  120_000,
  Math.max(15_000, Number(process.env.CARS_SUMMARY_CACHE_MS) || 45_000)
);
const MAX_LIST_LIMIT = 1000;
const DEFAULT_LIST_LIMIT = Math.max(
  1,
  Math.min(MAX_LIST_LIMIT, Number(process.env.CARS_LIST_LIMIT) || 200)
);
let summaryCache = {
  value: null,
  expiresAt: 0,
};

function invalidateSummaryCache() {
  summaryCache = { value: null, expiresAt: 0 };
}

async function getSummary() {
  const now = Date.now();
  if (summaryCache.value && summaryCache.expiresAt > now) {
    return summaryCache.value;
  }

  const [total, grouped] = await Promise.all([
    Car.estimatedDocumentCount(),
    Car.aggregate([{ $group: { _id: '$availability', count: { $sum: 1 } } }]),
  ]);

  const summary = { total, stock: 0, outstock: 0 };
  for (const row of grouped) {
    if (row._id === 'stock') summary.stock = row.count;
    if (row._id === 'outstock') summary.outstock = row.count;
  }

  summaryCache = {
    value: summary,
    expiresAt: now + SUMMARY_CACHE_TTL_MS,
  };
  return summary;
}

function uploadBufferToCloudinary(cloudinary, buffer, options = {}) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: 'yourdreamcar/cars', resource_type: 'image', ...options },
      (err, result) => {
        if (err) reject(err);
        else resolve(result);
      }
    );
    stream.end(buffer);
  });
}

function parseCreatePayload(body) {
  return {
    title: String(body.title || '').trim(),
    vehicleNumber: String(body.vehicleNumber || '').trim(),
    brand: String(body.brand || '').trim(),
    model: String(body.model || '').trim(),
    fuelType: String(body.fuelType || '').trim().toUpperCase(),
    ownership: String(body.ownership || '').trim(),
    availability: String(body.availability || '').trim().toLowerCase(),
    year: Number(body.year),
    buyPrice: Number(body.buyPrice),
    sellPrice: Number(body.sellPrice),
    buyDate: body.buyDate ? new Date(body.buyDate) : null,
    saleDate: body.saleDate ? new Date(body.saleDate) : null,
    description: String(body.description || '').trim(),
  };
}

function validatePayload(data, { requireImage }) {
  const required = ['title', 'brand', 'model', 'fuelType', 'ownership', 'availability'];
  for (const k of required) {
    if (!data[k]) {
      return `${k} is required`;
    }
  }
  if (Number.isNaN(data.year) || data.year < 1980 || data.year > 2100) {
    return 'year must be between 1980 and 2100';
  }
  if (Number.isNaN(data.buyPrice) || data.buyPrice < 0) {
    return 'buyPrice must be a valid number';
  }
  if (Number.isNaN(data.sellPrice) || data.sellPrice < 0) {
    return 'sellPrice must be a valid number';
  }
  if (!(data.buyDate instanceof Date) || Number.isNaN(data.buyDate.getTime())) {
    return 'buyDate must be a valid date';
  }
  if (data.saleDate && Number.isNaN(data.saleDate.getTime())) {
    return 'saleDate must be a valid date';
  }
  if (requireImage && !data.imageUrl) {
    return 'image is required';
  }
  return null;
}

async function createCar(req, res, cloudinary) {
  try {
    if (!cloudinary) {
      return res.status(503).json({
        error: 'Cloudinary is not configured. Set CLOUDINARY_* in .env',
      });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'image file is required' });
    }

    const parsed = parseCreatePayload(req.body);
    const uploaded = await uploadBufferToCloudinary(cloudinary, req.file.buffer);
    parsed.imageUrl = uploaded.secure_url;
    parsed.imagePublicId = uploaded.public_id;

    const validationError = validatePayload(parsed, { requireImage: true });
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const car = await Car.create(parsed);
    invalidateSummaryCache();
    return res.status(201).json({ car });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Create car failed' });
  }
}

async function listCars(req, res) {
  try {
    const availability = req.query.availability
      ? String(req.query.availability).toLowerCase()
      : null;
    const requestedLimit = Number(req.query.limit);
    const limit = Number.isFinite(requestedLimit)
      ? Math.max(1, Math.min(MAX_LIST_LIMIT, Math.floor(requestedLimit)))
      : DEFAULT_LIST_LIMIT;
    const q = availability ? { availability } : {};
    const omitDesc = ['1', 'true', 'yes'].includes(
      String(req.query.omitDescription || '').trim().toLowerCase()
    );
    const selectFields = omitDesc
      ? '_id title vehicleNumber brand model fuelType ownership availability year buyPrice sellPrice buyDate saleDate imageUrl createdAt'
      : '_id title vehicleNumber brand model fuelType ownership availability year buyPrice sellPrice buyDate saleDate description imageUrl createdAt';

    const [cars, summary] = await Promise.all([
      Car.find(q)
        .select(selectFields)
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean(),
      getSummary(),
    ]);
    res.set(
      'Cache-Control',
      omitDesc ? 'public, max-age=15, stale-while-revalidate=30' : 'public, max-age=10'
    );
    return res.json({ cars, summary });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'List cars failed' });
  }
}

async function updateCar(req, res, cloudinary) {
  try {
    const car = await Car.findById(req.params.id);
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }

    const parsed = parseCreatePayload({ ...car.toObject(), ...req.body });

    if (req.file) {
      if (!cloudinary) {
        return res.status(503).json({
          error: 'Cloudinary is not configured. Set CLOUDINARY_* in .env',
        });
      }
      const uploaded = await uploadBufferToCloudinary(cloudinary, req.file.buffer);
      if (car.imagePublicId) {
        try {
          await cloudinary.uploader.destroy(car.imagePublicId);
        } catch (_e) {}
      }
      parsed.imageUrl = uploaded.secure_url;
      parsed.imagePublicId = uploaded.public_id;
    } else {
      parsed.imageUrl = car.imageUrl;
      parsed.imagePublicId = car.imagePublicId;
    }

    const validationError = validatePayload(parsed, { requireImage: true });
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    Object.assign(car, parsed);
    await car.save();
    invalidateSummaryCache();
    return res.json({ car });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Update car failed' });
  }
}

async function deleteCar(req, res, cloudinary) {
  try {
    const car = await Car.findById(req.params.id);
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }
    if (cloudinary && car.imagePublicId) {
      try {
        await cloudinary.uploader.destroy(car.imagePublicId);
      } catch (_e) {}
    }
    await car.deleteOne();
    invalidateSummaryCache();
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Delete car failed' });
  }
}

module.exports = { createCar, listCars, updateCar, deleteCar };
