const Joi = require('joi');

const sensorSchema = Joi.object({
  deviceId: Joi.string().required(),

  sensors: Joi.object({
    flex: Joi.array().items(Joi.number()).length(3).required(),
    accel: Joi.array().items(Joi.number()).length(3).required(),
    gyro: Joi.array().items(Joi.number()).length(3).required(),
    orientation: Joi.array().items(Joi.number()).length(3).required()
  }).required()
});

module.exports = sensorSchema;
