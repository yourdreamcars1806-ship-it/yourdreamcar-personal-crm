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

const carUpload = upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'exteriorImages', maxCount: 15 },
  { name: 'interiorImages', maxCount: 15 },
]);

function createCarRouter(cloudinary) {
  const router = express.Router();

  router.get('/', optionalAuth, listCars);
  router.get('/:id', optionalAuth, getCar);
  router.post('/', requireAuth, requireAdmin, carUpload, (req, res) =>
    createCar(req, res, cloudinary)
  );
  router.put('/:id', requireAuth, requireAdmin, carUpload, (req, res) =>
    updateCar(req, res, cloudinary)
  );
  router.delete('/:id', requireAuth, requireAdmin, (req, res) =>
    deleteCar(req, res, cloudinary)
  );

  return router;
}

module.exports = { createCarRouter };
