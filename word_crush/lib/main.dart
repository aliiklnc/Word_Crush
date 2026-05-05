import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/game_provider.dart';
import 'screens/menu_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameProvider = GameProvider();
  await gameProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: gameProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return MaterialApp(
      title: 'Word Crush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A), // Deep Purple
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: provider.userName.isEmpty
          ? const WelcomeScreen()
          : const MenuScreen(),
    );
  }
}
