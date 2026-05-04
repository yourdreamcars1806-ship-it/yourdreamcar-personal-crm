const mongoose = require('mongoose');

const carImageSchema = new mongoose.Schema(
  {
    cloudinaryPublicId: { type: String, required: true },
    url: { type: String, required: true },
    originalName: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('CarImage', carImageSchema);
