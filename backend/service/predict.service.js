const { subscribeToQueue } = require("../utils/rabbit.client");
const textToSpeechController = require('../controllers/textToSpeechController');

const createMockRes = () => {
  const result = {
    statusCode: 200,
    payload: null,
  };

  return {
    result,
    res: {
      status(code) {
        result.statusCode = code;
        return this;
      },
      json(payload) {
        result.payload = payload;
        return payload;
      },
    },
  };
};

const startQueueConsumer = async () => {
  await subscribeToQueue(process.env.QUEUE_NAME, async (data) => {
    if (data) {
      try {
        const messageText =
          typeof data === "string"
            ? data
            : typeof data?.text === "string"
              ? data.text
              : JSON.stringify(data);

        const mockReq = { body: { text: messageText } };
        const { res, result } = createMockRes();

        await textToSpeechController.speak(mockReq, res);

        if (result.statusCode >= 400) {
          throw new Error(result.payload?.message || "TTS request failed");
        }

        console.log("TTS completed:", result.payload?.message || "success");
      } catch (error) {
        console.error("Error calling API :", error.message);
      }
    }
  });
};

module.exports = { startQueueConsumer };