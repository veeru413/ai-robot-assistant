import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'Rounded_Buttons.dart';

class GestureEnabled extends StatefulWidget {
  static const String id = "gesture_enabled";

  @override
  State<GestureEnabled> createState() => _GestureEnabledState();
}

class _GestureEnabledState extends State<GestureEnabled> {
  String serverUrl = 'ws://192.168.4.1:81';
  WebSocketChannel? channel;
  double dx = 0, dy = 0; // Movement directions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final double sensitivityThreshold = 1.5;
  bool isListening = false; // To manage accelerometer state

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    channel = WebSocketChannel.connect(Uri.parse(serverUrl));
  }

  void sendCommand(String command) {
    if (channel != null) {
      channel!.sink.add(command);
      //print('Command sent: $command');
    } else {
      print('Error: WebSocket not connected');
    }
  }

  void _startAccelerometerListener() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      if (!mounted) return;

      setState(() {
        if (event.x.abs() > sensitivityThreshold) {
          dy = event.x > 0 ? 1 : -1; // Forward-backward (x axis)
        } else {
          dy = 0;
        }

        if (event.y.abs() > sensitivityThreshold) {
          dx = event.y > 0 ? -1 : 1; // Left-right (y axis)
        } else {
          dx = 0;
        }
      });

      if (dx == 0 && dy == 0) {
        sendCommand('ST1');
      } else if (dy == 1) {
        sendCommand('Backward');
        HapticFeedback.vibrate();
      } else if (dy == -1) {
        sendCommand('Forward');
        HapticFeedback.vibrate();
      } else if (dx == -1) {
        sendCommand('Right');
        HapticFeedback.vibrate();
      } else if (dx == 1) {
        sendCommand('Left');
        HapticFeedback.vibrate();
      }
    });
  }

  void _stopAccelerometerListener() {
    _accelerometerSubscription?.cancel();
    setState(() {
      dx = 0;
      dy = 0;
    });
    sendCommand('ST'); // Stop the robot when listener stops
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String movementDirection = '';
    if (dy == 1) {
      movementDirection = 'BACKWARD';
    } else if (dy == -1) {
      movementDirection = 'FORWARD';
    } else if (dx == 1) {
      movementDirection = 'LEFT';
    } else if (dx == -1) {
      movementDirection = 'RIGHT';
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/background_image.jpeg',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopCard1(
                    child: IconButton(
                      icon: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159), // Flips the icon horizontally
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
                      padding: const EdgeInsets.only(left: 30, right: 30),
                      child: Text(
                        "GESTURE CONTROL",
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
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: isListening
                      ? Text(
                          movementDirection,
                          style: GoogleFonts.electrolize(
                            fontSize: 80.0,
                            color: Colors.yellow,
                            letterSpacing: 2.0,
                          ),
                        )
                      : Text(
                          "Press Start to Begin",
                          style: GoogleFonts.electrolize(
                            fontSize: 60.0,
                            color: Colors.green,
                            letterSpacing: 2.0,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isListening) {
                            isListening = false;
                            _stopAccelerometerListener();
                          } else {
                            isListening = true;
                            sendCommand('g');
                            _startAccelerometerListener();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isListening ? Colors.red : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 100),
                      ),
                      child: Text(
                        isListening ? 'STOP' : 'START',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
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
                      'Are you sure you wanna Exit Gesture Mode?',
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
                              sendCommand('ST');
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
