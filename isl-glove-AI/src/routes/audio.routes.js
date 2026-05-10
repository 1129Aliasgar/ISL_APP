const express = require("express");
const audioController = require("../controllers/audio.controller");

const router = express.Router();

router.post("/tts/stream", audioController.streamTTS);
router.get("/audio/:filename", audioController.getAudioByFilename);

module.exports = router;
