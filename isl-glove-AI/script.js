const mongoose = require("mongoose");

const MONGO_URI="mongodb://127.0.0.1:27017/isl_glove";

async function updateGestureLabels() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGO_URI);

    console.log("✅ Connected to MongoDB");

    // Access the collection directly (no schema needed)
    const collection = mongoose.connection.db.collection("sensorwindows");

    // Count documents before updating
    const count = await collection.countDocuments({
      gestureLabel: "WE ARE FORM AIDS DEPARTENT",
    });

    console.log(`Found ${count} document(s) with gestureLabel = "WE ARE FORM AIDS DEPARTENT"`);

    if (count === 0) {
      console.log("No documents found.");
      return;
    }

    // Update all matching documents
    const result = await collection.updateMany(
      { gestureLabel: "WE ARE FORM AIDS DEPARTENT" },
      {
        $set: {
          gestureLabel: "A",
        },
      }
    );

    console.log("✅ Update completed");
    console.log(`Matched: ${result.matchedCount}`);
    console.log(`Modified: ${result.modifiedCount}`);
  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from MongoDB");
  }
}

updateGestureLabels();