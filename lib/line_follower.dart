import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robozido/Rounded_Buttons.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LineFollower extends StatefulWidget {
  static const String id = "line_follower";
  @override
  State<LineFollower> createState() => _LineFollowerState();
}

class _LineFollowerState extends State<LineFollower> {
  String mode = 'ST';
  bool isManualModeActive = false;
  bool isLineFollowerModeActive = false;
  bool isObstacleAvoidanceModeActive = false;
  String serverUrl = 'ws://192.168.4.1:81';
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    channel = WebSocketChannel.connect(Uri.parse(serverUrl));
  }

  void sendCommand(String command) {
    if (channel != null) {
      channel!.sink.add(command);
      print('Command sent: $command');
    } else {
      print('Error: WebSocket not connected');
    }
  }

  void toggleMode(String selectedMode) {
    setState(() {
      mode = selectedMode;
      isManualModeActive = selectedMode == 'm';
      isLineFollowerModeActive = selectedMode == 'l';
      isObstacleAvoidanceModeActive = selectedMode == 'o';
    });
    sendCommand(selectedMode);
  }

  bool isRunning = false;

  void _toggleStartStop() {
    setState(() {
      HapticFeedback.vibrate();
      isRunning = !isRunning;

      if (isRunning) {
        sendCommand('l');
      } else {
        sendCommand('ST');
      }
    });
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/background_image.jpeg',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildTopCard1(
                        child: IconButton(
                          icon: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(3.14159), // Flips the icon horizontally
                            child: Icon(
                              Icons.logout,
                              color: Colors.yellow,
                            ),
                          ),
                          onPressed: () {
                            sendCommand('ST');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    _buildTopCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          "LINE FOLLOWING",
                          style: GoogleFonts.electrolize(
                            fontSize: 25.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildTopCard1(
                        child: Hero(
                          tag: 'logo',
                          child: SizedBox(
                            height: 50,
                            child: Image.asset('images/logo.png'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                    clipBehavior: Clip.antiAlias,
                    child: Hero(
                      tag: 'line_follower',
                      child: Image.asset(
                        'images/line_follower.jpeg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                RoundedButton1(
                  colors: isRunning ? Colors.red : Colors.green,
                  text_color: Colors.white,
                  text: isRunning ? "STOP" : "START",
                  onPressed: _toggleStartStop,
                  length: 16,
                  width: 300,
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildTopCard1({required Widget child}) {
    return Card(
      color: Colors.black54,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: child,
      ),
    );
  }
}
