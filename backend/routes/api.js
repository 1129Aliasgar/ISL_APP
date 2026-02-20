const express = require('express');
const router = express.Router();
const textToSpeechController = require('../controllers/textToSpeechController');
const path = require('path');

// Text to Speech endpoints
router.post('/speak', textToSpeechController.speak);
router.post('/text-to-speech', textToSpeechController.convertToSpeech); // Legacy endpoint
router.get('/voices', textToSpeechController.getVoices);

// Audio file endpoint
router.get('/audio/:filename', textToSpeechController.getAudio);

module.exports = router;

