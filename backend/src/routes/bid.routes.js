const express = require('express');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const {
  createBid,
  listMine,
  listAll,
  updateBid,
  updateMyBid,
  deleteBid,
} = require('../controllers/bid.controller');

const router = express.Router();
router.use(requireAuth);
router.get('/', listMine);
router.post('/', createBid);
router.get('/admin', requireAdmin, listAll);
router.patch('/mine/:id', updateMyBid);
router.patch('/:id', requireAdmin, updateBid);
router.delete('/:id', requireAdmin, deleteBid);

module.exports = router;
