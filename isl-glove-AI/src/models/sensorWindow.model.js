const mongoose = require('mongoose');

const sensorWindowSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
  },
  gestureLabel: {
    type: String,
    default: null,
  },
  windowStart: {
    type: Date,
    required: true,
  },
  data: {
    type: [[Number]], 
    required: true,
  }
}, { timestamps: true });

module.exports = mongoose.model('SensorWindow', sensorWindowSchema);
