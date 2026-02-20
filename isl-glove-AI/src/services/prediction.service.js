const { spawn } = require('child_process');
const path = require('path');

const predictGesture = (sensorData) => {
  return new Promise((resolve, reject) => {

    const projectRoot = process.cwd();

    const pythonPath = path.join(projectRoot, 'venv', 'Scripts', 'python.exe');
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
