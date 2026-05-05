import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final history = provider.gameHistory.where((e) => e.playerName == provider.userName).toList();

    int totalGames = history.length;
    int highestScore = history.isEmpty ? 0 : history.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    double avgScore = history.isEmpty ? 0 : history.map((e) => e.score).reduce((a, b) => a + b) / totalGames;
    int totalWords = history.isEmpty ? 0 : history.map((e) => e.wordCount).reduce((a, b) => a + b);
    String longestWord = history.isEmpty ? "-" : history.reduce((a, b) => a.longestWord.length > b.longestWord.length ? a : b).longestWord;
    
    int totalSec = history.isEmpty ? 0 : history.map((e) => e.durationSeconds).reduce((a, b) => a + b);
    String totalDurationStr = _formatTotalDuration(totalSec);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Skor Tablosu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(context, provider),
              tooltip: 'Geçmişi Temizle',
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 80),
            // PDF: Özet Alanı
            _buildSummaryArea(totalGames, highestScore, avgScore, totalWords, longestWord, totalDurationStr),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('GEÇMİŞ OYUNLAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purpleAccent.shade100, letterSpacing: 1.2)),
            ),

            Expanded(
              child: history.isEmpty 
                ? const Center(child: Text('Henüz oynanmış oyun yok.', style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    itemCount: history.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return _buildGameCard(record);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTotalDuration(int totalSeconds) {
    if (totalSeconds == 0) return "0 dk";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String res = "";
    if (hours > 0) res += "$hours saat ";
    if (minutes > 0) res += "$minutes dakika ";
    if (hours == 0 && minutes == 0) res += "$seconds saniye";
    return res.trim();
  }

  Widget _buildSummaryArea(int games, int highest, double avg, int words, String longest, String duration) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GENEL PERFORMANS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
            const SizedBox(height: 15),
            _summaryRow('Toplam Oynanan Oyun', '$games', Icons.videogame_asset_outlined),
            _summaryRow('En Yüksek Puan', '$highest', Icons.emoji_events_outlined),
            _summaryRow('Ortalama Puan', avg.toStringAsFixed(1), Icons.analytics_outlined),
            _summaryRow('Bulunan Toplam Kelime', '$words', Icons.text_snippet_outlined),
            _summaryRow('En Uzun Kelime', longest, Icons.straighten_outlined),
            _summaryRow('Toplam Oyun Süresi', duration, Icons.timer_outlined),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Oyun #${record.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                Text(record.date, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _cardStat('Grid', record.gridSize),
                _cardStat('Puan', '${record.score}'),
                _cardStat('Kelime', '${record.wordCount}'),
                _cardStat('Süre', record.duration),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_outline, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                Text('En Uzun Kelime: ${record.longestWord}', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showClearDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0845),
        title: const Text('Geçmişi Temizle', style: TextStyle(color: Colors.white)),
        content: const Text('Tüm oyun geçmişi silinecek. Onaylıyor musunuz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçmiş silindi!'), backgroundColor: Colors.purple));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('SİL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
