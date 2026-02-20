require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { connect } = require("./src/utils/rabbit.client")

const PORT = process.env.PORT || 5000;

connectDB();

// connect to rabbit
connect();

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
