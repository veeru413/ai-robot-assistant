import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robozido/line_follower.dart';
import 'package:robozido/manual.dart';
import 'package:robozido/modes.dart';
import 'package:robozido/obs_avoider.dart';
import 'package:robozido/gesture_enabled.dart';
import 'package:robozido/voice_enabled.dart';
import 'Rounded_Buttons.dart';

void main() {
  runApp(RoboCellApp());
}
class RoboCellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        Modes.id: (context) => Modes(),
        Manual.id: (context) => Manual(),
        ObsAvoider.id: (context) => ObsAvoider(),
        LineFollower.id: (context) => LineFollower(),
        GestureEnabled.id: (context) => GestureEnabled(),
        VoiceEnabled.id: (context) => VoiceEnabled(),
      },
    );
  }
}
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool _popupDisplayed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  static const colorizeColors = [
    Colors.white,
    Colors.black,
    Colors.grey,
  ];
  static const colorizeTextStyle = TextStyle(
    fontSize: 35.0,
    fontWeight: FontWeight.w900,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'images/background_image.jpeg',
              fit: BoxFit.cover,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 120, // Slightly bigger for space for border
                  backgroundColor: Colors.transparent, // Border color
                  child: CircleAvatar(
                    radius: 110, // Inner circle (actual logo)
                    backgroundColor: Colors.transparent, // Background inside, optional
                    backgroundImage: AssetImage('images/logo.png'),
                    child: Hero(
                      tag: 'logo',
                      child: Container(), // Empty because backgroundImage is used
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                AnimatedTextKit(
                  animatedTexts: [
                    ColorizeAnimatedText(
                      'ROBOZIDO',
                      textStyle: colorizeTextStyle,
                      colors: colorizeColors,
                    ),
                  ],
                  isRepeatingAnimation: true,
                ),
                const SizedBox(height: 40),
                // Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.shade700.withOpacity(0.7),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_popupDisplayed) {
                        setState(() {
                          _popupDisplayed = true;
                        });
                        _showConfirmationDialog1(context);
                      } else {
                        Navigator.pushNamed(context, Modes.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(300),
                      ),
                      backgroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Let's Get Started",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  'Important',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Make sure you are connected to NODEMCU before proceeding.',
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
                        width: 25,
                        length: 16,
                        text: 'Okay',
                        colors: Colors.yellow,
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, Modes.id);
                        },
                        text_color: Colors.black,
                      ),
                    ),
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
