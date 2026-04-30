const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const predictGesture = (sensorData) => {
  return new Promise((resolve, reject) => {
    const projectRoot = process.cwd();
    const mlDir = path.join(projectRoot, 'ml');
    const hasTflite = fs.existsSync(path.join(mlDir, 'model.tflite'));
    const hasKeras = fs.existsSync(path.join(mlDir, 'gesture_model.h5'));
    const requiredArtifacts = ['normalizer.npz', 'labels.json'];
    const missingArtifacts = requiredArtifacts.filter((name) => !fs.existsSync(path.join(mlDir, name)));

    if (missingArtifacts.length > 0 || (!hasTflite && !hasKeras)) {
      const modelMessage = hasTflite || hasKeras
        ? ''
        : 'Missing model file: expected ml/model.tflite or ml/gesture_model.h5. ';
      return reject(
        `${modelMessage}Missing ML artifacts in /app/ml: ${missingArtifacts.join(', ') || 'none'}. ` +
        'Generate/copy model files before calling /api/predict.'
      );
    }

    const windowsVenvPython = path.join(projectRoot, 'venv', 'Scripts', 'python.exe');
    const unixVenvPython = path.join(projectRoot, 'venv', 'bin', 'python');

    // Prefer local project venv for non-container runs.
    // Fall back to env-provided interpreter (used by Docker compose), then system python.
    const pythonPath = (fs.existsSync(windowsVenvPython) ? windowsVenvPython : null)
      || (fs.existsSync(unixVenvPython) ? unixVenvPython : null)
      || process.env.PYTHON_PATH
      || 'python3';

    const scriptPath = path.join(projectRoot, 'ml', 'predict.py');

    const python = spawn(pythonPath, [
      scriptPath,
      JSON.stringify(sensorData)
    ]);

    let result = '';
    let errorOutput = '';

    python.stdout.on('data', (data) => {
      result += data.toString();
    });

    python.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    python.on('close', (code) => {
      if (code !== 0) {
        return reject(errorOutput);
      }

      try {
        const parsed = JSON.parse(result);
        resolve(parsed);
      } catch (err) {
        reject("Invalid JSON from Python: " + result);
      }
    });

    python.on('error', (err) => {
      reject("Spawn error: " + err.message);
    });
  });
};

module.exports = { predictGesture };
