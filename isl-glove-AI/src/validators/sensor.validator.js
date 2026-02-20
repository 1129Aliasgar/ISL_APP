const Joi = require('joi');

const sensorSchema = Joi.object({
  deviceId: Joi.string().required(),
  timestamp: Joi.date().iso().required(),

  sensors: Joi.object({
    flex: Joi.array().items(Joi.number()).length(5).required(),
    accel: Joi.array().items(Joi.number()).length(3).required(),
    gyro: Joi.array().items(Joi.number()).length(3).required()
  }).required()
});

module.exports = sensorSchema;
