import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/mesh_provider.dart';
import 'screens/chat_list_screen.dart';
import 'screens/peers_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/channel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
    ),
  );

  final mesh = MeshProvider();
  await mesh.init();

  runApp(
    ChangeNotifierProvider.value(
      value: mesh,
      child: const FlareGunApp(),
    ),
  );
}

class FlareGunApp extends StatelessWidget {
  const FlareGunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlareGun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE53935),
          secondary: Color(0xFFFF5252),
          surface: Color(0xFF141418),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141418),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: Color(0xFFE53935),
          unselectedItemColor: Color(0xFF4A4A4E),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.3),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    ChatListScreen(),
    ChannelListScreen(),
    PeersScreen(),
    AIScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded, size: 22), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded, size: 22), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.radar_rounded, size: 22), label: 'Mesh'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome, size: 22), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_rounded, size: 22), label: 'Settings'),
        ],
      ),
    );
  }
}
