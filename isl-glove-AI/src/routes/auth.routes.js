const express = require("express");
const validate = require("../middlewares/validate.middleware");
const { requireAuth } = require("../middlewares/auth.middleware");
const authController = require("../controllers/auth.controller");
const { registerSchema, loginSchema, updateAccountSchema } = require("../validators/auth.validator");

const router = express.Router();

router.post("/register", validate(registerSchema), authController.register);
router.post("/login", validate(loginSchema), authController.login);
router.get("/me", requireAuth, authController.me);
router.patch("/me", requireAuth, validate(updateAccountSchema), authController.updateAccount);

module.exports = router;
