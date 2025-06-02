import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flortmate/services/profile_setup_page.dart';
import 'package:flortmate/widgets/message_generator_page.dart';
import 'package:flortmate/models/user_profile.dart';
import 'package:flortmate/screens/profile_page.dart';
import 'pages/discover_page.dart';
import 'services/auth_page.dart';
import 'pages/chat_page.dart';
import 'photo_picker_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FlortMateApp());
}

class FlortMateApp extends StatefulWidget {
  const FlortMateApp({Key? key}) : super(key: key);

  @override
  State<FlortMateApp> createState() => _FlortMateAppState();
}

class _FlortMateAppState extends State<FlortMateApp> {
  String _language = 'tr';

  void toggleLanguage() {
    setState(() {
      _language = _language == 'tr' ? 'en' : 'tr';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlörtMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: AuthWrapper(
        language: _language,
        onLanguageToggle: toggleLanguage,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/discover':
            return MaterialPageRoute(builder: (_) => DiscoverPage());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfilePage()); // const kaldırıldı
          case '/message_generator':
            return MaterialPageRoute(
              builder: (_) => MessageGeneratorPage(
                language: _language,
                premiumUser: false,
                onPremiumToggle: () {},
              ),
            );
          case '/photo_picker':
            return MaterialPageRoute(builder: (_) => PhotoPickerExample()); // const kaldırıldı
          default:
            return null;
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final String language;
  final VoidCallback onLanguageToggle;

  const AuthWrapper({
    Key? key,
    required this.language,
    required this.onLanguageToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FlortMateHome(
            user: snapshot.data!,
            language: language,
            onLanguageToggle: onLanguageToggle,
          );
        }

        return AuthPage(
          language: language,
          onLanguageToggle: onLanguageToggle,
        );
      },
    );
  }
}

class FlortMateHome extends StatefulWidget {
  final User user;
  final String language;
  final VoidCallback onLanguageToggle;

  const FlortMateHome({
    Key? key,
    required this.user,
    required this.language,
    required this.onLanguageToggle,
  }) : super(key: key);

  @override
  State<FlortMateHome> createState() => _FlortMateHomeState();
}

class _FlortMateHomeState extends State<FlortMateHome> {
  bool premiumUser = false;
  bool isLoadingPremiumStatus = true;

  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _initWidgetOptions();
    _fetchUserDataAndRedirectIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FlortMateHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initWidgetOptions();
  }

  void _initWidgetOptions() {
    _widgetOptions = <Widget>[
      MessageGeneratorPage(
        language: widget.language,
        premiumUser: premiumUser,
        onPremiumToggle: togglePremium,
      ),
      DiscoverPage(),
      ProfilePage(), // const kaldırıldı
    ];
  }

  Future<void> _fetchUserDataAndRedirectIfNeeded() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        final hasProfile = data != null &&
            data.containsKey('name') &&
            (data['name'] as String).isNotEmpty;

        if (!hasProfile) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ProfileSetupPage(user: widget.user),
              ),
            );
            return;
          }
        }

        if (data != null && data.containsKey('premium')) {
          setState(() {
            premiumUser = data['premium'] == true;
            _initWidgetOptions();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPremiumStatus = false;
        });
      }
    }
  }

  Future<void> updatePremiumStatus(bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'premium': newStatus});
      setState(() {
        premiumUser = newStatus;
        _initWidgetOptions();
      });
    } catch (e) {
      debugPrint('Error updating premium status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'tr'
                  ? 'Premium durumu güncellenemedi.'
                  : 'Failed to update premium status.',
            ),
          ),
        );
      }
    }
  }

  void togglePremium() async {
    final newStatus = !premiumUser;
    await updatePremiumStatus(newStatus);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingPremiumStatus) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlörtMate'),
        actions: [
          // Çıkış butonu kaldırıldı
          IconButton(
            icon: const Icon(Icons.language),
            tooltip:
                widget.language == 'tr' ? 'Dil değiştir' : 'Change Language',
            onPressed: widget.onLanguageToggle,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.message),
            label: widget.language == 'tr' ? 'Mesajlar' : 'Messages',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: widget.language == 'tr' ? 'Keşfet' : 'Discover',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.language == 'tr' ? 'Profil' : 'Profile',
          ),
        ],
      ),
    );
  }
}
