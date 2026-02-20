const Joi = require('joi');

const TIMESTEPS = 50;
const FEATURES = 11;

const predictionSchema = Joi.object({
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

module.exports = predictionSchema;
