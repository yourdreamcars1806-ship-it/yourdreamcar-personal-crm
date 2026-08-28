const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    type: { type: String, default: 'car_added', index: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    carId: { type: mongoose.Schema.Types.ObjectId, ref: 'Car', index: true },
    carTitle: { type: String, default: '', trim: true },
    imageUrl: { type: String, default: '', trim: true },
  },
  { timestamps: true }
);

notificationSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
