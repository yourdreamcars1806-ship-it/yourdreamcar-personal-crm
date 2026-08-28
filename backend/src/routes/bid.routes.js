const express = require('express');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const {
  createBid,
  listMine,
  listAll,
  updateStatus,
} = require('../controllers/bid.controller');

const router = express.Router();
router.use(requireAuth);
router.get('/', listMine);
router.post('/', createBid);
router.get('/admin', requireAdmin, listAll);
router.patch('/:id', requireAdmin, updateStatus);

module.exports = router;
