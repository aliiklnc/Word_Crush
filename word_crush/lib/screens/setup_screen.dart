import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _selectedGridSize = 8;
  int _currentStep = 0; // 0: Grid Seçimi, 1: Zorluk Seçimi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yeni Oyun', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildStepIndicator(),
            const SizedBox(height: 40),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0 ? _buildGridSelection() : _buildDifficultySelection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(0, 'Grid Boyutu'),
        Container(width: 50, height: 2, color: _currentStep == 1 ? Colors.purpleAccent : Colors.white24),
        _stepCircle(1, 'Zorluk Seviyesi'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    bool isActive = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.purpleAccent : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? Colors.purpleAccent : Colors.white30, width: 2),
            boxShadow: isActive ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.6), blurRadius: 15)] : null,
          ),
          child: Center(
            child: Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.white : Colors.white70)),
      ],
    );
  }

  Widget _buildGridSelection() {
    return Column(
      key: const ValueKey(0),
      children: [
        const Text('Oyun alanı büyüklüğünü seçin:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 30),
        _selectionButton('10x10 Grid', 'Kolay Seviye', 10, Icons.grid_on, Colors.greenAccent),
        _selectionButton('8x8 Grid', 'Orta Seviye', 8, Icons.grid_view, Colors.orangeAccent),
        _selectionButton('6x6 Grid', 'Zor Seviye', 6, Icons.grid_3x3, Colors.redAccent),
      ],
    );
  }

  Widget _buildDifficultySelection() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text('Zorluk ve Hamle sayısını seçin:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 30),
        _difficultyButton('Kolay Level', '25 Hamle', 25, Icons.sentiment_satisfied, Colors.greenAccent),
        _difficultyButton('Orta Level', '20 Hamle', 20, Icons.sentiment_neutral, Colors.orangeAccent),
        _difficultyButton('Zor Level', '15 Hamle', 15, Icons.sentiment_very_dissatisfied, Colors.redAccent),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => setState(() => _currentStep = 0),
          icon: const Icon(Icons.arrow_back, color: Colors.purpleAccent),
          label: const Text('Geri Dön', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _selectionButton(String title, String subtitle, int size, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGridSize = size;
            _currentStep = 1;
          });
        },
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyButton(String title, String subtitle, int moves, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(gridSize: _selectedGridSize, moves: moves)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Icon(Icons.play_circle_fill, size: 36, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
