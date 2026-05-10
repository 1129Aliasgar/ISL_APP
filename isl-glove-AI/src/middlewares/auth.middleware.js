const jwt = require("jsonwebtoken");
const User = require("../models/user.model");

const requireAuth = async (req, res, next) => {
  try {
    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    if (!token) {
      return res.status(401).json({ success: false, message: "Missing auth token" });
    }
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (!user) {
      return res.status(401).json({ success: false, message: "Invalid auth token" });
    }
    req.user = { id: user._id.toString(), name: user.name, email: user.email, deviceId: user.deviceId };
    return next();
  } catch (error) {
    return res.status(401).json({ success: false, message: "Unauthorized", error: error.message });
  }
};

module.exports = { requireAuth };
