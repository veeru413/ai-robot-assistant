import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robozido/Rounded_Buttons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robozido/manual.dart';
import 'package:robozido/obs_avoider.dart';
import 'package:robozido/line_follower.dart';
import 'package:robozido/gesture_enabled.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:robozido/voice_enabled.dart';

class Modes extends StatefulWidget {
  static const String id = "modes";

  @override
  State<Modes> createState() => _ModesState();
}

class _ModesState extends State<Modes> {
  WebSocketChannel? channel;
  int _clickCount = 0;
  String mode = 'ST';
  bool isManualModeActive = false;
  bool isLineFollowerModeActive = false;
  bool isObstacleAvoidanceModeActive = false;
  String serverUrl = 'ws://192.168.4.1:81';
  String ssid = "Connecting...";

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    // _fetchSSID();
    // _listenToConnectivityChanges();
  }

  Future<String?> fetchWifiSSID() async {
    PermissionStatus locationStatus = await Permission.location.request();
    PermissionStatus wifiStatus = await Permission.nearbyWifiDevices.request();

    if (locationStatus.isGranted && wifiStatus.isGranted) {
      try {
        final wifiName = await NetworkInfo().getWifiName();
        return wifiName ?? "No SSID found";
      } catch (e) {
        return "Failed to get SSID: $e";
      }
    } else {
      return "Permissions not granted";
    }
  }

  Future<void> _fetchSSID() async {
    String? fetchedSsid = await fetchWifiSSID();
    setState(() {
      ssid = fetchedSsid ?? "Disconnected!";
    });
  }


  Future<void> sendCommand(String command) async {
    if (channel != null) {
      channel?.sink.add(command);
      print('Command sent: $command');
      channel?.stream.listen((response) {
        print('Received from server: $response');
      });
    } else {
      print('WebSocket channel is not connected');
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

  void _resetClickCount() {
    setState(() {
      _clickCount = 0;
    });
  }

  void _onModesTextClicked() {
    setState(() {
      _clickCount++;
    });
    if (_clickCount >= 10) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EasterEggPage(
            resetClickCount: _resetClickCount,
          ),
        ),
      );
    }
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
                      child: Card(
                        color: Colors.black54,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
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
                      ),
                    ),
                    _buildTopCard(
                      child: GestureDetector(
                        onTap: _onModesTextClicked,
                        child: Padding(
                          padding: EdgeInsets.only(left: 45, right: 45),
                          child: Text(
                            "MODES",
                            style: GoogleFonts.electrolize(
                              fontSize: 28.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
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
                SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Column(
                        children: [
                          // _buildConnectionStatusCard(),
                          DiagonalCard(
                            imagePath: 'images/manual.jpeg',
                            text: 'Manual Mode',
                            onTap: () {
                              HapticFeedback.vibrate();
                              sendCommand('m');
                              Navigator.pushNamed(context, Manual.id);
                            },
                            heroTag: 'manual',
                          ),
                          DiagonalCard(
                            imagePath: 'images/obs_avoiding.jpeg',
                            text: 'Obstacle Avoider',
                            onTap: () {
                              HapticFeedback.vibrate();
                              Navigator.pushNamed(context, ObsAvoider.id);
                            },
                            heroTag: 'obstacle',
                          ),
                          DiagonalCard(
                            imagePath: 'images/line_follower.jpeg',
                            text: 'Line Follower',
                            onTap: () {
                              HapticFeedback.vibrate();
                              Navigator.pushNamed(context, LineFollower.id);
                            },
                            heroTag: 'line_follower',
                          ),
                          DiagonalCard(
                            imagePath: 'images/gesture.jpeg',
                            text: 'Gesture Controlled',
                            onTap: () {
                              HapticFeedback.vibrate();
                              Navigator.pushNamed(context, GestureEnabled.id);
                            },
                            heroTag: 'gesture_mode',
                          ),
                          DiagonalCard(
                            imagePath: 'images/voice.jpeg',
                            text: 'Ai Voice Mode',
                            onTap: () {
                              HapticFeedback.vibrate();
                              Navigator.pushNamed(context, VoiceEnabled.id);
                            },
                            heroTag: 'voice_enable',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildConnectionStatusCard() {
  //   return Card(
  //     color: Colors.black54,
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(10.0),
  //       child: Center(
  //         child: Text(
  //           ssid == "Disconnected!" ? "Disconnected!" : "Connected to $ssid",
  //           style: GoogleFonts.lexend(
  //             fontSize: 18.0,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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

void _showConfirmationDialog1(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Center(
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
                  'Are you sure you wanna Exit?',
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
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class EasterEggPage extends StatelessWidget {
  final VoidCallback resetClickCount;

  const EasterEggPage({Key? key, required this.resetClickCount})
      : super(key: key);

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
          Center(
            child: Card(
              color: Colors.black.withOpacity(0.8),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      style: TextStyle(
                        fontFamily: 'Cursive',
                        fontSize: 40.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      duration: Duration(milliseconds: 150),
                      child: Text('EASTER EGG🥚'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Hey, there! 🌟\n\nI’m Veerendra, the sole creator of this app, and congratulations on finding the Easter egg! 🙌\n\nYour discovery truly reflects the passion and love you have for this app, and it fills me with joy. 💛\n\nJust keep loving ROBOCELL and this app, and with that, it’s me signing off. 🚀\n\n#ROBOCELL27 Created with love ~ 20th Dec 2024 ✨',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        resetClickCount();
                        Navigator.pop(context);
                      },
                      child: Text("Go Back", style: TextStyle(fontSize: 18.0)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalCard extends StatelessWidget {
  final String imagePath;
  final String text;
  final VoidCallback onTap;
  final String heroTag;

  const DiagonalCard({
    Key? key,
    required this.imagePath,
    required this.text,
    required this.onTap,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            ClipPath(
              clipper: DiagonalClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Hero(
              tag: heroTag,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: GoogleFonts.lexend(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
