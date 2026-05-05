import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Joker Marketi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Altın Bakiyesi Paneli
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 48),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MEVCUT ALTIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
                        Text('${provider.gold}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Kullanılabilir Jokerler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent.shade100)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _jokerShopItem(context, provider, 'balik', 'Balık', 
                    'Gridde rastgele olarak harfleri yok etmektedir. Rastgele yok olan harflerin üzerindeki harfler aşağıya düşmektedir.', 
                    'Stratejik alan temizliği.', 'Otomatik (Anında)', 100, Icons.set_meal, Colors.blueAccent),
                  
                  _jokerShopItem(context, provider, 'tekerlek', 'Tekerlek', 
                    'Gridde seçilen harfin bulunduğu satır ve sütundaki tüm harfler yok olmaktadır.', 
                    'Satır ve sütun temizleme.', 'Hedef harfe tıklayarak kullanılır.', 200, Icons.radio_button_checked, Colors.pinkAccent),
                  
                  _jokerShopItem(context, provider, 'lolipop', 'Lolipop Kırıcı', 
                    'Gridde seçilen bir harfi yok etmek için kullanılmaktadır. Bu harf yok olduğunda yukarısındaki kelimeler aşağıya düşmektedir.', 
                    'Tekli hedef yok etme.', 'Hedef harfe tıklayarak kullanılır.', 75, Icons.icecream, Colors.purpleAccent),
                  
                  _jokerShopItem(context, provider, 'degistirme', 'Serbest Değiştirme', 
                    'Gridde birbirine temas eden iki harfin yer değiştirilmesini sağlamaktadır.', 
                    'Harf yerlerini optimize etme.', 'İki komşu harfe sırayla tıklanır.', 125, Icons.swap_horiz, Colors.redAccent),
                  
                  _jokerShopItem(context, provider, 'karistirma', 'Harf Karıştırma', 
                    'Bu özellik seçildiğinde gridde bulunan harflerin rastgele bir şekilde karıştırılmasını sağlamaktadır.', 
                    'Gridi yeniden düzenleme.', 'Otomatik (Anında)', 300, Icons.blur_on, Colors.greenAccent),
                  
                  _jokerShopItem(context, provider, 'parti', 'Parti Güçlendiricisi', 
                    'Bu özellik seçildiğinde gridde bulunan tüm harfler yok edilir ve tekrardan rastgele bir şekilde harfler yukarıdan aşağıya düşmektedir.', 
                    'Tüm gridi yenileme.', 'Otomatik (Anında)', 400, Icons.auto_awesome, Colors.indigoAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jokerShopItem(BuildContext context, GameProvider provider, String id, String name, String desc, String purpose, String usage, int price, IconData icon, Color color) {
    bool canAfford = provider.gold >= price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color.withOpacity(0.9))),
          subtitle: Text('$price Altın', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          trailing: ElevatedButton(
            onPressed: canAfford ? () {
                provider.buyJoker(id, price);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$name satın alındı!'), 
                  backgroundColor: Colors.green,
                  duration: const Duration(milliseconds: 1000),
                ));
              } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? Colors.green.shade600 : Colors.grey.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SATIN AL'),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  _infoRow(Icons.description, 'Açıklama:', desc),
                  _infoRow(Icons.lightbulb, 'Amaç:', purpose),
                  _infoRow(Icons.touch_app, 'Kullanım:', usage),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                children: [
                  TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: " $value"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
