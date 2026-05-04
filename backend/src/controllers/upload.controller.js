const CarImage = require('../models/CarImage');

function uploadBufferToCloudinary(cloudinary, buffer, options = {}) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: 'yourdreamcar', resource_type: 'image', ...options },
      (err, result) => {
        if (err) reject(err);
        else resolve(result);
      }
    );
    stream.end(buffer);
  });
}

async function uploadSingleImage(req, res, cloudinary) {
  try {
    if (!cloudinary) {
      return res.status(503).json({
        error: 'Image upload is not configured. Set CLOUDINARY_* in .env',
      });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'Missing file: use field name "image"' });
    }

    const result = await uploadBufferToCloudinary(cloudinary, req.file.buffer);

    const doc = await CarImage.create({
      cloudinaryPublicId: result.public_id,
      url: result.secure_url,
      originalName: req.file.originalname,
    });

    return res.status(201).json({
      message: 'Image uploaded',
      image: {
        id: doc._id,
        url: doc.url,
        publicId: doc.cloudinaryPublicId,
      },
    });
  } catch (err) {
    const message = err.message || 'Upload failed';
    return res.status(500).json({ error: message });
  }
}

module.exports = { uploadSingleImage };
