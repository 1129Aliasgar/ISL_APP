const buffers = {};

const addToBuffer = (deviceId, reading, timestamp = new Date()) => {
  if (!buffers[deviceId]) {
    buffers[deviceId] = [];
  }

  buffers[deviceId].push({
    reading,
    timestamp: new Date(timestamp),
  });
};

const flushBuffer = (deviceId) => {
  const entries = buffers[deviceId] || [];
  if (entries.length === 0) {
    return null;
  }

  const window = entries.map((entry) => entry.reading);
  const windowStart = entries[0].timestamp;
  delete buffers[deviceId];

  return { window, windowStart };
};

const getBufferSize = (deviceId) => {
  return (buffers[deviceId] || []).length;
};

module.exports = { addToBuffer, flushBuffer, getBufferSize };
