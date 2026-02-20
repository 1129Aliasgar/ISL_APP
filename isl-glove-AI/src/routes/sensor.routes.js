const express = require('express');
const router = express.Router();
const sensorController = require('../controllers/sensor.controller');
const validate = require('../middlewares/validate.middleware');
const sensorSchema = require('../validators/sensor.validator');

router.post('/', validate(sensorSchema), sensorController.createSensorData);

module.exports = router;
