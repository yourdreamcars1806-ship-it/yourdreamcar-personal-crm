const express = require('express');
const { upload } = require('../middleware/upload');
const { requireAuth, requireAdmin, optionalAuth } = require('../middleware/auth');
const {
  createCar,
  listCars,
  getCar,
  updateCar,
  deleteCar,
} = require('../controllers/car.controller');

function createCarRouter(cloudinary) {
  const router = express.Router();

  router.get('/', optionalAuth, listCars);
  router.get('/:id', optionalAuth, getCar);
  router.post('/', requireAuth, requireAdmin, upload.single('image'), (req, res) =>
    createCar(req, res, cloudinary)
  );
  router.put(
    '/:id',
    requireAuth,
    requireAdmin,
    upload.single('image'),
    (req, res) => updateCar(req, res, cloudinary)
  );
  router.delete('/:id', requireAuth, requireAdmin, (req, res) =>
    deleteCar(req, res, cloudinary)
  );

  return router;
}

module.exports = { createCarRouter };
