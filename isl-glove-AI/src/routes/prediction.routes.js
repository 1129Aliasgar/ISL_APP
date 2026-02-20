const express = require('express');
const router = express.Router();
const predictionController = require('../controllers/prediction.controller');
const validate = require('../middlewares/validate.middleware');
const predictionSchema = require('../validators/prediction.validator');

router.post('/', validate(predictionSchema), predictionController.predict);

module.exports = router;
