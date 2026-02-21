const Joi = require('joi');

const TIMESTEPS = 50;
const FEATURES = 11;

const fullWindowSchema = Joi.object({
  deviceId: Joi.string().optional(),
  timestamp: Joi.date().iso().optional(),
  data: Joi.array()
    .length(TIMESTEPS)
    .items(
      Joi.array()
        .length(FEATURES)
        .items(Joi.number().required())
        .required()
    )
    .required(),
});

const bufferedReadingSchema = Joi.object({
  deviceId: Joi.string().required(),
  timestamp: Joi.date().iso().optional(),
  sensors: Joi.object({
    flex: Joi.array().items(Joi.number()).length(5).required(),
    accel: Joi.array().items(Joi.number()).length(3).required(),
    gyro: Joi.array().items(Joi.number()).length(3).required(),
  }).required(),
});

const predictionSchema = Joi.alternatives().try(fullWindowSchema, bufferedReadingSchema);

module.exports = predictionSchema;
