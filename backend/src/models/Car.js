const mongoose = require('mongoose');

const fuelTypes = ['CNG', 'PETROL', 'DIESEL'];
const ownershipTypes = [
  '1st owner',
  '2nd owner',
  '3rd owner',
  '4th owner',
  '5th owner',
  'multiple owner',
];
const availabilityTypes = ['stock', 'outstock'];

const carSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    vehicleNumber: { type: String, default: '', trim: true },
    brand: { type: String, required: true, trim: true },
    model: { type: String, required: true, trim: true },
    fuelType: { type: String, enum: fuelTypes, required: true },
    ownership: { type: String, enum: ownershipTypes, required: true },
    availability: { type: String, enum: availabilityTypes, required: true },
    year: { type: Number, required: true, min: 1980, max: 2100 },
    buyPrice: { type: Number, required: true, min: 0 },
    sellPrice: { type: Number, required: true, min: 0 },
    buyDate: { type: Date, required: true },
    saleDate: { type: Date },
    description: { type: String, default: '', trim: true },
    imageUrl: { type: String, required: true },
    imagePublicId: { type: String, required: true },
  },
  { timestamps: true }
);

carSchema.index({ availability: 1, createdAt: -1 });
carSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Car', carSchema);
