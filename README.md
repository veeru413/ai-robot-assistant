# 🤖 AI Voice-Controlled Robot

<div align="center">

![Robot Demo](https://img.shields.io/badge/Platform-ESP8266-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)
![Voice Control](https://img.shields.io/badge/Voice-Gemini%20AI-orange)

**A complete AI-powered voice-controlled robot system with real-time speech recognition, natural language processing, and autonomous navigation.**

[Features](#-features) • [Demo](#-demo) • [Hardware](#-hardware-requirements) • [Setup](#-quick-start) • [Documentation](#-documentation)

</div>

---

## 📋 Overview

This project combines **ESP8266 NodeMCU**, **Flutter mobile app**, and **Google Gemini AI** to create an intelligent voice-controlled robot. Simply speak commands like *"move forward 3 seconds then turn left"* and watch your robot execute them with natural language understanding.

### What Makes This Special?

- 🎤 **Natural Voice Commands** - Talk to your robot like a person, not a computer
- 🧠 **AI-Powered** - Gemini AI understands context and complex instructions
- 📱 **Beautiful UI** - Professional Flutter app with real-time feedback
- 🔊 **Text-to-Speech** - Robot responds with human-like voice (Azure TTS support)
- 🎮 **Multiple Modes** - Voice, Manual, Obstacle Avoidance, Line Follower, Gesture
- 🚀 **Real-time Control** - WebSocket communication for instant response

---

## ✨ Features

### 🎙️ Voice Control
- **Natural language processing** via Google Gemini AI
- **Speech-to-text** recognition
- **Command queuing** - Execute multiple commands in sequence
- **Visual feedback** - See commands being executed in real-time

### 🤖 Autonomous Modes
- **Line Follower** - Follows black lines using IR sensors
- **Obstacle Avoidance** - Navigates around obstacles using ultrasonic sensor
- **Manual Control** - Direct control with on-screen buttons
- **Gesture Control** - Control with hand gestures (accelerometer-based)

### 📱 Mobile App Features
- **LCD-style display** showing robot status
- **Command queue visualization**
- **Live speech recognition display**
- **API key management**
- **Landscape-optimized UI**

### 🔧 Technical Features
- **WebSocket communication** for low-latency control
- **Base64 audio streaming** (optional - for on-robot audio)
- **PWM motor control** with speed adjustment
- **Servo control** for arm and ultrasonic sensor
- **Modular code** - Easy to customize and extend

---

## 🎬 Demo

### Voice Command Example
```
User: "Move forward 3 seconds, then turn left and move forward again"

Robot: 🔊 "Moving forward for 3 seconds, then turning left!"
       ⬆️ [Moves forward] → ⬅️ [Turns left] → ⬆️ [Moves forward]
```

### App Interface
```
┌─────────────────────────────────────────────────┐
│  [←]  AI VOICE CONTROL  [✓ API Active]  [🤖]   │
├─────────────────────────────────────────────────┤
│                                                 │
│  🎤 READY              📺 [LCD Display]         │
│                           😊                    │
│  Press microphone                               │
│  to start...            [🎤 Mic Button]         │
│                                                 │
│                        COMMAND QUEUE            │
│                        ⬆️ Forward - 3s           │
│                        ⬅️ Left - 2s              │
└─────────────────────────────────────────────────┘
```

---

## 🛠️ Hardware Requirements

### Essential Components
| Component | Specification | Quantity |
|-----------|--------------|----------|
| **Microcontroller** | ESP8266 NodeMCU | 1 |
| **Motor Driver** | L298N or similar | 1 |
| **DC Motors** | 5V-12V with wheels | 2 |
| **Ultrasonic Sensor** | HC-SR04 | 1 |
| **IR Sensors** | Line follower sensors | 2 |
| **Servo Motors** | SG90 (9g) | 2 |
| **Power Supply** | 7.4V LiPo or 9V battery | 1 |
| **Chassis** | Robot car chassis kit | 1 |

### Optional (For On-Robot Audio)
| Component | Purpose |
|-----------|---------|
| PAM8403 Amplifier | Audio amplification |
| 3W Speaker | Audio output |

### Pin Configuration
```cpp
// Motors
Left Motor:  D1 (Forward), D2 (Backward)
Right Motor: D3 (Forward), D4 (Backward)

// Sensors
Ultrasonic: D7 (Trigger), D8 (Echo)
IR Sensors: A0 (Left), D0 (Right)

// Servos
Ultrasonic Servo: D5
Arm Servo: D6
```

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** (3.0 or higher)
- **Arduino IDE** with ESP8266 board support
- **Android Studio** or **VS Code**
- **Gemini API Key** (free from [Google AI Studio](https://aistudio.google.com/apikey))

### 1️⃣ Hardware Setup

1. **Wire the components** according to pin configuration above
2. **Upload Arduino code** to ESP8266:
   ```bash
   # Open arduino/robot_controller.ino
   # Set your Gemini API key at line 28
   # Select Board: NodeMCU 1.0 (ESP-12E Module)
   # Upload
   ```

### 2️⃣ Mobile App Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/ai-voice-robot.git
cd ai-voice-robot/flutter_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3️⃣ Connect & Control

1. **Power on the robot** - It creates WiFi hotspot "Robocell Car"
2. **Connect your phone** to robot's WiFi (password: `12345678`)
3. **Keep mobile data ON** (for Gemini API calls)
4. **Open the app** - Wait for "✓ API Active"
5. **Tap microphone** and speak your command!

---

## 📖 Documentation

### Voice Commands Examples

**Movement Commands:**
```
"Move forward"
"Go backward for 5 seconds"
"Turn left then move forward"
"Move forward 2 seconds, turn right, then go backward"
```

**Conversational:**
```
"How are you?"
"What's your name?"
"Stop moving"
```

### API Key Setup

**Arduino (robot_controller.ino):**
```cpp
// Line 28 - Add your Gemini API key
const char* GEMINI_API_KEY = "YOUR_KEY_HERE";
```

**Get Free API Key:**
1. Visit https://aistudio.google.com/apikey
2. Create new API key
3. Copy and paste in Arduino code
4. Free tier: 60 requests/minute

### Optional: Upgrade to Human-Like Voice

Replace robotic TTS with natural neural voices:

**Azure TTS (Recommended):**
- 500,000 characters/month FREE
- See `docs/AZURE_TTS_SETUP.md` for setup
- Sounds like a real person!

---

## 🏗️ Project Structure

```
ai-voice-robot/
├── arduino/
│   ├── robot_controller/
│   │   └── robot_controller.ino       # Main Arduino code
│   └── README.md                       # Arduino setup guide
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart                   # App entry point
│   │   ├── voice_enabled.dart          # Voice control screen
│   │   └── widgets/                    # Custom widgets
│   ├── pubspec.yaml                    # Flutter dependencies
│   └── README.md                       # App setup guide
├── docs/
│   ├── HARDWARE_ASSEMBLY.md            # Hardware wiring guide
│   ├── AZURE_TTS_SETUP.md              # Voice upgrade guide
│   └── API_REFERENCE.md                # WebSocket API docs
├── LICENSE
└── README.md
```

---

## 🔌 Architecture

```
┌─────────────┐         WiFi          ┌──────────────┐
│             │◄────────────────────► │              │
│  Flutter    │   WebSocket (81)      │   ESP8266    │
│  Mobile App │   Movement Commands   │   NodeMCU    │
│             │◄────────────────────► │              │
└─────────────┘                        └──────────────┘
       │                                      │
       │ Mobile Data                          │
       │ (Gemini API)                         │ GPIO Control
       ▼                                      ▼
┌─────────────┐                        ┌──────────────┐
│   Google    │                        │   Motors &   │
│  Gemini AI  │                        │   Sensors    │
│   (Cloud)   │                        │  (Hardware)  │
└─────────────┘                        └──────────────┘
```

**Data Flow:**
1. User speaks → Phone (Speech-to-Text)
2. Text → Gemini AI via mobile data
3. AI response → Phone (Text-to-Speech)
4. Movement commands → Robot via WiFi
5. Robot executes commands

---

## 🎯 Use Cases

### Educational
- Learn robotics and IoT integration
- Understand AI/ML in embedded systems
- Practice Flutter mobile development
- Explore natural language processing

### Projects
- **Home Automation** - Voice-controlled smart devices
- **Warehouse Robot** - Item retrieval with voice commands
- **Educational Demo** - AI robotics demonstration
- **Competition Entry** - Robotics competitions

### Research
- Human-robot interaction
- Voice interface design
- Edge AI deployment
- Multi-modal control systems

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### 🐛 Bug Reports
Open an issue with:
- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Hardware setup details

### ✨ Feature Requests
- Describe the feature
- Explain use case
- Suggest implementation (optional)

### 🔧 Pull Requests
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 🐛 Troubleshooting

### Robot not responding to voice
- ✅ Check API key in Arduino code
- ✅ Verify mobile data is ON
- ✅ Ensure "✓ API Active" shows in app
- ✅ Check serial monitor for errors

### Poor voice recognition
- 🎤 Speak clearly and at normal pace
- 📱 Reduce background noise
- 🔊 Hold phone closer to mouth
- 📶 Check internet connection

### Motors not working
- 🔋 Check battery voltage (>6V recommended)
- 🔌 Verify motor driver connections
- 💻 Check serial monitor for commands
- ⚡ Ensure power supply can handle motor current

### WebSocket disconnects
- 📡 Stay within WiFi range (< 10m)
- 🔋 Check robot battery level
- 📱 Disable phone's auto-sleep
- 🌐 Forget other WiFi networks on phone

---

## 📜 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

### What this means:
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ℹ️ License and copyright notice required

---

## 🙏 Acknowledgments

### Technologies Used
- **Google Gemini AI** - Natural language processing
- **Flutter** - Cross-platform mobile framework
- **ESP8266** - WiFi microcontroller
- **Azure TTS** - Neural text-to-speech (optional)
- **Google Translate TTS** - Fallback text-to-speech

### Inspiration
Built by **Robocell, CCA** - The Robotics Club of NIT Durgapur

Special thanks to:
- The open-source robotics community
- ESP8266 Arduino core developers
- Flutter team at Google
- Contributors and testers

---

## 📞 Support

### Need Help?
- 📖 Check [Documentation](docs/)
- 🐛 [Open an Issue](https://github.com/yourusername/ai-voice-robot/issues)
- 💬 [Discussions](https://github.com/yourusername/ai-voice-robot/discussions)

### Stay Updated
- ⭐ Star this repo to show support
- 👁️ Watch for updates
- 🔔 Subscribe to releases

---

## 🎓 Learn More

### Related Projects
- [ESP8266 Arduino Core](https://github.com/esp8266/Arduino)
- [Flutter Documentation](https://flutter.dev/docs)
- [Google Gemini AI](https://ai.google.dev/)

### Tutorials
- [ESP8266 WiFi Setup](docs/tutorials/wifi-setup.md)
- [Gemini API Integration](docs/tutorials/gemini-integration.md)
- [Custom Voice Commands](docs/tutorials/custom-commands.md)

---

<div align="center">

**Built with ❤️ by robotics enthusiasts**

⭐ **Star this repo if you found it helpful!** ⭐

[Report Bug](https://github.com/yourusername/ai-voice-robot/issues) • [Request Feature](https://github.com/yourusername/ai-voice-robot/issues) • [Documentation](docs/)

</div>
