let predictNamespace = null;

const setPredictNamespace = (ns) => {
  predictNamespace = ns;
};

const emitPredictionResult = (deviceId, result) => {
  if (!predictNamespace || !deviceId || !result) return;

  predictNamespace.to(`predict:${deviceId}`).emit('prediction:result', {
    deviceId,
    text: result.character,
    character: result.character,
    confidence: result.confidence,
    probabilities: result.probabilities,
    timestamp: new Date().toISOString(),
  });
};

const emitPredictionError = (deviceId, message) => {
  if (!predictNamespace || !deviceId) return;

  predictNamespace.to(`predict:${deviceId}`).emit('prediction:error', {
    deviceId,
    message,
  });
};

module.exports = {
  setPredictNamespace,
  emitPredictionResult,
  emitPredictionError,
};
