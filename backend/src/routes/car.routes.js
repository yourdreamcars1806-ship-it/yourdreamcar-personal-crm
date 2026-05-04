const express = require('express');
const { upload } = require('../middleware/upload');
const {
  createCar,
  listCars,
  updateCar,
  deleteCar,
} = require('../controllers/car.controller');

function createCarRouter(cloudinary) {
  const router = express.Router();

  router.get('/', listCars);
  router.post('/', upload.single('image'), (req, res) => createCar(req, res, cloudinary));
  router.put('/:id', upload.single('image'), (req, res) =>
    updateCar(req, res, cloudinary)
  );
  router.delete('/:id', (req, res) => deleteCar(req, res, cloudinary));

  return router;
}

module.exports = { createCarRouter };
