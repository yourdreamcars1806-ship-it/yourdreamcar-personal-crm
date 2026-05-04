const mongoose = require('mongoose');

/** Works with local MongoDB and MongoDB Atlas (mongodb+srv). */
const connectOptions = {
  serverSelectionTimeoutMS: 15_000,
  maxPoolSize: Math.min(
    50,
    Math.max(10, Number(process.env.MONGO_MAX_POOL) || 25)
  ),
  minPoolSize: Math.min(
    5,
    Math.max(0, Number(process.env.MONGO_MIN_POOL) || 2)
  ),
  autoIndex: process.env.NODE_ENV !== 'production',
};

function normalizeMongoUri(rawUri) {
  const uri = rawUri.trim();
  const defaultDbName = (process.env.MONGODB_DB_NAME || 'yourdreamcar').trim();
  if (!defaultDbName) {
    return uri;
  }

  try {
    const parsed = new URL(uri);
    const hasDbPath = parsed.pathname && parsed.pathname !== '/';
    if (hasDbPath) {
      return uri;
    }
    parsed.pathname = `/${defaultDbName}`;
    return parsed.toString();
  } catch (_) {
    return uri;
  }
}

async function connectDatabase() {
  const rawUri = process.env.MONGODB_URI?.trim();
  if (!rawUri) {
    throw new Error(
      'MONGODB_URI is not set. Copy .env.example to .env and set your connection string.'
    );
  }
  const uri = normalizeMongoUri(rawUri);

  await mongoose.connect(uri, connectOptions);

  const name = mongoose.connection.name;
  const host = mongoose.connection.host;
  console.log(`[db] Connected: ${name} @ ${host}`);
}

module.exports = { connectDatabase };
