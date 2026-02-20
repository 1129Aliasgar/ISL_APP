const axios = require("axios");
const { subscribeToQueue } = require("../utils/rabbit.client");

const startQueueConsumer = async () => {
  await subscribeToQueue(process.env.QUEUE_NAME, async (data) => {
    if (data) {
      try {
        const response = await axios.post(
          `${process.env.BACKEND_URL}/speak`,{
          text: data,
      });
        console.log("Response from API :", response.data);
      } catch (error) {
        console.error("Error calling API :", error.message);
      }
    }
  });
};

module.exports = { startQueueConsumer };