const mongoose = require("mongoose");

const predictionResultSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true, index: true },
    prediction: {
      character: { type: String, required: true },
      confidence: { type: Number },
      probabilities: { type: mongoose.Schema.Types.Mixed },
    },
    audioUrl: { type: String, required: true },
    audioFilename: { type: String, required: true },
  },
  { timestamps: true },
);

predictionResultSchema.index({ deviceId: 1, createdAt: -1 });

module.exports = mongoose.model("PredictionResult", predictionResultSchema);
