const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user.model");

const signToken = (user) =>
  jwt.sign(
    { sub: user._id.toString(), email: user.email, name: user.name, deviceId: user.deviceId },
    process.env.JWT_SECRET,
    { expiresIn: "7d" },
  );

const register = async (req, res) => {
  try {
    const { name, email, password, deviceId } = req.body;
    const existing = await User.findOne({ $or: [{ email }, { deviceId }] });
    if (existing) {
      return res.status(409).json({ success: false, message: "Email or deviceId already registered" });
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, passwordHash, deviceId });
    const token = signToken(user);
    return res.status(201).json({
      success: true,
      user: { id: user._id, name: user.name, email: user.email, deviceId: user.deviceId },
      token,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { identifier, password } = req.body;
    const user = await User.findOne({ $or: [{ email: identifier.toLowerCase() }, { name: identifier }] });
    if (!user) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }
    const token = signToken(user);
    return res.json({
      success: true,
      user: { id: user._id, name: user.name, email: user.email, deviceId: user.deviceId },
      token,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const me = async (req, res) => {
  return res.json({ success: true, user: req.user });
};

const updateAccount = async (req, res) => {
  try {
    const { name, email, deviceId, password } = req.body;
    const updates = {};
    if (name) updates.name = name;
    if (email) updates.email = email.toLowerCase();
    if (deviceId) updates.deviceId = deviceId;
    if (password) updates.passwordHash = await bcrypt.hash(password, 10);

    const updated = await User.findByIdAndUpdate(req.user.id, updates, { new: true, runValidators: true });
    return res.json({
      success: true,
      user: { id: updated._id, name: updated.name, email: updated.email, deviceId: updated.deviceId },
    });
  } catch (error) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = {
  register,
  login,
  me,
  updateAccount,
};
