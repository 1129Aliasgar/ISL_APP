const express = require('express');
const router = express.Router();
const predictionController = require('../controllers/prediction.controller');

router.post('/', predictionController.predict);

module.exports = router;
