const buffers = {};

const addToBuffer = (deviceId, reading) => {
  if (!buffers[deviceId]) {
    buffers[deviceId] = [];
  }

  buffers[deviceId].push(reading);

  if (buffers[deviceId].length >= 3) {
    const window = buffers[deviceId].slice(0, 3);
    buffers[deviceId] = buffers[deviceId].slice(10); // sliding step

    return window;
  }

  return null;
};

module.exports = { addToBuffer };
