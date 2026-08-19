require('dotenv').config();
const mongoose = require('mongoose');

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

async function maybeSeedUser() {
  if (!shouldSeedUserOnBoot()) {
    console.log('[boot] Seed user on boot is disabled');
    return;
  }
  await ensureSeedUser();
}

async function tryConnectDatabase() {
  try {
    await connectDatabase();
    return true;
  } catch (err) {
    console.error(
      '[db] Initial connection failed, API will start in degraded mode:',
      err.message
    );
    return false;
  }
}

function startDatabaseReconnectLoop() {
  const retryMs = Math.max(3_000, Number(process.env.DB_RETRY_MS) || 10_000);
  const timer = setInterval(async () => {
    if (mongoose.connection.readyState === 1 || mongoose.connection.readyState === 2) {
      return;
    }
    try {
      await connectDatabase();
      try {
        await maybeSeedUser();
      } catch (err) {
        console.error('[boot] Seed user failed:', err.message);
      }
      console.log('[db] Reconnected successfully');
      clearInterval(timer);
    } catch (err) {
      console.warn('[db] Reconnect attempt failed:', err.message);
    }
  }, retryMs);
  timer.unref();
}

async function main() {
  const dbConnected = await tryConnectDatabase();
  if (dbConnected) {
    try {
      await maybeSeedUser();
    } catch (err) {
      console.error('[boot] Seed user failed (API will still start):', err.message);
    }
  } else {
    startDatabaseReconnectLoop();
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
