require('dotenv').config();

const env = {
  port: process.env.PORT || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoURI: process.env.MONGO_URI,
  modelPath: process.env.MODEL_PATH,
  pythonPath: process.env.PYTHON_PATH || 'python'
};

module.exports = env;
