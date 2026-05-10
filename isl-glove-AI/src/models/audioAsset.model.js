const mongoose = require("mongoose");

const audioAssetSchema = new mongoose.Schema(
  {
    filename: { type: String, required: true, unique: true },
    deviceId: { type: String, required: true, index: true },
    text: { type: String, required: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model("AudioAsset", audioAssetSchema);
