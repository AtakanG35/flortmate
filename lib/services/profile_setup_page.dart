import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// UserProfile modeli (tam senin projenin yapısına göre)
class UserProfile {
  final String name;
  final int age;
  final String city;
  final String gender;

  UserProfile({
    required this.name,
    required this.age,
    required this.city,
    required this.gender,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      age: (map['age'] is int)
          ? map['age']
          : int.tryParse(map['age'].toString()) ?? 0,
      city: map['city'] ?? '',
      gender: map['gender'] ?? 'Erkek',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'city': city,
      'gender': gender,
    };
  }
}

class ProfileSetupPage extends StatefulWidget {
  final User user;

  const ProfileSetupPage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String _gender = 'Erkek';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final profile = UserProfile.fromMap(data);
        setState(() {
          _nameController.text = profile.name;
          _ageController.text = profile.age.toString();
          _cityController.text = profile.city;
          _gender = profile.gender;
        });
      }
    } catch (e) {
      debugPrint('Profil yükleme hatası: $e');
      // İstersen kullanıcıya da gösterebilirsin
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      city: _cityController.text.trim(),
      gender: _gender,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(profile.toMap(), SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla kaydedildi")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilini Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Adınız'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ad girin' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Yaşınız'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Yaş girin';
                  final age = int.tryParse(value);
                  if (age == null || age <= 0 || age > 120) {
                    return 'Geçerli bir yaş girin';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Şehir'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Şehir girin' : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: ['Erkek', 'Kadın', 'Diğer']
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value ?? 'Erkek'),
                decoration: const InputDecoration(labelText: 'Cinsiyet'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _submitProfile,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anasayfa')),
      body: const Center(child: Text('Hoşgeldiniz!')),
    );
  }
}
