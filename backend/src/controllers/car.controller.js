const Car = require('../models/Car');
const { uploadImageBufferStream } = require('../utils/cloudinaryImageUpload');
const { notifyCarAdded, notifyLiveBidStarted } = require('./notification.controller');
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

function isAdminReq(req) {
  return req.userRole === 'admin';
}

function toClientCar(doc, admin) {
  const o =
    doc && typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
  if (!admin) {
    delete o.buyPrice;
    delete o.buyDate;
    delete o.imagePublicId;
    delete o.__v;
    o.exteriorImages = mapImagesForClient(o.exteriorImages, false);
    o.interiorImages = mapImagesForClient(o.interiorImages, false);
  }
  return o;
}

function mapImagesForClient(images, admin) {
  if (!Array.isArray(images)) return [];
  return images
    .map((img) => {
      if (typeof img === 'string') return img.trim();
      if (img && typeof img === 'object') {
        if (admin) return img;
        return String(img.url || '').trim();
      }
      return '';
    })
    .filter(Boolean);
}

function parseJsonUrlList(body, key) {
  const raw = body?.[key];
  if (raw == null || raw === '') return null;
  if (Array.isArray(raw)) return raw.map(String).filter(Boolean);
  try {
    const parsed = JSON.parse(String(raw));
    if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean);
  } catch (_e) {}
  return null;
}

function getUploadFiles(req, field) {
  const files = req.files?.[field];
  return Array.isArray(files) ? files : [];
}

function getMainUploadFile(req) {
  const fromFields = req.files?.image?.[0];
  if (fromFields) return fromFields;
  return req.file || null;
}

async function uploadMany(cloudinary, files, folder) {
  if (!cloudinary || !files?.length) return [];
  const uploaded = [];
  for (const file of files) {
    const result = await uploadImageBufferStream(cloudinary, file.buffer, folder);
    uploaded.push({ url: result.secure_url, publicId: result.public_id });
  }
  return uploaded;
}

async function destroyImages(cloudinary, images) {
  if (!cloudinary || !Array.isArray(images)) return;
  for (const img of images) {
    const publicId = img?.publicId || img?.public_id;
    if (!publicId) continue;
    try {
      await cloudinary.uploader.destroy(publicId);
    } catch (_e) {}
  }
}

function mergeImageLists(existing, keepUrls, uploaded) {
  const kept = [];
  const wanted = new Set((keepUrls || []).map(String));
  for (const url of wanted) {
    const found = (existing || []).find((img) => img.url === url);
    kept.push(found || { url, publicId: '' });
  }
  return [...kept, ...(uploaded || [])];
}

function removedImages(existing, keepUrls) {
  const wanted = new Set((keepUrls || []).map(String));
  return (existing || []).filter((img) => img?.url && !wanted.has(img.url));
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

function formatCarSaveError(err) {
  if (!err) {
    return { status: 500, message: 'Save failed' };
  }
  if (err.name === 'ValidationError') {
    const parts = Object.values(err.errors || {}).map((e) => e.message);
    const msg = parts.length ? parts.join('; ') : err.message;
    return { status: 400, message: msg };
  }
  const raw =
    typeof err.message === 'string'
      ? err.message
      : err.error?.message || String(err);
  const httpCode = err.http_code ?? err.error?.http_code ?? err.response?.status;
  const forbiddenUpload =
    httpCode === 403 ||
    httpCode === 401 ||
    /\b403\b/.test(raw) ||
    /Invalid credentials/i.test(raw) ||
    /Invalid api/i.test(raw) ||
    /not authorized/i.test(raw);

  if (forbiddenUpload) {
    return {
      status: 503,
      message:
        'Photo upload failed (Cloudinary rejected auth). Fix Railway Variables: either set CLOUDINARY_CLOUD_NAME + CLOUDINARY_API_KEY + CLOUDINARY_API_SECRET (exact copy from Cloudinary → API Keys, no quotes/spaces), OR set one CLOUDINARY_URL=cloudinary://KEY:SECRET@CLOUD_NAME (URL-encode characters like @ in SECRET). Redeploy after saving.',
    };
  }
  return { status: 500, message: raw || 'Save failed' };
}

function parseBool(v, fallback = false) {
  if (v === undefined || v === null || v === '') return fallback;
  const s = String(v).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(s)) return true;
  if (['false', '0', 'no', 'off'].includes(s)) return false;
  return fallback;
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
    liveBidEnabled: parseBool(body.liveBidEnabled, false),
  };
}

