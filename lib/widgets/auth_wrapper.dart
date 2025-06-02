import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flortmate/screens/home_screen.dart';
import 'package:flortmate/screens/login_page.dart';
import 'package:flortmate/screens/register_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            // Kullanıcı giriş yapmamış, Giriş/Kayıt sayfasına yönlendir
            return const AuthPage();
          } else {
            // Kullanıcı giriş yapmış, ana sayfaya git
            return const HomeScreen();
          }
        }

        // Bağlantı henüz aktif değilse yükleniyor göstergesi göster
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Giriş ve Kayıt sayfaları arasında geçiş yapan basit bir sayfa
class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  void toggle() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showLogin
        ? LoginPage(onRegisterClicked: toggle)   // <-- Burada LoginPage parametre alıyor
        : RegisterPage(onLoginClicked: toggle);  // <-- Burada RegisterPage parametre alıyor
  }
}
