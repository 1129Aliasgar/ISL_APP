const Joi = require("joi");

const registerSchema = Joi.object({
  name: Joi.string().min(2).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  deviceId: Joi.string().min(2).required(),
});

const loginSchema = Joi.object({
  identifier: Joi.string().required(),
  password: Joi.string().required(),
});

const updateAccountSchema = Joi.object({
  name: Joi.string().min(2).optional(),
  email: Joi.string().email().optional(),
  password: Joi.string().min(6).optional(),
  deviceId: Joi.string().min(2).optional(),
}).min(1);

module.exports = {
  registerSchema,
  loginSchema,
  updateAccountSchema,
};
