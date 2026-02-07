import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'Rounded_Buttons.dart';

class VoiceEnabled extends StatefulWidget {
  static const String id = "voice_enabled";

  @override
  State<VoiceEnabled> createState() => _VoiceEnabledState();
}

class _VoiceEnabledState extends State<VoiceEnabled>
    with SingleTickerProviderStateMixin {
  // WebSocket
  String serverUrl = 'ws://192.168.4.1:81';
  WebSocketChannel? channel;

  // Speech Recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";
  String _displayText = "Press microphone to start...";

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Gemini API — will be received from Arduino
  String geminiApiKey = "";
  bool apiKeyReceived = false;

  // Command Queue
  List<CommandStep> commandQueue = [];
  int currentCommandIndex = 0;
  bool isExecutingCommands = false;
  bool isPlayingAudio = false;

  // LCD Display state
  String lcdDisplay = "IDLE";
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);

    _initializeWebSocket();
    _initializeSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _initializeWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      print('WebSocket connected to $serverUrl');

      // Listen for messages from Arduino
      channel?.stream.listen((message) {
        print('Received from Arduino: $message');

        // Check if it's the API key
        if (message.toString().startsWith('GEMINI_API_KEY:')) {
          String receivedKey = message.toString().substring(15);
          setState(() {
            geminiApiKey = receivedKey;
            apiKeyReceived = true;
            _displayText = "✓ API Key received! Ready to use voice commands.";
          });
          print(
              '✓ Gemini API Key received: ${geminiApiKey.substring(0, 10)}...');
        }
      }, onError: (error) {
        print('WebSocket error: $error');
      });

      // Request API key on connection
      Future.delayed(Duration(milliseconds: 500), () {
        _sendCommand('VOICE_MODE');
      });
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      setState(() {
        _displayText = "Speech recognition not available";
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    channel?.sink.close();
    _speech.stop();
    _audioPlayer.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_isListening) {
      // Check if API key is received
      if (!apiKeyReceived || geminiApiKey.isEmpty) {
        setState(() {
          _displayText =
          "⚠️ Waiting for API key from robot...\nPress microphone again after connection.";
        });
        // Request API key again
        _sendCommand('REQUEST_API_KEY');
        return;
      }

      // Start listening
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _displayText = "Listening...";
          _recognizedText = "";
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _displayText = _recognizedText;
            });
            print('STT Recognized: $_recognizedText');
            print('Is Final: ${result.finalResult}');
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 30),
        );
      }
    } else {
      // Stop listening and process
      setState(() {
        _isListening = false;
      });
      _speech.stop();

      print('STT Stopped. Final recognized text: $_recognizedText');

      if (_recognizedText.isNotEmpty) {
        print('Processing command: $_recognizedText');
        _processVoiceCommand(_recognizedText);
      } else {
        print('No speech detected');
        setState(() {
          _displayText = "No speech detected. Try again.";
        });
      }
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    // Double-check API key
    if (!apiKeyReceived || geminiApiKey.isEmpty) {
      setState(() {
        _displayText = "Error: API key not available";
        lcdDisplay = "ERROR";
      });
      return;
    }

    setState(() {
      _displayText = "Processing: $command";
      lcdDisplay = "THINKING";
    });

    try {
      final response = await _callGeminiAPI(command);

      if (response != null) {
        print('Gemini Response: $response');

        Map<String, dynamic> jsonResponse = json.decode(response);

        String robotReply = jsonResponse['reply'] ?? "Command received";
        List<dynamic> commands = jsonResponse['commands'] ?? [];

        setState(() {
          _displayText = robotReply;
        });

        // First: Convert text to speech and play on phone
        await _convertAndPlayAudio(robotReply);

        // Second: Execute movement commands (after audio finishes)
        if (commands.isNotEmpty) {
          _parseAndExecuteCommands(commands);
        } else {
          setState(() {
            lcdDisplay = "IDLE";
            _displayText = "Press microphone to start...";
          });
        }
      }
    } catch (e) {
      print('Error processing command: $e');
      setState(() {
        _displayText = "Error: $e";
        lcdDisplay = "ERROR";
      });
    }
  }

  Future<String?> _callGeminiAPI(String prompt, {int retryCount = 0}) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey';

    final systemPrompt =
    '''You are Jarvis, a friendly robot assistant, Built by Robocell, CCA The Robotics club of N I T Durgapur

CRITICAL: You MUST respond with ONLY valid JSON. No markdown, no code blocks, no extra text.

Your response format:
{
  "reply": "Your spoken response here (max 50 words)",
  "commands": [
    {"direction": "forward", "duration": 3},
    {"direction": "left", "duration": 2}
  ]
}

Rules:
1. "reply" is what the robot will speak out loud
2. "commands" is an array of movement instructions
3. Valid directions: forward, backward, left, right, stop
4. Duration is in seconds (integer)
5. If no movement needed, use empty array: "commands": []
6. Keep replies conversational and friendly
7. NEVER use markdown formatting in your response

Examples:

Input: "how are you doing?"
Output:
{
  "reply": "I'm doing great! Thanks for asking. Ready to help you!",
  "commands": []
}

Input: "move forward for 3 seconds"
Output:
{
  "reply": "Moving forward for 3 seconds!",
  "commands": [{"direction": "forward", "duration": 3}]
}

Input: "go forward 2 seconds then turn left"
Output:
{
  "reply": "Going forward, then turning left!",
  "commands": [
    {"direction": "forward", "duration": 2},
    {"direction": "left", "duration": 1}
  ]
}

Remember: ONLY return valid JSON, nothing else!''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\nUser: $prompt'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String generatedText =
        data['candidates'][0]['content']['parts'][0]['text'];

        generatedText = generatedText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        print('Cleaned response: $generatedText');
        return generatedText;
      } else if (response.statusCode == 429 && retryCount < 3) {
        final waitTime = pow(2, retryCount) * 2;
        print(
            'Rate limit hit. Retrying in ${waitTime}s... (Attempt ${retryCount + 1}/3)');

        setState(() {
          _displayText = "Rate limited. Retrying in ${waitTime}s...";
        });

        await Future.delayed(Duration(seconds: waitTime.toInt()));
        return _callGeminiAPI(prompt, retryCount: retryCount + 1);
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Gemini API call error: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        setState(() {
          _displayText =
          "No internet connection.\nCheck your mobile data.";
        });
      }

      return null;
    }
  }

  Future<void> _convertAndPlayAudio(String text) async {
    setState(() {
      isPlayingAudio = true;
      lcdDisplay = "SPEAKING";
    });

    try {
      print('Converting text to speech: $text');

      final audioData = await _getAudioFromGoogleTranslateTTS(text);

      if (audioData != null) {
        print('Got audio data: ${audioData.length} bytes');

        await _audioPlayer.play(BytesSource(audioData));
        await _audioPlayer.onPlayerComplete.first;

        print('Audio playback complete');
      } else {
        print('Failed to get audio data');
      }
    } catch (e) {
      print('Error in audio playback: $e');
    } finally {
      setState(() {
        isPlayingAudio = false;
      });
    }
  }

  Future<Uint8List?> _getAudioFromGoogleTranslateTTS(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = 'https://translate.google.com/translate_tts?'
          'ie=UTF-8&'
          'q=$encodedText&'
          'tl=en&'
          'client=tw-ob';

      print('Using Google Translate TTS (playing on phone)');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );

      if (response.statusCode == 200) {
        print(
            'Got audio from Google Translate: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('Google Translate TTS error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Google Translate TTS error: $e');
      return null;
    }
  }

  void _parseAndExecuteCommands(List<dynamic> commands) {
    commandQueue.clear();
    currentCommandIndex = 0;

    for (var cmd in commands) {
      commandQueue.add(CommandStep(
        direction: cmd['direction'] ?? 'stop',
        duration: (cmd['duration'] ?? 1).toDouble(),
      ));
    }

    if (commandQueue.isNotEmpty) {
      setState(() {});
      _executeNextCommand();
    }
  }

  void _executeNextCommand() {
    if (currentCommandIndex >= commandQueue.length) {
      setState(() {
        lcdDisplay = "IDLE";
        isExecutingCommands = false;
        commandQueue.clear();
        _displayText = "Press microphone to start...";
      });
      _sendCommand('ST1');
      return;
    }

    setState(() {
      isExecutingCommands = true;
    });

    CommandStep currentCommand = commandQueue[currentCommandIndex];

    setState(() {
      lcdDisplay = currentCommand.direction.toUpperCase();
    });

    String cmd = _mapDirectionToCommand(currentCommand.direction);
    _sendCommand(cmd);

    Future.delayed(Duration(seconds: currentCommand.duration.toInt()), () {
      setState(() {
        currentCommandIndex++;
      });
      _executeNextCommand();
    });
  }

  String _mapDirectionToCommand(String direction) {
    switch (direction.toLowerCase()) {
      case 'forward':
        return 'Forward';
      case 'backward':
        return 'Backward';
      case 'left':
        return 'Left';
      case 'right':
        return 'Right';
      case 'stop':
        return 'ST1';
      default:
        return 'ST1';
    }
  }

  void _sendCommand(String command) {
    if (channel != null) {
      channel?.sink.add(command);
      print('Command sent: $command');
    } else {
      print('WebSocket not connected!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: .87,
            child: Image.asset(
              'images/background_image.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(height: 5),
              _buildTopBar(),
              SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildSpeechRecognitionPanel(),
                    ),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        Expanded(
                          child: _buildLCDDisplay(),
                        ),
                        SizedBox(height: 10),
                        _buildMicrophoneButton(),
                        SizedBox(height: 0),
                      ],
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildCommandQueuePanel(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopCard(
            child: IconButton(
              icon: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: const Icon(Icons.logout, color: Colors.yellow, size: 28),
              ),
              onPressed: () {
                _showExitDialog(context);
              },
            ),
          ),
          _buildTopCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "AI VOICE CONTROL",
                    style: GoogleFonts.electrolize(
                      fontSize: 26.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // API Key Status Indicator (ORIGINAL DESIGN)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        apiKeyReceived ? Icons.check_circle : Icons.warning,
                        color: apiKeyReceived ? Colors.green : Colors.orange,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        apiKeyReceived ? "API Active" : "Waiting for API...",
                        style: GoogleFonts.electrolize(
                          fontSize: 12.0,
                          color: apiKeyReceived ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildTopCard(
            child: Hero(
              tag: 'logo',
              child: SizedBox(
                height: 50,
                child: Image.asset('images/appicon2.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechRecognitionPanel() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Card(
        color: Colors.black.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                _isListening
                    ? Icons.mic
                    : isPlayingAudio
                    ? Icons.volume_up
                    : Icons.mic_none,
                size: 50,
                color: _isListening
                    ? Colors.red
                    : isPlayingAudio
                    ? Colors.green
                    : Colors.yellow,
              ),
              Text(
                _isListening
                    ? "RECORDING..."
                    : isPlayingAudio
                    ? "SPEAKING..."
                    : "READY",
                style: GoogleFonts.electrolize(
                  fontSize: 18,
                  color: _isListening
                      ? Colors.red
                      : isPlayingAudio
                      ? Colors.green
                      : Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.yellow.withOpacity(0.3), thickness: 2),
              SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _displayText,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.electrolize(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLCDDisplay() {
    return Card(
      color: Colors.black.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 280,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.yellow, width: 3),
        ),
        child: CustomPaint(
          painter: LCDPainter(
            display: lcdDisplay,
            isExecuting: isExecutingCommands,
            isSpeaking: isPlayingAudio,
          ),
        ),
      ),
    );
  }

  Widget _buildCommandQueuePanel() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 10),
      child: Card(
        color: Colors.black.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "COMMAND QUEUE",
                style: GoogleFonts.electrolize(
                  fontSize: 18,
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: Colors.yellow.withOpacity(0.3), thickness: 2),
              // FIXED: Proper overflow handling
              Expanded(
                child: commandQueue.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 60,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      Text(
                        "No commands",
                        style: GoogleFonts.electrolize(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: commandQueue.length - currentCommandIndex,
                  itemBuilder: (context, index) {
                    int actualIndex = currentCommandIndex + index;
                    bool isCurrent = index == 0 && isExecutingCommands;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.yellow.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? Colors.yellow : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        leading: Icon(
                          _getDirectionIcon(
                              commandQueue[actualIndex].direction),
                          color: isCurrent ? Colors.yellow : Colors.white,
                          size: 18,
                        ),
                        title: Text(
                          commandQueue[actualIndex]
                              .direction
                              .toUpperCase(),
                          style: GoogleFonts.electrolize(
                            fontSize: 13,
                            color:
                            isCurrent ? Colors.yellow : Colors.white,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.yellow.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${commandQueue[actualIndex].duration.toInt()}s',
                            style: GoogleFonts.electrolize(
                              fontSize: 12,
                              color: isCurrent
                                  ? Colors.yellow
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDirectionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'forward':
        return Icons.arrow_upward;
      case 'backward':
        return Icons.arrow_downward;
      case 'left':
        return Icons.arrow_back;
      case 'right':
        return Icons.arrow_forward;
      case 'stop':
        return Icons.stop;
      default:
        return Icons.stop;
    }
  }

  Widget _buildMicrophoneButton() {
    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? 1.0 + (_pulseController!.value * 0.1) : 1.0,
          child: GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Colors.red
                    : isPlayingAudio
                    ? Colors.green
                    : Colors.yellow,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                        ? Colors.red
                        : isPlayingAudio
                        ? Colors.green
                        : Colors.yellow)
                        .withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                _isListening
                    ? Icons.mic
                    : isPlayingAudio
                    ? Icons.volume_up
                    : Icons.mic_none,
                size: 50,
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard({required Widget child}) {
    return Card(
      color: Colors.black54,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Card(
              color: Colors.grey[800]?.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Confirmation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Exit AI Voice Control Mode?',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: RoundedButton1(
                            width: 50,
                            length: 16,
                            text: 'No',
                            colors: Colors.yellow,
                            onPressed: () => Navigator.pop(context),
                            text_color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: RoundedButton1(
                            width: 50,
                            length: 16,
                            text: 'Yes',
                            colors: Colors.grey,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            text_color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CommandStep {
  final String direction;
  final double duration;

  CommandStep({required this.direction, required this.duration});
}

class LCDPainter extends CustomPainter {
  final String display;
  final bool isExecuting;
  final bool isSpeaking;

  LCDPainter({
    required this.display,
    required this.isExecuting,
    required this.isSpeaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSpeaking ? Colors.green : Colors.yellow
      ..style = PaintingStyle.fill;

    final pixelSize = 6.0;

    if (display == "IDLE") {
      _drawSmileyFace(canvas, size, paint, pixelSize);
    } else if (display == "SPEAKING") {
      _drawSpeakerIcon(canvas, size, paint, pixelSize);
    } else if (display == "THINKING") {
      _drawThinkingIcon(canvas, size, paint, pixelSize);
    } else if (display == "FORWARD") {
      _drawArrowUp(canvas, size, paint, pixelSize);
    } else if (display == "BACKWARD") {
      _drawArrowDown(canvas, size, paint, pixelSize);
    } else if (display == "LEFT") {
      _drawArrowLeft(canvas, size, paint, pixelSize);
    } else if (display == "RIGHT") {
      _drawArrowRight(canvas, size, paint, pixelSize);
    } else if (display == "ERROR") {
      _drawErrorIcon(canvas, size, paint, pixelSize);
    } else {
      _drawText(canvas, size, paint, display);
    }
  }

  void _drawSmileyFace(
      Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    _drawPixel(canvas, paint, centerX - 35, centerY - 25, pixelSize * 2);
    _drawPixel(canvas, paint, centerX + 35, centerY - 25, pixelSize * 2);
    List<Offset> smilePixels = [
      Offset(centerX - 50, centerY + 15),
      Offset(centerX - 40, centerY + 25),
      Offset(centerX - 30, centerY + 32),
      Offset(centerX - 20, centerY + 37),
      Offset(centerX - 10, centerY + 40),
      Offset(centerX, centerY + 42),
      Offset(centerX + 10, centerY + 40),
      Offset(centerX + 20, centerY + 37),
      Offset(centerX + 30, centerY + 32),
      Offset(centerX + 40, centerY + 25),
      Offset(centerX + 50, centerY + 15),
    ];
    for (var pixel in smilePixels) {
      _drawPixel(canvas, paint, pixel.dx, pixel.dy, pixelSize * 1.5);
    }
  }

  void _drawSpeakerIcon(
      Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final speakerPath = Path()
      ..moveTo(centerX - 30, centerY - 25)
      ..lineTo(centerX - 10, centerY - 25)
      ..lineTo(centerX + 10, centerY - 40)
      ..lineTo(centerX + 10, centerY + 40)
      ..lineTo(centerX - 10, centerY + 25)
      ..lineTo(centerX - 30, centerY + 25)
      ..close();
    canvas.drawPath(speakerPath, paint);
    for (int wave = 1; wave <= 3; wave++) {
      final waveX = centerX + 20 + (wave * 15);
      _drawCircle(canvas, paint, waveX, centerY - 30, pixelSize);
      _drawCircle(canvas, paint, waveX, centerY, pixelSize);
      _drawCircle(canvas, paint, waveX, centerY + 30, pixelSize);
    }
  }

  void _drawThinkingIcon(
      Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    _drawCircle(canvas, paint, centerX - 40, centerY, pixelSize * 3);
    _drawCircle(canvas, paint, centerX, centerY, pixelSize * 3);
    _drawCircle(canvas, paint, centerX + 40, centerY, pixelSize * 3);
  }

  void _drawArrowUp(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final path = Path()
      ..moveTo(centerX, centerY - 50)
      ..lineTo(centerX - 30, centerY - 20)
      ..lineTo(centerX - 15, centerY - 20)
      ..lineTo(centerX - 15, centerY + 50)
      ..lineTo(centerX + 15, centerY + 50)
      ..lineTo(centerX + 15, centerY - 20)
      ..lineTo(centerX + 30, centerY - 20)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawArrowDown(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final path = Path()
      ..moveTo(centerX, centerY + 50)
      ..lineTo(centerX - 30, centerY + 20)
      ..lineTo(centerX - 15, centerY + 20)
      ..lineTo(centerX - 15, centerY - 50)
      ..lineTo(centerX + 15, centerY - 50)
      ..lineTo(centerX + 15, centerY + 20)
      ..lineTo(centerX + 30, centerY + 20)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawArrowLeft(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final path = Path()
      ..moveTo(centerX - 50, centerY)
      ..lineTo(centerX - 20, centerY - 30)
      ..lineTo(centerX - 20, centerY - 15)
      ..lineTo(centerX + 50, centerY - 15)
      ..lineTo(centerX + 50, centerY + 15)
      ..lineTo(centerX - 20, centerY + 15)
      ..lineTo(centerX - 20, centerY + 30)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawArrowRight(
      Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final path = Path()
      ..moveTo(centerX + 50, centerY)
      ..lineTo(centerX + 20, centerY - 30)
      ..lineTo(centerX + 20, centerY - 15)
      ..lineTo(centerX - 50, centerY - 15)
      ..lineTo(centerX - 50, centerY + 15)
      ..lineTo(centerX + 20, centerY + 15)
      ..lineTo(centerX + 20, centerY + 30)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawErrorIcon(Canvas canvas, Size size, Paint paint, double pixelSize) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    paint.color = Colors.red;
    final thickness = pixelSize * 3;
    canvas.drawLine(Offset(centerX - 40, centerY - 40),
        Offset(centerX + 40, centerY + 40), paint..strokeWidth = thickness);
    canvas.drawLine(Offset(centerX + 40, centerY - 40),
        Offset(centerX - 40, centerY + 40), paint..strokeWidth = thickness);
  }

  void _drawText(Canvas canvas, Size size, Paint paint, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: paint.color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2,
            (size.height - textPainter.height) / 2));
  }

  void _drawCircle(
      Canvas canvas, Paint paint, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  void _drawPixel(Canvas canvas, Paint paint, double x, double y, double size) {
    canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: size, height: size),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}