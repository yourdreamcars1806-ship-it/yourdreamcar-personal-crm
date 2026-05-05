const cloudinary = require('cloudinary').v2;

/** Strip BOM, newlines, wrapping quotes (Railway/UI paste issues). */
function normalizeEnvValue(raw) {
  if (raw === undefined || raw === null) return '';
  let s = String(raw).replace(/\uFEFF/g, '').trim();
  s = s.replace(/\r?\n/g, '');
  if (
    (s.startsWith('"') && s.endsWith('"')) ||
    (s.startsWith("'") && s.endsWith("'"))
  ) {
    s = s.slice(1, -1).trim();
  }
  return s;
}

/**
 * cloudinary://API_KEY:API_SECRET@CLOUD_NAME
 * Secret may be URL-encoded if it contains reserved characters.
 */
function parseCloudinaryUrl(urlRaw) {
  const url = normalizeEnvValue(urlRaw);
  if (!url || !url.startsWith('cloudinary://')) {
    return null;
  }
  const body = url.slice('cloudinary://'.length);
  const at = body.lastIndexOf('@');
  if (at <= 0) return null;

  const cloudName = normalizeEnvValue(body.slice(at + 1));
  const pair = body.slice(0, at);
  const colon = pair.indexOf(':');
  if (colon <= 0) return null;

  const apiKey = normalizeEnvValue(pair.slice(0, colon));
  let apiSecret = pair.slice(colon + 1);
  if (/%[0-9A-Fa-f]{2}/.test(apiSecret)) {
    try {
      apiSecret = decodeURIComponent(apiSecret);
    } catch (_) {
      apiSecret = normalizeEnvValue(apiSecret);
    }
  } else {
    apiSecret = normalizeEnvValue(apiSecret);
  }

  if (!cloudName || !apiKey || !apiSecret) return null;
  return { cloudName, apiKey, apiSecret };
}

/** Returns configured Cloudinary client, or `null` if env vars are missing. */
function configureCloudinary() {
  const cloudName = normalizeEnvValue(process.env.CLOUDINARY_CLOUD_NAME);
  const apiKey = normalizeEnvValue(process.env.CLOUDINARY_API_KEY);
  const apiSecret = normalizeEnvValue(process.env.CLOUDINARY_API_SECRET);

  let resolved = null;
  if (cloudName && apiKey && apiSecret) {
    resolved = { cloudName, apiKey, apiSecret };
  } else {
    resolved = parseCloudinaryUrl(process.env.CLOUDINARY_URL);
  }

  if (!resolved?.cloudName || !resolved?.apiKey || !resolved?.apiSecret) {
    return null;
  }

  cloudinary.config({
    cloud_name: resolved.cloudName,
    api_key: resolved.apiKey,
    api_secret: resolved.apiSecret,
    secure: true,
  });

  return cloudinary;
}

module.exports = { configureCloudinary, normalizeEnvValue };
