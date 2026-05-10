const path = require("path");
const AudioAsset = require("../models/audioAsset.model");
const { audioDir, generateSpeechFile } = require("../services/tts.service");

const streamTTS = async (req, res) => {
  try {
    const { text, deviceId, language = "en" } = req.body;
    if (!text || !deviceId) {
      return res.status(400).json({ success: false, message: "text and deviceId are required" });
    }

    const { filepath, filename } = await generateSpeechFile({ text, deviceId, language });
    res.setHeader("Content-Type", "audio/mpeg");
    res.setHeader("Content-Disposition", `inline; filename="${filename}"`);
    return res.sendFile(filepath);
  } catch (error) {
    return res.status(500).json({ success: false, message: "Failed to generate speech", error: error.message });
  }
};

const getAudioByFilename = async (req, res) => {
  try {
    const { filename } = req.params;
    const { deviceId } = req.query;

    const asset = await AudioAsset.findOne({ filename });
    if (!asset) {
      return res.status(404).json({ success: false, message: "Audio file not found" });
    }
    if (deviceId && asset.deviceId !== deviceId) {
      return res.status(403).json({ success: false, message: "Audio does not belong to this device" });
    }

    const filepath = path.join(audioDir, filename);
    res.setHeader("Content-Type", "audio/mpeg");
    res.setHeader("Content-Disposition", `inline; filename="${filename}"`);
    return res.sendFile(filepath);
  } catch (error) {
    return res.status(500).json({ success: false, message: "Failed to serve audio", error: error.message });
  }
};

module.exports = {
  streamTTS,
  getAudioByFilename,
};
