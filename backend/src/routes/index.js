const authRoutes = require('./auth.routes');
const expenseRoutes = require('./expense.routes');
const { createUploadRouter } = require('./upload.routes');
const { createCarRouter } = require('./car.routes');

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
}

module.exports = { registerRoutes };
