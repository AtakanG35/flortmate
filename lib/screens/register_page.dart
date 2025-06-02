import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onLoginClicked;  // <-- Eklendi

  const RegisterPage({Key? key, required this.onLoginClicked}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String fullName = '';
  String city = '';
  String gender = 'Male';
  int? age;

  bool isLoading = false;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': fullName,
        'age': age,
        'city': city,
        'gender': gender,
        'email': email,
        'premium': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarılı! Hoş geldiniz, $fullName'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Kayıt başarılı, ana sayfaya yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Kayıt sırasında hata oluştu'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) => email = value.trim(),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Geçerli bir email giriniz';
                  }
                  return null;
                },
              ),

              // Parola
              TextFormField(
                decoration: const InputDecoration(labelText: 'Parola'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: (value) => password = value.trim(),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Parola en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),

              // İsim Soyisim
              TextFormField(
                decoration: const InputDecoration(labelText: 'İsim Soyisim'),
                textInputAction: TextInputAction.next,
                onChanged: (value) => fullName = value.trim(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İsim Soyisim boş bırakılamaz';
                  }
                  return null;
                },
              ),

              // Yaş
              TextFormField(
                decoration: const InputDecoration(labelText: 'Yaş'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onChanged: (value) => age = int.tryParse(value),
                validator: (value) {
                  int? parsed = int.tryParse(value ?? '');
                  if (parsed == null) {
                    return 'Yaş giriniz';
                  }
                  if (parsed < 13) {
                    return 'Yaş 13\'ten büyük olmalı';
                  }
                  return null;
                },
              ),

              // Şehir
              TextFormField(
                decoration: const InputDecoration(labelText: 'Şehir'),
                textInputAction: TextInputAction.next,
                onChanged: (value) => city = value.trim(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şehir boş bırakılamaz';
                  }
                  return null;
                },
              ),

              // Cinsiyet
              DropdownButtonFormField<String>(
                value: gender,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    gender = value ?? 'Male';
                  });
                },
                decoration: const InputDecoration(labelText: 'Cinsiyet'),
              ),

              const SizedBox(height: 20),

              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: isLoading ? null : register,
                      child: const Text('Kayıt Ol'),
                    ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: widget.onLoginClicked,  // <-- Toggle fonksiyonu buraya çağrılır
                child: const Text('Zaten hesabınız var mı? Giriş Yapın'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
