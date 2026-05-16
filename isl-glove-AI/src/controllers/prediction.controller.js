const predictionService = require('../services/prediction.service');
const predictionResultService = require('../services/predictionResult.service');
const { addToBuffer, flushBuffer, getBufferSize } = require('../utils/sensorBuffer');
const { generateSpeechFile, buildPublicBaseUrl } = require('../services/tts.service');

const predict = async (req, res, next) => {
  try {
    let predictionInput = req.body.data;

    if (!predictionInput && req.body.sensors && req.body.deviceId) {
      const { flex, accel, gyro } = req.body.sensors;
      const reading = [...flex, ...accel, ...gyro];
      const readingTimestamp = req.body.timestamp ? new Date(req.body.timestamp) : new Date();
      const end = req.body.end === true || req.body.end === "true";

      addToBuffer(req.body.deviceId, reading, readingTimestamp);
      if (!end) {
        return res.status(202).json({
          success: true,
          buffered: true,
          message: 'Reading buffered. Send end=true to run prediction for this sequence.',
          bufferedCount: getBufferSize(req.body.deviceId),
        });
      }

      const flushed = flushBuffer(req.body.deviceId);
      if (!flushed) {
        return res.status(400).json({
          success: false,
          error: "No buffered data found for prediction"
        });
      }
      predictionInput = flushed.window;
    }

    const result = await predictionService.predictGesture(predictionInput);
    const deviceId = req.body.deviceId;
    if (!deviceId) {
      return res.status(400).json({
        success: false,
        error: "deviceId is required to save and deliver prediction results",
      });
    }
    const { filename } = await generateSpeechFile({
      text: result.character,
      deviceId,
      language: req.body.language || "en",
    });
    const baseUrl = buildPublicBaseUrl(req);
    const audioUrl = `${baseUrl}/api/audio/${filename}?deviceId=${encodeURIComponent(deviceId)}`;

    const saved = await predictionResultService.saveLatest({
      deviceId,
      prediction: result,
      audioUrl,
      audioFilename: filename,
    });

    return res.json({
      success: true,
      prediction: result,
      audioUrl,
      id: saved._id.toString(),
      createdAt: saved.createdAt,
    });
  } catch (err) {
    console.error("PREDICT ERROR:", err); 
    const message = typeof err === 'string' ? err : err.message || String(err);
    const statusCode = message.includes('Missing ML artifacts') ? 503 : 500;
    return res.status(statusCode).json({
      success: false,
      error: message
    });
  }
};

const getLatest = async (req, res) => {
  try {
    const { deviceId } = req.params;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: "deviceId is required" });
    }

    const latest = await predictionResultService.getLatest(deviceId);
    if (!latest) {
      return res.status(404).json({ success: false, message: "No predictions yet for this device" });
    }

    return res.json({
      success: true,
      id: latest._id.toString(),
      prediction: latest.prediction,
      audioUrl: latest.audioUrl,
      createdAt: latest.createdAt,
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
};

module.exports = { predict, getLatest };
