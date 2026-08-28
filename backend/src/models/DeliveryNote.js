const mongoose = require('mongoose');

const deliveryNoteSchema = new mongoose.Schema(
  {
    deliveryNoteNo: { type: String, trim: true, default: '' },
    deliveryDate: { type: Date },
    deliveryTime: { type: String, trim: true, default: '' },
    customerName: { type: String, trim: true, default: '' },
    customerAddress: { type: String, trim: true, default: '' },
    customerMobile: { type: String, trim: true, default: '' },
    idProofType: { type: String, trim: true, default: '' },
    idProofNo: { type: String, trim: true, default: '' },
    vehicleBrand: { type: String, trim: true, default: '' },
    vehicleModel: { type: String, trim: true, default: '' },
    registrationNo: { type: String, trim: true, default: '' },
    yearOfManufacture: { type: Number },
    colour: { type: String, trim: true, default: '' },
    fuelType: { type: String, trim: true, default: '' },
    chassisNo: { type: String, trim: true, default: '' },
    engineNo: { type: String, trim: true, default: '' },
    odometerKm: { type: Number },
    totalPrice: { type: Number },
    amountReceived: { type: Number },
    balanceAmount: { type: Number },
    paymentMode: {
      type: String,
      enum: ['Cash', 'UPI', 'Bank Transfer', 'Finance', 'Other', ''],
      default: '',
    },
    documentsHandedOver: { type: String, trim: true, default: '' },
    declarationCustomerName: { type: String, trim: true, default: '' },
    customerSignatureName: { type: String, trim: true, default: '' },
    signedAt: { type: Date },
    authorizedSignatoryName: { type: String, trim: true, default: '' },
    vehicleHandedOverBy: { type: String, trim: true, default: '' },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    carId: { type: mongoose.Schema.Types.ObjectId, ref: 'Car' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('DeliveryNote', deliveryNoteSchema);
