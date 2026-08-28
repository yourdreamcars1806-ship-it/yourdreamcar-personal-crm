const express = require('express');
const {
  login,
  register,
  me,
  changePassword,
  adminStats,
} = require('../controllers/auth.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.get('/me', requireAuth, me);
router.get('/admin/stats', requireAuth, requireAdmin, adminStats);
router.post('/change-password', requireAuth, changePassword);

module.exports = router;
