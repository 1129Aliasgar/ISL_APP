const createSlidingWindows = (data, windowSize = 50, step = 10) => {
  const windows = [];

  for (let i = 0; i <= data.length - windowSize; i += step) {
    const window = data.slice(i, i + windowSize);
    windows.push(window);
  }

  return windows;
};

module.exports = { createSlidingWindows };
