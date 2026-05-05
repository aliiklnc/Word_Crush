import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import 'score_screen.dart';
import 'market_screen.dart';
import 'setup_screen.dart';

/// Akıcı sayfa geçişi için özel route
Route _createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      _nameController.text = provider.userName;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showNameEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0845),
        title: const Text('Kullanıcı Adı Değiştir',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Yeni isim girin',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İPTAL',
                  style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                context
                    .read<GameProvider>()
                    .updateUserName(_nameController.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent),
            child: const Text('KAYDET',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // PDF: Sol üstte kullanıcı adı (tıklanabilir)
            Positioned(
              top: 10,
              left: 16,
              child: GestureDetector(
                onTap: _showNameEditDialog,
                child: Row(
                  children: [
                    const Icon(Icons.person_pin,
                        color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      provider.userName.isEmpty
                          ? "İsim Girin"
                          : provider.userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 30),
                        hasBorder: true,
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.purpleAccent
                                        .withValues(alpha: 0.5),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.purpleAccent
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5)
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset('assets/images/logo.png',
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'WORD\nCRUSH',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                  height: 1.1),
                            ),
                            const SizedBox(height: 12),
                            Text('Kelime Patlatma Oyunu',
                                style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Premium Butonlar
                      _buildPremiumButton(
                        'YENİ OYUN',
                        'Maceraya başla!',
                        Icons.play_circle_fill,
                        [const Color(0xFF00C853), const Color(0xFF1B5E20)],
                        0,
                        () => Navigator.push(
                            context, _createRoute(const GameSetupScreen())),
                      ),
                      _buildPremiumButton(
                        'SKOR TABLOSU',
                        'Geçmiş performansın',
                        Icons.emoji_events,
                        [const Color(0xFF2979FF), const Color(0xFF0D47A1)],
                        1,
                        () => Navigator.push(
                            context, _createRoute(const ScoreScreen())),
                      ),
                      _buildPremiumButton(
                        'MARKET',
                        'Joker satın al',
                        Icons.storefront,
                        [const Color(0xFFFF6D00), const Color(0xFFE65100)],
                        2,
                        () => Navigator.push(
                            context, _createRoute(const MarketScreen())),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton(String title, String subtitle, IconData icon,
      List<Color> colors, int index, VoidCallback onPressed) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            splashColor: colors[0].withValues(alpha: 0.3),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    colors[0].withValues(alpha: 0.25),
                    colors[1].withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: colors[0].withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors[0].withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colors[0].withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(icon, color: colors[0], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.4), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
