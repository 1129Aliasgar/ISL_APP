const SensorWindow = require('../models/sensorWindow.model');

const saveSensorWindow = async (payload) => {
  return await SensorWindow.create(payload);
};

const getUnlabeledData = async () => {
  return await SensorWindow.find({ gestureLabel: null });
};

module.exports = {
  saveSensorWindow,
  getUnlabeledData,
};
