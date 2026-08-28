const express = require('express');
const cors = require('cors');
const compression = require('compression');
const { registerRoutes } = require('./routes');

function createApp(cloudinary) {
  const app = express();

  const corsOrigin = process.env.CORS_ORIGIN?.trim() || '*';

  app.set('trust proxy', 1);
  app.disable('x-powered-by');
  app.use(
    compression({
      filter: (req, res) => {
        if (req.headers.accept && req.headers.accept.includes('text/event-stream')) {
          return false;
        }
        return compression.filter(req, res);
      },
    })
  );
  app.use(cors({ origin: corsOrigin === '*' ? true : corsOrigin }));
  app.use(express.json({ limit: '1mb' }));

  registerRoutes(app, cloudinary);

  app.use((err, _req, res, _next) => {
    if (err && err.message === 'Only image files are allowed') {
      return res.status(400).json({ error: err.message });
    }
    return res.status(500).json({ error: err.message || 'Server error' });
  });

  return app;
}

module.exports = { createApp };
