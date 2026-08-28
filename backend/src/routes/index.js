const authRoutes = require('./auth.routes');
const expenseRoutes = require('./expense.routes');
const { createUploadRouter } = require('./upload.routes');
const { createCarRouter } = require('./car.routes');
const { createListingRequestRouter } = require('./listingRequest.routes');
const notificationRoutes = require('./notification.routes');
const bidRoutes = require('./bid.routes');
const deliveryNoteRoutes = require('./deliveryNote.routes');

function registerRoutes(app, cloudinary) {
  app.get('/api/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'yourdreamcar-backend',
      env: process.env.NODE_ENV || 'development',
      uptime: Math.floor(process.uptime()),
    });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/expenses', expenseRoutes);
  app.use('/api/upload', createUploadRouter(cloudinary));
  app.use('/api/cars', createCarRouter(cloudinary));
  app.use('/api/listing-requests', createListingRequestRouter(cloudinary));
  app.use('/api/notifications', notificationRoutes);
  app.use('/api/bids', bidRoutes);
  app.use('/api/delivery-notes', deliveryNoteRoutes);
}

module.exports = { registerRoutes };
