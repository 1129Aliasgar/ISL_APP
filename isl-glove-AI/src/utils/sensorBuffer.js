const buffers = {};
const WINDOW_SIZE = 50;
const STEP_SIZE = 10;

const addToBuffer = (deviceId, reading, timestamp = new Date()) => {
  if (!buffers[deviceId]) {
    buffers[deviceId] = [];
  }

  buffers[deviceId].push({
    reading,
    timestamp: new Date(timestamp),
  });

  if (buffers[deviceId].length >= WINDOW_SIZE) {
    const windowChunk = buffers[deviceId].slice(0, WINDOW_SIZE);
    const window = windowChunk.map((entry) => entry.reading);
    const windowStart = windowChunk[0].timestamp;
    buffers[deviceId] = buffers[deviceId].slice(STEP_SIZE); // sliding step

    return { window, windowStart };
  }

  return null;
};

module.exports = { addToBuffer };
