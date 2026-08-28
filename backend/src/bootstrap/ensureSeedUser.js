const bcrypt = require('bcryptjs');
const User = require('../models/User');

const DEFAULT_EMAIL = 'gafru@yourdreamcar.app';
const DEFAULT_PASSWORD = 'DreamCar2026!';
const DEFAULT_APP_EMAIL = 'user@yourdreamcar.app';
const DEFAULT_APP_PASSWORD = 'User1234!';

async function ensureAdminUser() {
  const email = (process.env.SEED_USER_EMAIL || DEFAULT_EMAIL)
    .trim()
    .toLowerCase();
  const password = process.env.SEED_USER_PASSWORD || DEFAULT_PASSWORD;

  await User.updateMany(
    { $or: [{ role: { $exists: false } }, { role: null }, { role: '' }] },
    { $set: { role: 'admin' } }
  );

  const existing = await User.findOne({ email });
  if (existing) {
    if (existing.role !== 'admin') {
      existing.role = 'admin';
      await existing.save();
    }
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.create({ email, passwordHash, role: 'admin', name: 'Admin' });
  console.log('[boot] Seeded admin login user:', email);
}

async function ensureMarketplaceUser() {
  const email = (process.env.SEED_APP_USER_EMAIL || DEFAULT_APP_EMAIL)
    .trim()
    .toLowerCase();
  const password = process.env.SEED_APP_USER_PASSWORD || DEFAULT_APP_PASSWORD;

  const existing = await User.findOne({ email });
  if (existing) {
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.create({
    email,
    passwordHash,
    role: 'user',
    name: 'Demo User',
  });
  console.log('[boot] Seeded marketplace user:', email);
}

/** Ensures admin + marketplace demo user exist (does not change passwords). */
async function ensureSeedUser() {
  await ensureAdminUser();
  await ensureMarketplaceUser();
}

module.exports = { ensureSeedUser };
