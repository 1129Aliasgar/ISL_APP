const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const sensorRoutes = require('./routes/sensor.routes');
const predictionRoutes = require('./routes/prediction.routes');
const errorMiddleware = require('./middlewares/error.middleware');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/api/sensors', sensorRoutes);
app.use('/api/predict', predictionRoutes);

app.use(errorMiddleware);

module.exports = app;
