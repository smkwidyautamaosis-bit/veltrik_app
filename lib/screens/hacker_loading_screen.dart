import 'dart:async';
import 'package:flutter/material.dart';
import 'smart_material_screen.dart';

class HackerLoadingScreen extends StatefulWidget {
  final String subject;
  
  const HackerLoadingScreen({super.key, required this.subject});

  @override
  State<HackerLoadingScreen> createState() => _HackerLoadingScreenState();
}

class _HackerLoadingScreenState extends State<HackerLoadingScreen> {
  final List<String> _logs = [];
  Timer? _timer;
  int _step = 0;

  final List<Map<String, dynamic>> _script = [
    {"text": "[SYSTEM]: Accessing Veltrik Secure Database...", "color": Colors.blueAccent, "delay": 800},
    {"text": "[AUTH]: Bypassing teacher's encryption...", "color": Colors.yellowAccent, "delay": 1200},
    {"text": ">> Handshake established with server.", "color": Colors.white70, "delay": 600},
    {"text": ">> Downloading smart material packages...", "color": Colors.white70, "delay": 900},
    {"text": ">> Compiling interactive nodes...", "color": Colors.white70, "delay": 800},
    {"text": "[SUCCESS]: Material successfully decrypted.", "color": Colors.greenAccent, "delay": 1200},
  ];

  @override
  void initState() {
    super.initState();
    _startHackingSequence();
  }

  void _startHackingSequence() async {
    for (var line in _script) {
      await Future.delayed(Duration(milliseconds: line['delay']));
      if (!mounted) return;
      setState(() {
        _logs.add(line['text']);
      });
    }

    // Wait an extra second before navigating
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Fade Transition to SmartMaterialScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SmartMaterialScreen(subject: widget.subject),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Gelap biar terasa kodingan sejati
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: Colors.blueAccent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "VELTRIK OVERRIDE",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final text = _logs[index];
                    Color textColor = Colors.white;
                    if (text.contains("[SYSTEM]")) textColor = Colors.blueAccent;
                    if (text.contains("[AUTH]")) textColor = Colors.yellowAccent;
                    if (text.contains("[SUCCESS]")) textColor = Colors.greenAccent;
                    if (text.startsWith(">>")) textColor = Colors.white70;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'Courier', // font koding (monospace generic fallback)
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
