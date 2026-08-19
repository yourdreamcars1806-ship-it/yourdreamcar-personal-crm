const bcrypt = require('bcryptjs');
const User = require('../models/User');

const DEFAULT_EMAIL = 'gafru@yourdreamcar.app';
const DEFAULT_PASSWORD = 'DreamCar2026!';

/** Ensures one dev user exists (same defaults as seed script). */
async function ensureSeedUser() {
  const email = (process.env.SEED_USER_EMAIL || DEFAULT_EMAIL)
    .trim()
    .toLowerCase();
  const password = process.env.SEED_USER_PASSWORD || DEFAULT_PASSWORD;

  const existing = await User.findOne({ email });
  if (existing) {
    const ok = await bcrypt.compare(password, existing.passwordHash);
    if (!ok) {
      existing.passwordHash = await bcrypt.hash(password, 10);
      await existing.save();
      console.log('[boot] Updated login password for:', email);
    }
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.create({ email, passwordHash });
  console.log('[boot] Seeded login user:', email);
}

module.exports = { ensureSeedUser };
