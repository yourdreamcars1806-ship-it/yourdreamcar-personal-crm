/**
 * Default dev login (created if missing):
 *   Email:    gafru@yourdreamcar.app
 *   Password: DreamCar2026!
 *
 * Override with SEED_USER_EMAIL / SEED_USER_PASSWORD in .env
 */
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');

const DEFAULT_EMAIL = 'gafru@yourdreamcar.app';
const DEFAULT_PASSWORD = 'DreamCar2026!';

async function seedUser() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.warn('[seed] MONGODB_URI missing, skip seed');
    return;
  }

  await mongoose.connect(uri);

  const email = (process.env.SEED_USER_EMAIL || DEFAULT_EMAIL)
    .trim()
    .toLowerCase();
  const password = process.env.SEED_USER_PASSWORD || DEFAULT_PASSWORD;

  const existing = await User.findOne({ email });
  if (existing) {
    console.log('[seed] User already exists:', email);
    await mongoose.disconnect();
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.create({ email, passwordHash });
  console.log('[seed] Created user:', email);
  console.log('[seed] Password:', password === DEFAULT_PASSWORD ? '(default)' : '(from env)');

  await mongoose.disconnect();
}

seedUser().catch((err) => {
  console.error('[seed]', err);
  process.exit(1);
});
