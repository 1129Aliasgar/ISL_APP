const Joi = require('joi');

const FEATURES = 11;

const fullWindowSchema = Joi.object({
  deviceId: Joi.string().optional(),
  timestamp: Joi.date().iso().optional(),
  end: Joi.boolean().optional(),
  data: Joi.array()
    .min(1)
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
  end: Joi.boolean().optional().default(false),
  sensors: Joi.object({
    flex: Joi.array().items(Joi.number()).length(5).required(),
    accel: Joi.array().items(Joi.number()).length(3).required(),
    gyro: Joi.array().items(Joi.number()).length(3).required(),
  }).required(),
});

const predictionSchema = Joi.alternatives().try(fullWindowSchema, bufferedReadingSchema);

module.exports = predictionSchema;
