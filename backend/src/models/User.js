const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    name: { type: String, default: '', trim: true },
    role: {
      type: String,
      enum: ['admin', 'user'],
      default: 'admin',
    },
    resetOtpHash: { type: String, default: '' },
    resetOtpExpiresAt: { type: Date },
    lastActiveAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
