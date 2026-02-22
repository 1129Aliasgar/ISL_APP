const amqp = require("amqplib");

let channel;
let connection;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function connect(options = {}) {
  const maxRetries = Number(options.maxRetries ?? 30);
  const retryDelayMs = Number(options.retryDelayMs ?? 2000);
  const rabbitUrl = process.env.RABBIT_MQ;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      connection = await amqp.connect(rabbitUrl);
      channel = await connection.createChannel();
      console.log("RabbitMQ connected");
      return channel;
    } catch (error) {
      channel = null;
      console.error(
        `RabbitMQ connection error (attempt ${attempt}/${maxRetries}):`,
        error.message || error,
      );
      if (attempt < maxRetries) {
        await sleep(retryDelayMs);
      }
    }
  }

  throw new Error(`Unable to connect to RabbitMQ after ${maxRetries} attempts`);
}

async function publishToQueue(queueName, data) {
  try {
    if (!channel) {
      await connect();
    }
    await channel.assertQueue(queueName);
    channel.sendToQueue(queueName, Buffer.from(JSON.stringify(data)));
    console.log(`Message sent to ${queueName}`);
  } catch (error) {
    console.error(error);
  }
}

async function subscribeToQueue(queueName, callback) {
  try {
    if (!channel) {
      await connect();
    }
    await channel.assertQueue(queueName);
    channel.consume(queueName, (message) => {
      const data = JSON.parse(message.content.toString());
      callback(data);
      channel.ack(message);
    });
    console.log(`Listening to ${queueName}`);
  } catch (error) {
    console.error(error);
  }
}

module.exports = {
  connect,
  publishToQueue,
  subscribeToQueue,
};