const { exec } = require('child_process');
const { promisify } = require('util');
const os = require('os');
const gtts = require('gtts');
const fs = require('fs-extra');
const path = require('path');

const execAsync = promisify(exec);

// Ensure audio directory exists
const audioDir = path.join(__dirname, '../audio');
fs.ensureDirSync(audioDir);

/**
 * Get TTS command based on OS
 */
const getTTSCommand = (text, options = {}) => {
  const platform = os.platform();
  const { voice, speed = 1.0, volume = 0.8 } = options;

  // Escape text for shell
  const escapedText = text.replace(/'/g, "'\\''");

  if (platform === 'darwin') {
    // macOS - use 'say' command
    let cmd = `say '${escapedText}'`;
    
    if (voice) {
      cmd += ` -v ${voice}`;
    }
    
    // Speed: say uses rate (words per minute), default is ~200
    // Convert speed multiplier to WPM (0.5x = 100, 1.0x = 200, 2.0x = 400)
    const rate = Math.round(200 * speed);
    cmd += ` -r ${rate}`;
    
    // Volume: say uses volume 0-100, convert from 0-1
    const sayVolume = Math.round(volume * 100);
    cmd += ` --volume=${sayVolume}`;
    
    return cmd;
  } else if (platform === 'linux') {
    // Linux - use 'espeak' or 'spd-say'
    // Try espeak first (more common)
    let cmd = `espeak '${escapedText}'`;
    
    if (voice) {
      cmd += ` -v ${voice}`;
    }
    
    // Speed: espeak uses -s (words per minute), default is ~175
    const rate = Math.round(175 * speed);
    cmd += ` -s ${rate}`;
    
    // Volume: espeak uses -a (amplitude 0-200), default is 100
    const amplitude = Math.round(volume * 200);
    cmd += ` -a ${amplitude}`;
    
    return cmd;
  } else if (platform === 'win32') {
    // Windows - use PowerShell with SAPI.SpVoice
    // Note: Windows voice selection is limited, speed and volume are supported
    const rate = Math.round((speed - 1) * 10); // -10 to +10, 0 is normal
    const sayVolume = Math.round(volume * 100);
    
    const psScript = `
      $speak = New-Object -ComObject SAPI.SpVoice
      $speak.Rate = ${rate}
      $speak.Volume = ${sayVolume}
      $speak.Speak("${escapedText.replace(/"/g, '\\"')}")
    `.trim();
    
    return `powershell -Command "${psScript.replace(/"/g, '\\"')}"`;
  } else {
    throw new Error(`Unsupported platform: ${platform}`);
  }
};

/**
 * Get available voices for the platform
 */
const getAvailableVoices = async () => {
  const platform = os.platform();
  
  try {
    if (platform === 'darwin') {
      const { stdout } = await execAsync('say -v ?');
      return stdout.split('\n')
        .filter(line => line.trim())
        .map(line => {
          const match = line.match(/^(\S+)\s+(.+)$/);
          return match ? { code: match[1], name: match[2] } : null;
        })
        .filter(Boolean);
    } else if (platform === 'linux') {
      const { stdout } = await execAsync('espeak --voices');
      return stdout.split('\n')
        .slice(1) // Skip header
        .filter(line => line.trim())
        .map(line => {
          const parts = line.trim().split(/\s+/);
          return parts.length >= 4 ? { code: parts[1], name: parts[3] } : null;
        })
        .filter(Boolean);
    } else if (platform === 'win32') {
      // Windows has limited voice selection
      return [
        { code: 'default', name: 'Default System Voice' }
      ];
    }
  } catch (error) {
    console.error('Error getting voices:', error);
    return [];
  }
  
  return [];
};

/**
 * Convert text to speech using system TTS (say/espeak)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const speak = async (req, res) => {
  try {
    const { 
      text, 
      language = 'en',
      voice,
      speed = 1.0,
      volume = 0.8,
      pitch = 1.0 
    } = req.body;

    // Validate input
    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Text is required and must be a non-empty string',
      });
    }

    // Validate parameters
    if (speed < 0.1 || speed > 3.0) {
      return res.status(400).json({
        success: false,
        message: 'Speed must be between 0.1 and 3.0',
      });
    }

    if (volume < 0.0 || volume > 1.0) {
      return res.status(400).json({
        success: false,
        message: 'Volume must be between 0.0 and 1.0',
      });
    }

    // Language code mapping for gTTS
    const languageMap = {
      hi: 'hi', // Hindi
      en: 'en', // English
      bn: 'bn', // Bengali
      gu: 'gu', // Gujarati
      mr: 'mr', // Marathi
      ta: 'ta', // Tamil
      te: 'te', // Telugu
      pa: 'pa', // Punjabi
    };

    const ttsLanguage = languageMap[language] || 'en';

    // Generate unique filename
    const timestamp = Date.now();
    const filename = `speech_${timestamp}.mp3`;
    const filepath = path.join(audioDir, filename);

    // Generate audio file using gTTS (works for web clients)
    return new Promise((resolve, reject) => {
      const tts = new gtts(text, ttsLanguage);
      
      tts.save(filepath, async (err) => {
        if (err) {
          console.error('gTTS Error:', err);
          // Fallback to system TTS if gTTS fails
          try {
            const command = getTTSCommand(text, { voice, speed, volume, pitch });
            await execAsync(command, { timeout: 30000 });
            
            return res.json({
              success: true,
              message: 'Text spoken successfully (system TTS)',
              data: {
                text: text,
                language: language,
                voice: voice || 'default',
                speed: speed,
                volume: volume,
                pitch: pitch,
                platform: os.platform(),
                audioUrl: null, // System TTS doesn't generate file
              },
            });
          } catch (execError) {
            console.error('System TTS Error:', execError);
            return res.status(500).json({
              success: false,
              message: 'Failed to generate speech',
              error: err.message,
            });
          }
        }

        // Return audio file URL
        res.json({
          success: true,
          message: 'Audio generated successfully',
          data: {
            text: text,
            language: language,
            voice: voice || 'default',
            speed: speed,
            volume: volume,
            pitch: pitch,
            platform: os.platform(),
            audioUrl: `/api/audio/${filename}`,
            timestamp: timestamp,
          },
        });

        resolve();
      });
    });
  } catch (error) {
    console.error('Speak Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to convert text to speech',
      error: error.message,
    });
  }
};

/**
 * Get available voices
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getVoices = async (req, res) => {
  try {
    const voices = await getAvailableVoices();
    res.json({
      success: true,
      data: voices,
      platform: os.platform(),
    });
  } catch (error) {
    console.error('Get Voices Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get available voices',
      error: error.message,
    });
  }
};

/**
 * Get audio file
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getAudio = (req, res) => {
  try {
    const filename = req.params.filename;
    const filepath = path.join(audioDir, filename);

    if (!fs.existsSync(filepath)) {
      return res.status(404).json({
        success: false,
        message: 'Audio file not found',
      });
    }

    // Set appropriate headers
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
    
    // Stream the file
    const fileStream = fs.createReadStream(filepath);
    fileStream.pipe(res);
  } catch (error) {
    console.error('Get Audio Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve audio file',
      error: error.message,
    });
  }
};

/**
 * Legacy endpoint - convert text to speech (for backward compatibility)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const convertToSpeech = async (req, res) => {
  // Redirect to speak endpoint
  return speak(req, res);
};

module.exports = {
  speak,
  getVoices,
  convertToSpeech,
  getAudio,
};
