const express = require('express');
const { upload } = require('../middleware/upload');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const { createListingRequestController } = require('../controllers/listingRequest.controller');

function createListingRequestRouter(cloudinary) {
  const router = express.Router();
  const ctrl = createListingRequestController(cloudinary);

  router.use(requireAuth);
  router.get('/', ctrl.listMine);
  router.post('/', upload.single('image'), ctrl.createRequest);
  router.get('/admin', requireAdmin, ctrl.listAll);
  router.patch('/:id', requireAdmin, ctrl.review);

  return router;
}

module.exports = { createListingRequestRouter };
