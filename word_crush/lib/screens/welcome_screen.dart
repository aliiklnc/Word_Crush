import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import 'menu_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Lütfen bir kullanıcı adı girin');
      return;
    }
    if (name.length < 2) {
      setState(() => _errorText = 'En az 2 karakter olmalı');
      return;
    }

    final provider = context.read<GameProvider>();
    provider.updateUserName(name);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Başlık
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'WORD CRUSH',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelime Patlatma Oyunu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // İsim Giriş Kartı
                      GlassCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const Text(
                              'Hoş Geldiniz!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Oyuna başlamak için kullanıcı adınızı girin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'Kullanıcı Adı',
                                hintStyle:
                                    TextStyle(color: Colors.white.withOpacity(0.4)),
                                errorText: _errorText,
                                errorStyle: const TextStyle(color: Colors.orangeAccent),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: Colors.white.withOpacity(0.6)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Colors.white54, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF4A148C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'BAŞLA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
