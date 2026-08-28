const DeliveryNote = require('../models/DeliveryNote');
const User = require('../models/User');
const { buildDeliveryNotePdf } = require('../services/deliveryNotePdf');

function toDto(doc, extra = {}) {
  return {
    id: String(doc._id),
    deliveryNoteNo: doc.deliveryNoteNo || '',
    deliveryDate: doc.deliveryDate || null,
    deliveryTime: doc.deliveryTime || '',
    customerName: doc.customerName || '',
    customerAddress: doc.customerAddress || '',
    customerMobile: doc.customerMobile || '',
    idProofType: doc.idProofType || '',
    idProofNo: doc.idProofNo || '',
    vehicleBrand: doc.vehicleBrand || '',
    vehicleModel: doc.vehicleModel || '',
    registrationNo: doc.registrationNo || '',
    yearOfManufacture: doc.yearOfManufacture ?? null,
    colour: doc.colour || '',
    fuelType: doc.fuelType || '',
    chassisNo: doc.chassisNo || '',
    engineNo: doc.engineNo || '',
    odometerKm: doc.odometerKm ?? null,
    totalPrice: doc.totalPrice ?? null,
    amountReceived: doc.amountReceived ?? null,
    balanceAmount: doc.balanceAmount ?? null,
    paymentMode: doc.paymentMode || '',
    documentsHandedOver: doc.documentsHandedOver || '',
    declarationCustomerName: doc.declarationCustomerName || '',
    customerSignatureName: doc.customerSignatureName || '',
    signedAt: doc.signedAt || null,
    authorizedSignatoryName: doc.authorizedSignatoryName || '',
    vehicleHandedOverBy: doc.vehicleHandedOverBy || '',
    userId: doc.userId ? String(doc.userId) : '',
    carId: doc.carId ? String(doc.carId) : '',
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
    ...extra,
  };
}

function parseBody(body) {
  const num = (v) => {
    if (v === '' || v == null) return null;
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  };
  const date = (v) => {
    if (!v) return null;
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d;
  };
  const str = (v) => String(v ?? '').trim();

  const paymentModes = ['Cash', 'UPI', 'Bank Transfer', 'Finance', 'Other', ''];
  const paymentMode = str(body.paymentMode);
  const normalizedPayment = paymentModes.includes(paymentMode) ? paymentMode : '';

  return {
    deliveryNoteNo: str(body.deliveryNoteNo),
    deliveryDate: date(body.deliveryDate),
    deliveryTime: str(body.deliveryTime),
    customerName: str(body.customerName),
    customerAddress: str(body.customerAddress),
    customerMobile: str(body.customerMobile),
    idProofType: str(body.idProofType),
    idProofNo: str(body.idProofNo),
    vehicleBrand: str(body.vehicleBrand),
    vehicleModel: str(body.vehicleModel),
    registrationNo: str(body.registrationNo),
    yearOfManufacture: num(body.yearOfManufacture),
    colour: str(body.colour),
    fuelType: str(body.fuelType),
    chassisNo: str(body.chassisNo),
    engineNo: str(body.engineNo),
    odometerKm: num(body.odometerKm),
    totalPrice: num(body.totalPrice),
    amountReceived: num(body.amountReceived),
    balanceAmount: num(body.balanceAmount),
    paymentMode: normalizedPayment,
    documentsHandedOver: str(body.documentsHandedOver),
    declarationCustomerName: str(body.declarationCustomerName),
    customerSignatureName: str(body.customerSignatureName),
    signedAt: date(body.signedAt),
    authorizedSignatoryName: str(body.authorizedSignatoryName),
    vehicleHandedOverBy: str(body.vehicleHandedOverBy),
    carId: str(body.carId) || undefined,
  };
}

async function nextNoteNo() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const prefix = `DN-${y}${m}${d}-`;
  const latest = await DeliveryNote.findOne({
    deliveryNoteNo: new RegExp(`^${prefix}`),
  })
    .sort({ createdAt: -1 })
    .lean();
  let seq = 1;
  if (latest?.deliveryNoteNo) {
    const part = latest.deliveryNoteNo.slice(prefix.length);
    const n = parseInt(part, 10);
    if (Number.isFinite(n)) seq = n + 1;
  }
  return `${prefix}${String(seq).padStart(4, '0')}`;
}

