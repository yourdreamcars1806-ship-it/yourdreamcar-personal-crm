const express = require('express');
const { upload } = require('../middleware/upload');
const { uploadSingleImage } = require('../controllers/upload.controller');

function createUploadRouter(cloudinary) {
  const router = express.Router();

  router.post(
    '/image',
    upload.single('image'),
    (req, res) => uploadSingleImage(req, res, cloudinary)
  );

  return router;
}

module.exports = { createUploadRouter };
