const express = require('express');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const {
  createNote,
  listMine,
  listAll,
  getOne,
  updateNote,
  deleteNote,
  downloadPdf,
} = require('../controllers/deliveryNote.controller');

const router = express.Router();
router.use(requireAuth);

router.get('/admin', requireAdmin, listAll);
router.get('/mine', listMine);
router.get('/:id/pdf', requireAdmin, downloadPdf);
router.get('/:id', getOne);
router.post('/', createNote);
router.put('/:id', requireAdmin, updateNote);
router.delete('/:id', requireAdmin, deleteNote);

module.exports = router;
