/**
 * Stream uploads — avoids duplicating large buffers as base64 on small Railway RAM.
 * @param {import('cloudinary').v2} cloudinary
 * @param {Buffer} buffer
 * @param {string} folder Cloudinary folder path
 */
function uploadImageBufferStream(cloudinary, buffer, folder) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        use_filename: false,
      },
      (err, result) => {
        if (err) reject(err);
        else resolve(result);
      }
    );
    stream.end(buffer);
  });
}

module.exports = { uploadImageBufferStream };
