require('dotenv').config();

const { connectDatabase } = require('./config/database');
const { configureCloudinary } = require('./config/cloudinary');
const { ensureSeedUser } = require('./bootstrap/ensureSeedUser');
const { createApp } = require('./app');

const port = Number(process.env.PORT) || 5000;
const host = process.env.HOST || '0.0.0.0';

function shouldSeedUserOnBoot() {
  if (process.env.SEED_USER_ON_BOOT === 'true') {
    return true;
  }
  if (process.env.NODE_ENV === 'production') {
    return false;
  }
  return true;
}

async function main() {
  await connectDatabase();
  if (shouldSeedUserOnBoot()) {
    await ensureSeedUser();
  } else {
    console.log('[boot] Seed user on boot is disabled');
  }
  const cloudinary = configureCloudinary();
  if (!cloudinary) {
    console.warn(
      '[boot] Cloudinary not configured — POST /api/upload/image returns 503 until CLOUDINARY_* is set'
    );
  }
  const app = createApp(cloudinary);
  const server = app.listen(port, host, () => {
    console.log(`Server listening on port ${port} (bound to ${host})`);
    console.log('Auth: POST /api/auth/login');
  });

  function shutdown(signal) {
    console.log(`[boot] Received ${signal}, shutting down server...`);
    server.close(() => {
      console.log('[boot] HTTP server closed');
      process.exit(0);
    });
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
