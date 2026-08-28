const mongoose = require('mongoose');

const listingRequestSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, default: '', trim: true },
    vehicleNumber: { type: String, default: '', trim: true },
    brand: { type: String, required: true, trim: true },
    model: { type: String, required: true, trim: true },
    ownership: {
      type: String,
      enum: [
        '1st owner',
        '2nd owner',
        '3rd owner',
        '4th owner',
        '5th owner',
        'multiple owner',
      ],
      default: '1st owner',
    },
    year: { type: Number, required: true, min: 1980, max: 2100 },
    fuelType: {
      type: String,
      enum: ['CNG', 'PETROL', 'DIESEL'],
      required: true,
    },
    kmDriven: { type: Number, required: true, min: 0 },
    expectedPrice: { type: Number, required: true, min: 0 },
    city: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    imageUrl: { type: String, default: '' },
    imagePublicId: { type: String, default: '' },
    publishedCarId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Car',
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
  },
  { timestamps: true }
);

listingRequestSchema.index({ userId: 1, createdAt: -1 });
listingRequestSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('ListingRequest', listingRequestSchema);
