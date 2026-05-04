const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    amount: { type: Number, required: true, min: 0 },
    carId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Car',
      required: false,
      index: true,
    },
    carLabel: { type: String, required: false, trim: true },
  },
  { timestamps: true }
);

expenseSchema.index({ user: 1, createdAt: -1 });
expenseSchema.index({ user: 1, carId: 1, createdAt: -1 });

module.exports = mongoose.model('Expense', expenseSchema);
