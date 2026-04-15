import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  const PremiumScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: title != null
          ? AppBar(
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              leading: leading,
              title: Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              actions: actions,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0F22), // Deep Indigo
              Color(0xFF000000), // True Black
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle Radial Glow di tengah
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -50,
              right: -50,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            SafeArea(child: body),
          ],
        ),
      ),
    );
  }
}
