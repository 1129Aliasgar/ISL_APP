const predictionService = require('../services/prediction.service');

const predict = async (req, res, next) => {
  try {
    const result = await predictionService.predictGesture(req.body.data);
    res.json({ prediction: result });
  } catch (err) {
    console.error("PREDICT ERROR:", err); // 👈 IMPORTANT
    res.status(500).json({
      success: false,
      error: err
    });
  }
};

module.exports = { predict };
