import 'package:flutter/material.dart';

void main() => runApp(const NameJapApp());

class NameJapApp extends StatelessWidget {
  const NameJapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name Jap',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const Scaffold(
        body: Center(
          child: Text('🙏 राधे राधे', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
