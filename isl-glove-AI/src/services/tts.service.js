const path = require("path");
const fs = require("fs-extra");
const gtts = require("gtts");

const AudioAsset = require("../models/audioAsset.model");

const audioDir = path.join(process.cwd(), "audio");
fs.ensureDirSync(audioDir);

const languageMap = {
  hi: "hi",
  en: "en",
  bn: "bn",
  gu: "gu",
  mr: "mr",
  ta: "ta",
  te: "te",
  pa: "pa",
};

const buildPublicBaseUrl = (req) => {
  if (process.env.PUBLIC_BASE_URL) {
    return process.env.PUBLIC_BASE_URL.replace(/\/$/, "");
  }
  const proto = req.headers["x-forwarded-proto"] || req.protocol || "http";
  const host = req.headers["x-forwarded-host"] || req.get("host") || `localhost:${process.env.PORT || 5000}`;
  return `${proto}://${host}`;
};

const generateSpeechFile = async ({ text, deviceId, language = "en" }) => {
  const ttsLanguage = languageMap[language] || "en";
  const filename = `speech_${Date.now()}_${Math.random().toString(36).slice(2, 8)}.mp3`;
  const filepath = path.join(audioDir, filename);

  await new Promise((resolve, reject) => {
    const tts = new gtts(text, ttsLanguage);
    tts.save(filepath, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });

  await AudioAsset.create({ filename, deviceId, text });
  return { filename, filepath };
};

module.exports = {
  audioDir,
  buildPublicBaseUrl,
  generateSpeechFile,
};
