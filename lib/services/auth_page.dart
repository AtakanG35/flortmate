import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/profile_page.dart';

class AuthPage extends StatefulWidget {
  final String language;
  final VoidCallback onLanguageToggle;

  const AuthPage({
    Key? key,
    required this.language,
    required this.onLanguageToggle,
  }) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String _errorMessage = '';

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    try {
      User? user;
      if (_isLoginMode) {
        user = await _authService.signInWithEmail(email, password);
      } else {
        user = await _authService.registerWithEmail(email, password, name: name);
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String errorCode) {
    final tr = widget.language == 'tr';
    switch (errorCode) {
      case 'user-not-found':
        return tr ? 'Kullanıcı bulunamadı.' : 'User not found.';
      case 'wrong-password':
        return tr ? 'Yanlış parola girdiniz.' : 'Wrong password.';
      case 'email-already-in-use':
        return tr ? 'Bu email zaten kullanılıyor.' : 'Email is already in use.';
      case 'invalid-email':
        return tr ? 'Geçersiz email adresi.' : 'Invalid email address.';
      case 'weak-password':
        return tr ? 'Parola çok zayıf.' : 'Password is too weak.';
      default:
        return tr ? 'Bir hata oluştu.' : 'An error occurred.';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: widget.language == 'tr' ? 'İsim' : 'Name',
      ),
      validator: (value) {
        if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
          return widget.language == 'tr' ? 'İsim giriniz' : 'Please enter name';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$");
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: widget.language == 'tr' ? 'Email' : 'Email address',
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.language == 'tr' ? 'Email giriniz' : 'Please enter email';
        }
        if (!emailRegex.hasMatch(value)) {
          return widget.language == 'tr' ? 'Geçerli bir email giriniz' : 'Enter a valid email';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: widget.language == 'tr' ? 'Parola' : 'Password',
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.language == 'tr' ? 'Parola giriniz' : 'Please enter password';
        }
        if (value.length < 6) {
          return widget.language == 'tr'
              ? 'Parola en az 6 karakter olmalı'
              : 'Password must be at least 6 characters';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _isLoading ? null : _submit(),
    );
  }

  Widget _buildErrorText() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _errorMessage,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoginMode
              ? (widget.language == 'tr' ? 'Giriş Yap' : 'Log In')
              : (widget.language == 'tr' ? 'Kayıt Ol' : 'Sign Up'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: widget.language == 'tr' ? 'Dili Değiştir' : 'Change Language',
            onPressed: widget.onLanguageToggle,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLoginMode) _buildNameField(),
                  if (!_isLoginMode) const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(_isLoginMode
                          ? (widget.language == 'tr' ? 'Giriş Yap' : 'Log In')
                          : (widget.language == 'tr' ? 'Kayıt Ol' : 'Sign Up')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleAuthMode,
                    child: Text(
                      _isLoginMode
                          ? (widget.language == 'tr'
                          ? 'Hesabınız yok mu? Kayıt olun'
                          : 'Don\'t have an account? Sign up')
                          : (widget.language == 'tr'
                          ? 'Zaten hesabınız var mı? Giriş yapın'
                          : 'Already have an account? Log in'),
                    ),
                  ),
                  _buildErrorText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
