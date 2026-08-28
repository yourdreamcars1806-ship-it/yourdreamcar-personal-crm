const mongoose = require('mongoose');

const bidSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    carId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Car',
      required: true,
      index: true,
    },
    amount: { type: Number, required: true, min: 1 },
    name: { type: String, default: '', trim: true },
    phone: { type: String, required: true, trim: true },
    city: { type: String, default: '', trim: true },
    message: { type: String, default: '', trim: true },
    carTitle: { type: String, default: '', trim: true },
    carImageUrl: { type: String, default: '', trim: true },
    askPrice: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected'],
      default: 'pending',
    },
  },
  { timestamps: true }
);

bidSchema.index({ userId: 1, createdAt: -1 });
bidSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Bid', bidSchema);
