const ListingRequest = require('../models/ListingRequest');
const Car = require('../models/Car');
const { uploadImageBufferStream } = require('../utils/cloudinaryImageUpload');
const { notifyCarAdded } = require('./notification.controller');
const { invalidateSummaryCache } = require('./car.controller');

const ownershipTypes = [
  '1st owner',
  '2nd owner',
  '3rd owner',
  '4th owner',
  '5th owner',
  'multiple owner',
];

function toDto(doc) {
  const user =
    doc.userId && typeof doc.userId === 'object' && doc.userId.email
      ? doc.userId
      : null;
  return {
    id: String(doc._id),
    title: doc.title || '',
    vehicleNumber: doc.vehicleNumber || '',
    brand: doc.brand,
    model: doc.model,
    year: doc.year,
    fuelType: doc.fuelType,
    ownership: doc.ownership || '1st owner',
    kmDriven: doc.kmDriven,
    expectedPrice: doc.expectedPrice,
    sellPrice: doc.expectedPrice,
    city: doc.city,
    phone: doc.phone,
    description: doc.description || '',
    imageUrl: doc.imageUrl || '',
    status: doc.status,
    publishedCarId: doc.publishedCarId ? String(doc.publishedCarId) : '',
    userName: user?.name || '',
    userEmail: user?.email || '',
    createdAt: doc.createdAt,
  };
}

async function maybeUploadImage(cloudinary, file) {
  if (!file?.buffer) {
    return { imageUrl: '', imagePublicId: '' };
  }
  if (!cloudinary) {
    throw new Error('Image upload is not configured');
  }
  const result = await uploadImageBufferStream(
    cloudinary,
    file.buffer,
    'yourdreamcar/listing-requests'
  );
  return {
    imageUrl: result.secure_url || result.url || '',
    imagePublicId: result.public_id || '',
  };
}

function parseBody(req) {
  const brand = String(req.body?.brand || '').trim();
  const model = String(req.body?.model || '').trim();
  const city = String(req.body?.city || '').trim();
  const phone = String(req.body?.phone || '').trim();
  const description = String(req.body?.description || '').trim();
  const title = String(req.body?.title || '').trim();
  const vehicleNumber = String(req.body?.vehicleNumber || '').trim();
  const fuelType = String(req.body?.fuelType || '')
    .trim()
    .toUpperCase();
  const ownership = String(req.body?.ownership || '1st owner').trim();
  const year = Number(req.body?.year);
  const kmDriven = Number(req.body?.kmDriven);
  const expectedPrice = Number(
    req.body?.sellPrice ?? req.body?.expectedPrice
  );

  if (!brand || !model || !city || !phone) {
    return { error: 'Brand, model, city and phone are required' };
  }
  if (!['CNG', 'PETROL', 'DIESEL'].includes(fuelType)) {
    return { error: 'Fuel type must be CNG, PETROL or DIESEL' };
  }
  if (!ownershipTypes.includes(ownership)) {
    return { error: 'Enter a valid ownership' };
  }
  if (!Number.isFinite(year) || year < 1980 || year > 2100) {
    return { error: 'Enter a valid year' };
  }
  if (!Number.isFinite(kmDriven) || kmDriven < 0) {
    return { error: 'Enter valid kilometers' };
  }
  if (!Number.isFinite(expectedPrice) || expectedPrice <= 0) {
    return { error: 'Enter a valid sell price' };
  }

  return {
    data: {
      title: title || `${brand} ${model}`.trim(),
      vehicleNumber,
      brand,
      model,
      city,
      phone,
      description,
      fuelType,
      ownership,
      year,
      kmDriven,
      expectedPrice,
    },
  };
}

