import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  late final Stream<User?> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _authStateChanges = _auth.authStateChanges();

    // Oturum durumu değiştiğinde kullanıcı güncellemesi ve login yönlendirme
    _authStateChanges.listen((user) {
      if (user == null) {
        // Oturum kapandıysa login sayfasına yönlendir
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        // Kullanıcı değiştiyse state güncelle
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    // Oturum kapandığında yukarıdaki listener yönlendirecek
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      // Oturum açmamışsa boş ve yükleniyor göstergesi
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoşgeldiniz,', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _currentUser?.displayName?.isNotEmpty == true
                  ? _currentUser!.displayName!
                  : _currentUser?.email ?? 'Kullanıcı',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hesap Bilgileri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_currentUser?.email ?? 'Email bilgisi yok'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _currentUser?.emailVerified == true
                              ? Icons.verified_user
                              : Icons.error_outline,
                          color: _currentUser?.emailVerified == true ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentUser?.emailVerified == true
                                ? 'Email doğrulandı'
                                : 'Email doğrulanmadı',
                            style: TextStyle(
                              color:
                                  _currentUser?.emailVerified == true ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // İleride eklenebilecek özellikler için bilgi mesajı
            const Center(
              child: Text(
                'Diğer özellikler yakında eklenecek...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
