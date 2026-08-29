const clients = new Set();

function toPublic(doc) {
  const o = doc && typeof doc.toObject === 'function' ? doc.toObject() : doc;
  return {
    id: String(o._id || o.id || ''),
    type: o.type || 'car_added',
    title: o.title || 'New Car Arrival!',
    body: o.body || '',
    carId: o.carId ? String(o.carId) : '',
    carTitle: o.carTitle || '',
    imageUrl: o.imageUrl || '',
    createdAt: o.createdAt,
  };
}

function subscribe(req, res) {
  res.status(200);
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  if (typeof res.flushHeaders === 'function') {
    res.flushHeaders();
  }
  res.write(': connected\n\n');
  clients.add(res);

  const ping = setInterval(() => {
    try {
      res.write(': ping\n\n');
    } catch (_) {
      clearInterval(ping);
      clients.delete(res);
    }
  }, 25000);

  const cleanup = () => {
    clearInterval(ping);
    clients.delete(res);
  };
  req.on('close', cleanup);
  req.on('end', cleanup);
}

function broadcast(doc) {
  const payload = `event: car_added\ndata: ${JSON.stringify(toPublic(doc))}\n\n`;
  for (const res of [...clients]) {
    try {
      res.write(payload);
    } catch (_) {
      clients.delete(res);
    }
  }
}

module.exports = { subscribe, broadcast, toPublic };
