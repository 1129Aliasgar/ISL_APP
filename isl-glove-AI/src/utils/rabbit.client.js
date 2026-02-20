const amqp = require("amqplib");

let channel;
let connection;

async function connect() {
  try {
    connection = await amqp.connect(process.env.RABBIT_MQ);
    channel = await connection.createChannel();
    console.log("RabbitMQ connected");
  } catch (error) {
    console.error("RabbitMQ connection error:", error);
  }
}

async function publishToQueue(queueName, data) {
  try {
    await channel.assertQueue(queueName);
    channel.sendToQueue(queueName, Buffer.from(JSON.stringify(data)));
    console.log(`Message sent to ${queueName}`);
  } catch (error) {
    console.error(error);
  }
}

async function subscribeToQueue(queueName, callback) {
  try {
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