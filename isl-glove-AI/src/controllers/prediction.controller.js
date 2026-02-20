const predictionService = require('../services/prediction.service');
const { publishToQueue } = require('../utils/rabbit.client')

const predict = async (req, res, next) => {
  try {
    const result = await predictionService.predictGesture(req.body.data);
    res.json({ prediction: result });
    await publishToQueue(process.env.QUEUE_NAME, result.character);
  } catch (err) {
    console.error("PREDICT ERROR:", err); 
    res.status(500).json({
      success: false,
      error: err
    });
  }
};

module.exports = { predict };
