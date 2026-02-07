import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'Rounded_Buttons.dart';
import 'package:flutter/services.dart';

class Manual extends StatefulWidget {
  static const String id = "manual";

  @override
  State<Manual> createState() => _ManualState();
}

class _ManualState extends State<Manual> {
  String serverUrl = 'ws://192.168.4.1:81';
  WebSocketChannel? channel;
  String mode = 'ST';
  bool isForward = false;
  bool isBackward = false;
  bool isLeft = false;
  bool isRight = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    channel = WebSocketChannel.connect(Uri.parse(serverUrl));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    channel?.sink.close();
    super.dispose();
  }

  bool isRunning = false;
  bool isRunning1 = false;

  void _toggleStartStop() {
    setState(() {
      HapticFeedback.vibrate();
      isRunning = !isRunning;

      if (isRunning) {
        sendCommand('ON');
      } else {
        sendCommand('OFF');
      }
    });
  }

  void _toggleStartStop1() {
    setState(() {
      HapticFeedback.vibrate();
      isRunning1 = !isRunning1;

      if (isRunning1) {
        sendCommand('Rotate');
      } else {
        sendCommand('ST1');
      }
    });
  }

  double servoAngle = 90.0;
  String directionLeft = "None";
  String directionRight = "None";
  Offset _leftJoystickPosition = Offset(0, 0);
  Offset _rightJoystickPosition = Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: .87, // Set the opacity level (0.0 to 1.0)
            child: Image.asset(
              'images/background_image.jpeg',
              fit: BoxFit.fitWidth,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopCard1(
                    child: IconButton(
                      icon: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159),
                        // Flips the icon horizontally
                        child: const Icon(
                          Icons.logout,
                          color: Colors.yellow,
                        ),
                      ),
                      onPressed: () {
                        _showConfirmationDialog1(context);
                      },
                    ),
                  ),
                  _buildTopCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 100),
                      child: Text(
                        "MANUAL CONTROL",
                        style: GoogleFonts.electrolize(
                          fontSize: 28.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildTopCard1(
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
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildJoystick(
                        label: "",
                        direction: directionLeft,
                        isVertical: true,
                        onDragUpdate: (offset) {
                          setState(() {
                            HapticFeedback.vibrate();
                            _leftJoystickPosition = Offset(0, offset.dy);
                            directionLeft =
                                _getDirection(_leftJoystickPosition, true);
                            sendCommand(directionLeft);
                          });
                        },
                        onDragEnd: () {
                          setState(() {
                            directionLeft = "None";
                            _leftJoystickPosition = Offset.zero;
                          });
                          sendCommand('ST1');
                        },
                      ),
                    ),
                    _buildServoControl(),
                    Expanded(
                      child: _buildJoystick(
                        label: "",
                        direction: directionRight,
                        isVertical: false,
                        onDragUpdate: (offset) {
                          setState(() {
                            HapticFeedback.vibrate();
                            _rightJoystickPosition = Offset(offset.dx, 0);
                            directionRight =
                                _getDirection(_rightJoystickPosition, false);
                            toggleMode(directionRight);
                          });
                        },
                        onDragEnd: () {
                          setState(() {
                            directionRight = "None";
                            _rightJoystickPosition = Offset.zero;
                          });
                          toggleMode('ST1');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void sendCommand(String command) {
    if (channel != null) {
      channel?.sink.add(command);
      //print('Command sent: $command');
    }
  }

  void toggleMode(String selectedMode) {
    setState(() {
      mode = selectedMode;
      isForward = selectedMode == 'Forward';
      isBackward = selectedMode == 'Backward';
      isLeft = selectedMode == 'Left';
      isRight = selectedMode == 'Right';
    });
    sendCommand(selectedMode);
  }

  void _showConfirmationDialog1(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 100, right: 100),
            child: Card(
              color: Colors.grey[800]?.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                      'Are you sure you wanna Exit Manual Mode?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            text_color: Colors.black,
                          ),
                        ),
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

  Widget _buildServoControl() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            sendCommand('U');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            minimumSize: const Size(40, 60),
          ),
          child: Icon(Icons.keyboard_arrow_up, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Text(
              "Robotic Arm",
              style: GoogleFonts.electrolize(
                fontSize: 35.0,
                color: Colors.yellow,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            sendCommand('D');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            minimumSize: const Size(40, 60),
          ),
          child: Icon(Icons.keyboard_arrow_down, size: 40, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildJoystick({
    required String label,
    required String direction,
    required bool isVertical,
    required Function(Offset) onDragUpdate,
    required VoidCallback onDragEnd,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          direction,
          style: GoogleFonts.electrolize(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
            ),
            Positioned(
              top: isVertical ? 0 : 85,
              bottom: isVertical ? 0 : 85,
              left: isVertical ? 85 : 0,
              right: isVertical ? 85 : 0,
              child: Container(
                width: isVertical ? 20 : null,
                height: isVertical ? null : 20,
                color: Colors.grey.shade800,
              ),
            ),
            GestureDetector(
              onPanUpdate: (details) {
                Offset localPosition = details.localPosition - Offset(100, 100);
                onDragUpdate(localPosition);
              },
              onPanEnd: (_) {
                onDragEnd();
              },
              child: Container(
                height: 200,
                width: 200,
                color: Colors.transparent,
                child: CustomPaint(
                  painter: JoystickPainter(
                    offset: direction == "None"
                        ? Offset(0, 0)
                        : direction == "Forward"
                            ? Offset(0, -80)
                            : direction == "Backward"
                                ? Offset(0, 80)
                                : direction == "Left"
                                    ? Offset(-80, 0)
                                    : Offset(80, 0),
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.electrolize(
            color: Colors.yellow,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getDirection(Offset offset, bool isVertical) {
    if (isVertical) {
      if (offset.dy < -20) {
        return "Forward";
      } else if (offset.dy > 20) {
        return "Backward";
      }
    } else {
      if (offset.dx > 20) {
        return "Right";
      } else if (offset.dx < -20) {
        return "Left";
      }
    }
    return "None";
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

class JoystickPainter extends CustomPainter {
  final Offset offset;

  JoystickPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 6;
    canvas.drawCircle(
      Offset(size.width / 2 + offset.dx, size.height / 2 + offset.dy),
      20,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
