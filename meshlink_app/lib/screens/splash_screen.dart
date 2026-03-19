import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget home;
  const SplashScreen({super.key, required this.home});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _glowController.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      _fadeController.forward().then((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => widget.home,
              transitionDuration: Duration.zero,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: const Color(0xFF050508),
        body: Center(
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withValues(alpha: 0.3 * _glowAnim.value),
                            const Color(0xFFE53935).withValues(alpha: 0.08 * _glowAnim.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          radius: 1.5 + (_glowAnim.value * 0.5),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.4 * _glowAnim.value),
                                blurRadius: 32 * _glowAnim.value,
                                spreadRadius: 8 * _glowAnim.value,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32 * _glowAnim.value),
                  Opacity(
                    opacity: _glowAnim.value,
                    child: const Text(
                      'FLAREGUN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: (_glowAnim.value * 0.5).clamp(0.0, 1.0),
                    child: Text(
                      'MESH COMMUNICATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
