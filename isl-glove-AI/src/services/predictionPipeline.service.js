const predictionService = require('./prediction.service');
const predictionResultService = require('./predictionResult.service');

const runPrediction = async (deviceId, window) => {
  const result = await predictionService.predictGesture(window);

  await predictionResultService.saveLatest({
    deviceId,
    prediction: result,
  });

  return result;
};

module.exports = { runPrediction };