function applyLiveBidTiming(parsed, previous) {
  const wasEnabled = previous?.liveBidEnabled === true;
  const nowEnabled = parsed.liveBidEnabled === true;
  if (nowEnabled && !wasEnabled) {
    parsed.liveBidStartedAt = new Date();
  } else if (!nowEnabled) {
    parsed.liveBidStartedAt = null;
  } else if (previous?.liveBidStartedAt) {
    parsed.liveBidStartedAt = previous.liveBidStartedAt;
  } else if (nowEnabled) {
    parsed.liveBidStartedAt = new Date();
  }
  return parsed;
}

function validatePayload(data, { requireImage }) {
  const required = ['title', 'brand', 'model', 'fuelType', 'ownership', 'availability'];
  for (const k of required) {
    if (!data[k]) {
      return `${k} is required`;
    }
  }
  const ownershipEnum = Car.schema.path('ownership')?.enumValues;
  if (
    Array.isArray(ownershipEnum) &&
    ownershipEnum.length > 0 &&
    !ownershipEnum.includes(data.ownership)
  ) {
    return `ownership must be one of: ${ownershipEnum.join(', ')}`;
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
    const mainFile = getMainUploadFile(req);
    if (!mainFile) {
      return res.status(400).json({ error: 'image file is required' });
    }

    const parsed = parseCreatePayload(req.body);
    applyLiveBidTiming(parsed, null);
    const validationError = validatePayload(parsed, { requireImage: false });
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const uploaded = await uploadImageBufferStream(
      cloudinary,
      mainFile.buffer,
      'yourdreamcar/cars'
    );
    parsed.imageUrl = uploaded.secure_url;
    parsed.imagePublicId = uploaded.public_id;

    parsed.exteriorImages = await uploadMany(
      cloudinary,
      getUploadFiles(req, 'exteriorImages'),
      'yourdreamcar/cars/exterior'
    );
    parsed.interiorImages = await uploadMany(
      cloudinary,
      getUploadFiles(req, 'interiorImages'),
      'yourdreamcar/cars/interior'
    );

    const car = await Car.create(parsed);
    invalidateSummaryCache();
    notifyCarAdded(car).catch((err) => {
      console.error('[notify] car_added failed:', err.message);
    });
    if (car.liveBidEnabled) {
      notifyLiveBidStarted(car).catch((err) => {
        console.error('[notify] live_bid failed:', err.message);
      });
    }
    return res.status(201).json({ car: toClientCar(car, true) });
  } catch (err) {
    const { status, message } = formatCarSaveError(err);
    return res.status(status).json({ error: message });
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
    const omitSummary = ['1', 'true', 'yes'].includes(
      String(req.query.omitSummary || '').trim().toLowerCase()
    );
    const admin = isAdminReq(req);
    const selectFields = admin
      ? omitDesc
        ? '_id title vehicleNumber brand model fuelType ownership availability year buyPrice sellPrice buyDate saleDate imageUrl exteriorImages interiorImages liveBidEnabled liveBidStartedAt createdAt'
        : '_id title vehicleNumber brand model fuelType ownership availability year buyPrice sellPrice buyDate saleDate description imageUrl exteriorImages interiorImages liveBidEnabled liveBidStartedAt createdAt'
      : omitDesc
        ? '_id title vehicleNumber brand model fuelType ownership availability year sellPrice saleDate imageUrl liveBidEnabled liveBidStartedAt createdAt'
        : '_id title vehicleNumber brand model fuelType ownership availability year sellPrice saleDate description imageUrl liveBidEnabled liveBidStartedAt createdAt';

    const [cars, summary] = await Promise.all([
      Car.find(q)
        .select(selectFields)
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean(),
      omitSummary
        ? Promise.resolve(null)
        : getSummary(),
    ]);

    const resolvedSummary = summary ?? {
      total: cars.length,
      stock: cars.filter((c) => c.availability === 'stock').length,
      outstock: cars.filter((c) => c.availability === 'outstock').length,
    };
    res.set(
      'Cache-Control',
      admin
        ? 'private, no-store'
        : omitDesc
          ? 'public, max-age=15, stale-while-revalidate=30'
          : 'public, max-age=10'
    );
    return res.json({
      cars: cars.map((c) => toClientCar(c, admin)),
      summary: resolvedSummary,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'List cars failed' });
  }
}

