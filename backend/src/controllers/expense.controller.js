const Expense = require('../models/Expense');
const mongoose = require('mongoose');
const MAX_EXPENSE_LIMIT = 1000;
const DEFAULT_EXPENSE_LIMIT = Math.max(
  1,
  Math.min(MAX_EXPENSE_LIMIT, Number(process.env.EXPENSES_LIST_LIMIT) || 300)
);

async function listExpenses(req, res) {
  try {
    const requestedLimit = Number(req.query.limit);
    const limit = Number.isFinite(requestedLimit)
      ? Math.max(1, Math.min(MAX_EXPENSE_LIMIT, Math.floor(requestedLimit)))
      : DEFAULT_EXPENSE_LIMIT;
    const carIdRaw = String(req.query.carId || '').trim();
    if (carIdRaw && !mongoose.isValidObjectId(carIdRaw)) {
      return res.status(400).json({ error: 'carId is invalid' });
    }
    const filter = { user: req.userId };
    if (carIdRaw) {
      filter.carId = carIdRaw;
    }
    const items = await Expense.find(filter)
      .select('_id title amount createdAt carId carLabel')
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    res.set('Cache-Control', 'private, max-age=10');
    return res.json({
      expenses: items.map((e) => ({
        id: String(e._id),
        title: e.title,
        amount: e.amount,
        createdAt: e.createdAt,
        carId: e.carId ? String(e.carId) : null,
        carLabel: e.carLabel || null,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'List expenses failed' });
  }
}

async function createExpense(req, res) {
  try {
    const title = String(req.body?.title || '').trim();
    const amount = Number(req.body?.amount);
    const carIdRaw = String(req.body?.carId || '').trim();
    const carLabel = String(req.body?.carLabel || '').trim();
    if (!title) {
      return res.status(400).json({ error: 'title is required' });
    }
    if (Number.isNaN(amount) || amount <= 0) {
      return res.status(400).json({ error: 'amount must be a positive number' });
    }
    if (carIdRaw && !mongoose.isValidObjectId(carIdRaw)) {
      return res.status(400).json({ error: 'carId is invalid' });
    }
    const doc = await Expense.create({
      user: req.userId,
      title,
      amount,
      carId: carIdRaw || undefined,
      carLabel: carLabel || undefined,
    });
    return res.status(201).json({
      expense: {
        id: String(doc._id),
        title: doc.title,
        amount: doc.amount,
        createdAt: doc.createdAt,
        carId: doc.carId ? String(doc.carId) : null,
        carLabel: doc.carLabel || null,
      },
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Create expense failed' });
  }
}

async function updateExpense(req, res) {
  try {
    const title = String(req.body?.title || '').trim();
    const amount = Number(req.body?.amount);
    if (!title) {
      return res.status(400).json({ error: 'title is required' });
    }
    if (Number.isNaN(amount) || amount <= 0) {
      return res.status(400).json({ error: 'amount must be a positive number' });
    }

    const updated = await Expense.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      { title, amount },
      { new: true, runValidators: true }
    );
    if (!updated) {
      return res.status(404).json({ error: 'Expense not found' });
    }
    return res.json({
      expense: {
        id: String(updated._id),
        title: updated.title,
        amount: updated.amount,
        createdAt: updated.createdAt,
        carId: updated.carId ? String(updated.carId) : null,
        carLabel: updated.carLabel || null,
      },
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Update expense failed' });
  }
}

async function deleteExpense(req, res) {
  try {
    const result = await Expense.findOneAndDelete({
      _id: req.params.id,
      user: req.userId,
    });
    if (!result) {
      return res.status(404).json({ error: 'Expense not found' });
    }
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Delete expense failed' });
  }
}

module.exports = { listExpenses, createExpense, updateExpense, deleteExpense };