function createListingRequestController(cloudinary) {
  async function createRequest(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'Car photo is required' });
      }
      const parsed = parseBody(req);
      if (parsed.error) {
        return res.status(400).json({ error: parsed.error });
      }
      const images = await maybeUploadImage(cloudinary, req.file);
      const doc = await ListingRequest.create({
        userId: req.userId,
        ...parsed.data,
        ...images,
      });
      return res.status(201).json({ request: toDto(doc) });
    } catch (err) {
      return res
        .status(500)
        .json({ error: err.message || 'Failed to submit listing request' });
    }
  }

  async function listMine(req, res) {
    try {
      const docs = await ListingRequest.find({ userId: req.userId })
        .sort({ createdAt: -1 })
        .limit(100)
        .lean();
      return res.json({ requests: docs.map(toDto) });
    } catch (err) {
      return res
        .status(500)
        .json({ error: err.message || 'Failed to load listing requests' });
    }
  }

  async function listAll(req, res) {
    try {
      const docs = await ListingRequest.find({})
        .populate('userId', 'email name')
        .sort({ createdAt: -1 })
        .limit(300)
        .lean();
      return res.json({ requests: docs.map(toDto) });
    } catch (err) {
      return res
        .status(500)
        .json({ error: err.message || 'Failed to load listing requests' });
    }
  }

  async function review(req, res) {
    try {
      const doc = await ListingRequest.findById(req.params.id);
      if (!doc) {
        return res.status(404).json({ error: 'Request not found' });
      }

      const action = String(req.body?.action || '').trim().toLowerCase();
      if (action === 'reject') {
        doc.status = 'rejected';
        await doc.save();
        return res.json({ request: toDto(doc) });
      }
      if (action !== 'publish') {
        return res.status(400).json({ error: 'action must be publish or reject' });
      }
      if (doc.status === 'approved' && doc.publishedCarId) {
        return res.status(400).json({ error: 'This request is already published' });
      }
      if (!doc.imageUrl) {
        return res
          .status(400)
          .json({ error: 'This request has no photo. Ask the user to resubmit.' });
      }

      const brand = String(req.body?.brand || doc.brand).trim();
      const model = String(req.body?.model || doc.model).trim();
      const title = String(req.body?.title || doc.title || `${brand} ${model}`).trim();
      const vehicleNumber = String(
        req.body?.vehicleNumber || doc.vehicleNumber || ''
      ).trim();
      const fuelType = String(req.body?.fuelType || doc.fuelType)
        .trim()
        .toUpperCase();
      const ownership = String(req.body?.ownership || doc.ownership || '1st owner').trim();
      const year = Number(req.body?.year ?? doc.year);
      const sellPrice = Number(req.body?.sellPrice ?? doc.expectedPrice);
      const buyPrice = Number(req.body?.buyPrice);
      const description = String(
        req.body?.description ?? doc.description ?? ''
      ).trim();
      const availability = String(req.body?.availability || 'stock')
        .trim()
        .toLowerCase();
      const buyDate = req.body?.buyDate
        ? new Date(req.body.buyDate)
        : new Date();

      if (!brand || !model || !title) {
        return res.status(400).json({ error: 'Title, brand and model are required' });
      }
      if (!['CNG', 'PETROL', 'DIESEL'].includes(fuelType)) {
        return res.status(400).json({ error: 'Invalid fuel type' });
      }
      if (!ownershipTypes.includes(ownership)) {
        return res.status(400).json({ error: 'Invalid ownership' });
      }
      if (!Number.isFinite(year) || year < 1980 || year > 2100) {
        return res.status(400).json({ error: 'Invalid year' });
      }
      if (!Number.isFinite(sellPrice) || sellPrice < 0) {
        return res.status(400).json({ error: 'Enter a valid sell price' });
      }
      if (!Number.isFinite(buyPrice) || buyPrice < 0) {
        return res.status(400).json({ error: 'Enter a valid buy price' });
      }
      if (!(buyDate instanceof Date) || Number.isNaN(buyDate.getTime())) {
        return res.status(400).json({ error: 'Enter a valid buy date' });
      }

      const car = await Car.create({
        title,
        vehicleNumber,
        brand,
        model,
        fuelType,
        ownership,
        availability: availability === 'outstock' ? 'outstock' : 'stock',
        year,
        buyPrice,
        sellPrice,
        buyDate,
        description,
        imageUrl: doc.imageUrl,
        imagePublicId: doc.imagePublicId || `listing/${doc._id}`,
      });

      doc.brand = brand;
      doc.model = model;
      doc.title = title;
      doc.vehicleNumber = vehicleNumber;
      doc.fuelType = fuelType;
      doc.ownership = ownership;
      doc.year = year;
      doc.expectedPrice = sellPrice;
      doc.description = description;
      doc.status = 'approved';
      doc.publishedCarId = car._id;
      await doc.save();

      invalidateSummaryCache();
      notifyCarAdded(car).catch((err) => {
        console.error('[notify] listing publish failed:', err.message);
      });

      return res.json({ request: toDto(doc), car });
    } catch (err) {
      return res
        .status(500)
        .json({ error: err.message || 'Failed to review listing request' });
    }
  }

  return { createRequest, listMine, listAll, review };
}

module.exports = { createListingRequestController };
