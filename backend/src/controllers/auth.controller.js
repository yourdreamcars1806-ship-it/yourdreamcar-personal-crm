const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function getJwtSecret() {
  const s = process.env.JWT_SECRET;
  if (!s) {
    throw new Error('JWT_SECRET is not set');
  }
  return s;
}

function roleOf(user) {
  return user.role === 'user' ? 'user' : 'admin';
}

function publicUser(user) {
  return {
    id: String(user._id),
    email: user.email,
    name: user.name || '',
    role: roleOf(user),
  };
}

function signToken(user) {
  return jwt.sign(
    { sub: String(user._id), email: user.email, role: roleOf(user) },
    getJwtSecret(),
    { expiresIn: '7d' }
  );
}

async function login(req, res) {
  try {
    const email = String(req.body?.email || '')
      .trim()
      .toLowerCase();
    const password = String(req.body?.password || '');

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (!user.role) {
      user.role = 'admin';
    }
    user.lastActiveAt = new Date();
    await user.save();

    return res.json({
      token: signToken(user),
      user: publicUser(user),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Login failed' });
  }
}

async function register(req, res) {
  try {
    const email = String(req.body?.email || '')
      .trim()
      .toLowerCase();
    const password = String(req.body?.password || '');
    const name = String(req.body?.name || '').trim();

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (password.length < 6) {
      return res
        .status(400)
        .json({ error: 'Password must be at least 6 characters' });
    }

    const exists = await User.findOne({ email });
    if (exists) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      email,
      passwordHash,
      name,
      role: 'user',
      lastActiveAt: new Date(),
    });

    return res.status(201).json({
      token: signToken(user),
      user: publicUser(user),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Sign up failed' });
  }
}

async function me(req, res) {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    user.lastActiveAt = new Date();
    await user.save();
    return res.json({ user: publicUser(user) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load profile' });
  }
}

async function adminStats(req, res) {
  try {
    const activeWindowMinutes = 15;
    const activeSince = new Date(Date.now() - activeWindowMinutes * 60 * 1000);
    const [totalUsers, activeUsers] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      User.countDocuments({ role: 'user', lastActiveAt: { $gte: activeSince } }),
    ]);
    return res.json({
      totalUsers,
      activeUsers,
      activeWindowMinutes,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to load stats' });
  }
}

async function changePassword(req, res) {
  try {
    const currentPassword = String(req.body?.currentPassword || '');
    const newPassword = String(req.body?.newPassword || '');

    if (!currentPassword || !newPassword) {
      return res
        .status(400)
        .json({ error: 'Current password and new password are required' });
    }
    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ error: 'New password must be at least 6 characters' });
    }

    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const ok = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    return res.json({ ok: true });
  } catch (err) {
    return res
      .status(500)
      .json({ error: err.message || 'Failed to update password' });
  }
}

module.exports = {
  login,
  register,
  me,
  changePassword,
  adminStats,
};
