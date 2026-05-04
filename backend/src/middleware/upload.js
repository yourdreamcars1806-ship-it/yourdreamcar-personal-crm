const multer = require('multer');

const IMAGE_EXT = /\.(jpe?g|png|gif|webp|bmp|heic|heif|avif)$/i;

/** Single image in memory (one file field: "image") */
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const name = (file.originalname || '').toLowerCase();

    // Some clients send application/octet-stream or empty mimetype for gallery picks.
    const okMime = mime.startsWith('image/');
    const okExt = IMAGE_EXT.test(name);

    if (okMime || okExt) {
      cb(null, true);
      return;
    }
    cb(new Error('Only image files are allowed'));
  },
});

module.exports = { upload };