async function getCar(req, res) {
  try {
    const car = await Car.findById(req.params.id).lean();
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }
    return res.json({ car: toClientCar(car, isAdminReq(req)) });
  } catch (_err) {
    return res.status(400).json({ error: 'Invalid car id' });
  }
}

async function updateCar(req, res, cloudinary) {
  try {
    const car = await Car.findById(req.params.id);
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }

    const parsed = parseCreatePayload({ ...car.toObject(), ...req.body });
    const wasLiveBidEnabled = car.liveBidEnabled === true;
    applyLiveBidTiming(parsed, car);

    const preValidate = validatePayload(parsed, { requireImage: false });
    if (preValidate) {
      return res.status(400).json({ error: preValidate });
    }

    const mainFile = getMainUploadFile(req);
    if (mainFile) {
      if (!cloudinary) {
        return res.status(503).json({
          error: 'Cloudinary is not configured. Set CLOUDINARY_* in .env',
        });
      }
      const uploaded = await uploadImageBufferStream(
        cloudinary,
        mainFile.buffer,
        'yourdreamcar/cars'
      );
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

    const keepExterior = parseJsonUrlList(req.body, 'exteriorImagesJson');
    const keepInterior = parseJsonUrlList(req.body, 'interiorImagesJson');
    const newExterior = await uploadMany(
      cloudinary,
      getUploadFiles(req, 'exteriorImages'),
      'yourdreamcar/cars/exterior'
    );
    const newInterior = await uploadMany(
      cloudinary,
      getUploadFiles(req, 'interiorImages'),
      'yourdreamcar/cars/interior'
    );

    if (keepExterior !== null) {
      await destroyImages(cloudinary, removedImages(car.exteriorImages, keepExterior));
      parsed.exteriorImages = mergeImageLists(car.exteriorImages, keepExterior, newExterior);
    } else {
      parsed.exteriorImages = [...(car.exteriorImages || []), ...newExterior];
    }

    if (keepInterior !== null) {
      await destroyImages(cloudinary, removedImages(car.interiorImages, keepInterior));
      parsed.interiorImages = mergeImageLists(car.interiorImages, keepInterior, newInterior);
    } else {
      parsed.interiorImages = [...(car.interiorImages || []), ...newInterior];
    }

    const validationError = validatePayload(parsed, { requireImage: true });
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    Object.assign(car, parsed);
    await car.save();
    invalidateSummaryCache();
    if (!wasLiveBidEnabled && car.liveBidEnabled) {
      notifyLiveBidStarted(car).catch((err) => {
        console.error('[notify] live_bid failed:', err.message);
      });
    }
    return res.json({ car: toClientCar(car, true) });
  } catch (err) {
    const { status, message } = formatCarSaveError(err);
    return res.status(status).json({ error: message });
  }
}

async function deleteCar(req, res, cloudinary) {
  try {
    const car = await Car.findById(req.params.id);
    if (!car) {
      return res.status(404).json({ error: 'Car not found' });
    }
    if (cloudinary) {
      if (car.imagePublicId) {
        try {
          await cloudinary.uploader.destroy(car.imagePublicId);
        } catch (_e) {}
      }
      await destroyImages(cloudinary, car.exteriorImages);
      await destroyImages(cloudinary, car.interiorImages);
    }
    await car.deleteOne();
    invalidateSummaryCache();
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Delete car failed' });
  }
}

module.exports = {
  createCar,
  listCars,
  getCar,
  updateCar,
  deleteCar,
  invalidateSummaryCache,
};
