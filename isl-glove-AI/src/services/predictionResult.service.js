const PredictionResult = require('../models/predictionResult.model');

const saveLatest = async ({ deviceId, prediction, audioUrl, audioFilename }) => {
  return PredictionResult.create({
    deviceId,
    prediction,
    audioUrl,
    audioFilename,
  });
};

const getLatest = async (deviceId) => {
  return PredictionResult.findOne({ deviceId }).sort({ createdAt: -1 }).lean();
};

module.exports = {
  saveLatest,
  getLatest,
};