async function createNote(req, res) {
  try {
    const data = parseBody(req.body || {});
    if (!data.customerName) {
      return res.status(400).json({ error: 'Customer name is required' });
    }
    if (!data.deliveryNoteNo) {
      data.deliveryNoteNo = await nextNoteNo();
    }
    if (!data.deliveryDate) {
      data.deliveryDate = new Date();
    }
    if (!data.declarationCustomerName) {
      data.declarationCustomerName = data.customerName;
    }
    if (!data.customerSignatureName) {
      data.customerSignatureName = data.customerName;
    }
    if (!data.signedAt) {
      data.signedAt = new Date();
    }
    if (data.totalPrice != null && data.amountReceived != null && data.balanceAmount == null) {
      data.balanceAmount = Math.max(0, data.totalPrice - data.amountReceived);
    }

    const doc = await DeliveryNote.create({
      ...data,
      userId: req.userId,
    });
    return res.status(201).json({ deliveryNote: toDto(doc) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to create delivery note' });
  }
}

async function listMine(req, res) {
  try {
    const docs = await DeliveryNote.find({ userId: req.userId })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();
    return res.json({ deliveryNotes: docs.map((d) => toDto(d)) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load delivery notes' });
  }
}

async function listAll(req, res) {
  try {
    const docs = await DeliveryNote.find()
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();
    const userIds = [...new Set(docs.map((d) => String(d.userId)).filter(Boolean))];
    const users = await User.find({ _id: { $in: userIds } })
      .select('email name')
      .lean();
    const userMap = Object.fromEntries(
      users.map((u) => [String(u._id), { email: u.email || '', name: u.name || '' }]),
    );
    return res.json({
      deliveryNotes: docs.map((d) =>
        toDto(d, {
          userEmail: userMap[String(d.userId)]?.email || '',
          userName: userMap[String(d.userId)]?.name || '',
        }),
      ),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load delivery notes' });
  }
}

async function getOne(req, res) {
  try {
    const doc = await DeliveryNote.findById(req.params.id).lean();
    if (!doc) {
      return res.status(404).json({ error: 'Delivery note not found' });
    }
    const isOwner = String(doc.userId) === String(req.userId);
    if (!isOwner && req.userRole !== 'admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }
    let extra = {};
    if (req.userRole === 'admin' && doc.userId) {
      const user = await User.findById(doc.userId).select('email name').lean();
      extra = { userEmail: user?.email || '', userName: user?.name || '' };
    }
    return res.json({ deliveryNote: toDto(doc, extra) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load delivery note' });
  }
}

async function updateNote(req, res) {
  try {
    const doc = await DeliveryNote.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Delivery note not found' });
    }
    const data = parseBody(req.body || {});
    if (data.totalPrice != null && data.amountReceived != null && data.balanceAmount == null) {
      data.balanceAmount = Math.max(0, data.totalPrice - data.amountReceived);
    }
    Object.assign(doc, data);
    await doc.save();
    return res.json({ deliveryNote: toDto(doc) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to update delivery note' });
  }
}

async function deleteNote(req, res) {
  try {
    const doc = await DeliveryNote.findByIdAndDelete(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: 'Delivery note not found' });
    }
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to delete delivery note' });
  }
}

async function downloadPdf(req, res) {
  try {
    const doc = await DeliveryNote.findById(req.params.id).lean();
    if (!doc) {
      return res.status(404).json({ error: 'Delivery note not found' });
    }
    const pdf = await buildDeliveryNotePdf(doc);
    const fileName = `${doc.deliveryNoteNo || 'delivery-note'}.pdf`.replace(/[^\w.-]+/g, '_');
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    return res.send(pdf);
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to generate PDF' });
  }
}

module.exports = {
  createNote,
  listMine,
  listAll,
  getOne,
  updateNote,
  deleteNote,
  downloadPdf,
};
