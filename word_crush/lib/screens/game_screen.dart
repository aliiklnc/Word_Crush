import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class GameScreen extends StatefulWidget {
  final int gridSize;
  final int moves;

  const GameScreen({super.key, this.gridSize = 8, this.moves = 25});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isLoading = true;
  final List<GlobalKey> _cellKeys = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _initGame();
    }
  }

  Future<void> _initGame() async {
    try {
      final provider = context.read<GameProvider>();
      await provider.init();
      provider.initializeGame(widget.gridSize, widget.moves);
      _cellKeys.clear();
      for (int i = 0; i < provider.gridSize * provider.gridSize; i++) {
        _cellKeys.add(GlobalKey());
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Oyun başlatma hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, GameProvider provider) {
    if (provider.isGameOver) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    for (int i = 0; i < _cellKeys.length; i++) {
      final key = _cellKeys[i];
      final RenderBox? cellBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (cellBox == null) continue;

      final cellPosition = cellBox.localToGlobal(Offset.zero);
      final cellSize = cellBox.size;
      final cellRect = Rect.fromLTWH(
        cellPosition.dx,
        cellPosition.dy,
        cellSize.width,
        cellSize.height,
      );

      if (cellRect.contains(details.globalPosition)) {
        int r = i ~/ provider.gridSize;
        int c = i % provider.gridSize;
        provider.onCellTap(r, c);
        break;
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final provider = context.watch<GameProvider>();

    // Hamle bittiyse otomatik olarak ana menüye yönlendir (biraz gecikmeli)
    if (provider.isGameOver) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitDialog(context, provider);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Word Crush', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitDialog(context, provider),
          ),

        ),
        extendBodyBehindAppBar: true,
        body: GradientBackground(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 48), // AppBar padding
                  _buildTopPanel(provider),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Gridde Oluşturulabilir Kelime Sayısı: ${provider.possibleWordCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: provider.possibleWordCount > 0
                            ? Colors.white70
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: _buildGrid(provider)),
                  _buildBottomPanel(provider),
                ],
              ),
              if (provider.isGameOver) _buildGameOverOverlay(provider),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oyundan Çık'),
        content: const Text('Çıkmak istediğinize emin misiniz? Mevcut puanınız kaydedilecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HAYIR')),
          ElevatedButton(
            onPressed: () async {
              await provider.saveGameResult();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('EVET, ÇIK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(GameProvider provider) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassCard(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 100),
                const SizedBox(height: 24),
                const Text('OYUN BİTTİ!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text('Toplam Skor', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                Text('${provider.score}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Colors.purpleAccent),
                const SizedBox(height: 16),
                const Text('Ana menüye yönlendiriliyor...', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel(GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statBox('SKOR', '${provider.score}', Colors.blueAccent, Icons.star),
            _statBox('HAMLE', '${provider.movesLeft}', Colors.orangeAccent, Icons.touch_app),
            _statBox('ALTIN', '${provider.gold}', Colors.amberAccent, Icons.monetization_on),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _buildGrid(GameProvider provider) {
    if (provider.grid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    double fontSize = provider.gridSize >= 10 ? 24.0 : 32.0;
    double pointsSize = provider.gridSize >= 10 ? 12.0 : 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          return Center(
            child: SizedBox(
              width: size,
              height: size,
              child: GestureDetector(
                onPanUpdate: (details) => _onPanUpdate(details, provider),
                onPanEnd: (_) => provider.submitWord(),
                child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: provider.gridSize,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: provider.gridSize * provider.gridSize,
          itemBuilder: (context, index) {
            int r = index ~/ provider.gridSize;
            int c = index % provider.gridSize;
            var cell = provider.grid[r][c];

            // Hücre içeriği widget'ı
            Widget cellContent = AnimatedContainer(
              key: _cellKeys[index],
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: cell.letter == ""
                    ? Colors.transparent
                    : (cell.isExploding
                        ? Colors.red.shade400
                        : (cell.isSelected
                            ? const Color(0xFF7B1FA2)
                            : (cell.specialPower != null
                                ? _getPowerColor(cell.specialPower!)
                                : Colors.white))),
                borderRadius:
                    BorderRadius.circular(cell.letter == "" ? 20 : 8),
                border: cell.letter == ""
                    ? null
                    : Border.all(
                        color: cell.isExploding
                            ? Colors.red.shade700
                            : (cell.isSelected
                                ? const Color(0xFF4A148C)
                                : Colors.grey.shade300),
                        width: cell.isSelected ? 2.5 : 1.5,
                      ),
                boxShadow: cell.letter == ""
                    ? null
                    : (cell.isExploding
                        ? [
                            BoxShadow(
                                color: Colors.red.shade300,
                                blurRadius: 12,
                                spreadRadius: 2)
                          ]
                        : (cell.isSelected
                            ? [
                                BoxShadow(
                                    color: Colors.purple.shade200,
                                    blurRadius: 8,
                                    spreadRadius: 1)
                              ]
                            : [
                                const BoxShadow(
                                    color: Colors.black12, blurRadius: 2)
                              ])),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cell.letter,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: cell.isExploding
                                    ? Colors.white
                                    : (cell.isSelected ||
                                            cell.specialPower != null
                                        ? Colors.white
                                        : Colors.black87),
                                shadows: cell.specialPower != null
                                    ? const [
                                        Shadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                            offset: Offset(1, 1))
                                      ]
                                    : null,
                              ),
                            ),
                            if (cell.letter != "")
                              Text(
                                '${cell.points}',
                                style: TextStyle(
                                  fontSize: pointsSize,
                                  color: cell.isExploding
                                      ? Colors.white70
                                      : (cell.isSelected ||
                                              cell.specialPower != null
                                          ? Colors.white70
                                          : Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Köşe İkonu
                  if (cell.specialPower != null && cell.letter != "")
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        _getPowerIcon(cell.specialPower!),
                        size: pointsSize - 2,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            );

            // Patlatma animasyonu: küçülme + saydamlaşma
            if (cell.isExploding) {
              cellContent = AnimatedScale(
                scale: 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInBack,
                child: AnimatedOpacity(
                  opacity: 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: cellContent,
                ),
              );
            }

            // Düşme animasyonu: yukarıdan kayma
            if (cell.isDropping) {
              cellContent = TweenAnimationBuilder<Offset>(
                tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
                duration: const Duration(milliseconds: 350),
                curve: Curves.bounceOut,
                builder: (context, offset, child) {
                  return FractionalTranslation(
                    translation: offset,
                    child: child,
                  );
                },
                child: cellContent,
              );
            }

            return GestureDetector(
              onTapDown: (_) => provider.onCellTap(r, c),
              child: cellContent,
            );
          },
        ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildBottomPanel(GameProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0845).withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.purpleAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _jokerButton(
                    provider, 'balik', 'Balık', Icons.set_meal, Colors.blue),
                _jokerButton(provider, 'tekerlek', 'Tekerlek',
                    Icons.radio_button_checked, Colors.pink),
                _jokerButton(
                    provider, 'lolipop', 'Lolipop', Icons.icecream, Colors.purple),
                _jokerButton(provider, 'degistirme', 'Değiştirme',
                    Icons.back_hand, Colors.red),
                _jokerButton(provider, 'karistirma', 'Karıştır', Icons.blur_on,
                    Colors.green),
                _jokerButton(provider, 'parti', 'Parti', Icons.auto_awesome,
                    Colors.indigo),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('SEÇİLEN KELİME',
              style: TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 2)),
          const SizedBox(height: 1),
          Text(
            provider.currentWord.isEmpty ? '-' : provider.currentWord,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 10)],
            ),
          ),
          // Sabit yükseklik, böylece kelime bulununca alt panel genişleyip ızgarayı küçültmez
          SizedBox(
            height: 36,
            child: provider.lastComboWords.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥 ${provider.lastComboCount}x Combo!',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.orangeAccent,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: provider.lastComboWords
                                  .map((word) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orangeAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            '+$word',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orangeAccent),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: provider.currentWord.length >= 3 &&
                        !provider.isProcessing &&
                        !provider.isGameOver
                    ? () => provider.submitWord()
                    : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('ONAYLA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: provider.currentWord.isNotEmpty &&
                        !provider.isProcessing &&
                        !provider.isGameOver
                    ? () => provider.cancelSelection()
                    : null,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('İPTAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jokerButton(
      GameProvider provider, String id, String name, IconData icon, Color color) {
    int count = provider.jokers[id] ?? 0;
    bool hasAny = count > 0;
    bool isActive = provider.activeJoker == id;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Column(
        children: [
          GestureDetector(
            onTap: hasAny
                ? () {
                    provider.selectJoker(id);
                    if (id == 'lolipop' || id == 'tekerlek') {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$name: Lütfen grid üzerinde bir harf seçin!'),
                          backgroundColor: color, duration: const Duration(milliseconds: 1500)));
                    } else if (id == 'degistirme') {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$name: Yer değiştirmek için iki komşu harfe sırayla tıklayın!'),
                          backgroundColor: color, duration: const Duration(milliseconds: 1500)));
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.3)
                    : (hasAny ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Colors.white
                      : (hasAny ? color.withOpacity(0.5) : Colors.white12),
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : null,
              ),
              child: Icon(icon,
                  color: hasAny ? color : Colors.white24, size: 20),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: hasAny ? color.withOpacity(0.2) : Colors.white12,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hasAny ? color.withOpacity(0.5) : Colors.transparent),
            ),
            child: Text('x$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasAny ? Colors.white : Colors.white54)),
          ),
        ],
      ),
    );
  }
  Color _getPowerColor(String power) {
    switch (power) {
      case 'row': return Colors.purple.shade600;
      case 'column': return Colors.blue.shade600;
      case 'area': return Colors.orange.shade700;
      case 'mega': return Colors.red.shade800;
      default: return Colors.white;
    }
  }



  IconData _getPowerIcon(String power) {
    switch (power) {
      case 'row': return Icons.swap_horiz;
      case 'column': return Icons.swap_vert;
      case 'area': return Icons.vignette;
      case 'mega': return Icons.auto_awesome;
      default: return Icons.flash_on;
    }
  }
}
