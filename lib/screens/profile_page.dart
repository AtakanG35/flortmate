import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../models/badge.dart';
import '../widgets/badge_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  User? user;
  bool _isLoading = false;

  File? _profileImageFile;
  String? _profileImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String? _gender;

  String? _originalName;
  String? _originalAge;
  String? _originalCity;
  String? _originalAbout;
  String? _originalGender;

  bool _isEditing = false;

  static const List<String> genderOptions = ['Erkek', 'Kadın', 'Diğer'];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // Profil fotoğraf widget'ı, düzenleme modunda kamera simgesi ve seçeneklerle
  Widget _buildProfileImage() {
    const double size = 120;
    Widget imageWidget;

    if (_profileImageFile != null) {
      imageWidget = ClipOval(
        child: Image.file(
          _profileImageFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageWidget = ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }

    return Stack(
      children: [
        imageWidget,
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 20,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onSelected: (value) {
                  if (value == 'upload') {
                    _pickImage();
                  } else if (value == 'remove') {
                    _removeImage();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'upload',
                    child: Text('Fotoğraf Yükle'),
                  ),
                  if ((_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || _profileImageFile != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Fotoğrafı Sil'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Profil kartında gösterilecek her bilgi için okunabilir alan
  Widget _buildProfileInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // Düzenlenebilir form alanları
  Widget _buildEditableForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'İsim'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'İsim boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Yaş'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Yaş boş olamaz';
              }
              if (int.tryParse(value) == null) {
                return 'Geçerli bir sayı giriniz';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Şehir'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Şehir boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: genderOptions.contains(_gender) ? _gender : null,
            items: genderOptions
                .map((gender) => DropdownMenuItem(
              value: gender,
              child: Text(gender),
            ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _gender = val;
              });
            },
            decoration: const InputDecoration(labelText: 'Cinsiyet'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cinsiyet seçmelisiniz';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _aboutController,
            decoration: const InputDecoration(labelText: 'Hakkında'),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Hakkında kısmı boş olamaz';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Profil kart (okunabilir mod)
  Widget _buildProfileCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileInfoItem('İsim', _nameController.text),
            _buildProfileInfoItem('Yaş', _ageController.text),
            _buildProfileInfoItem('Şehir', _cityController.text),
            _buildProfileInfoItem('Cinsiyet', _gender),
            _buildProfileInfoItem('Hakkında', _aboutController.text),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 20),
            _isEditing ? _buildEditableForm() : _buildProfileCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isEditing)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: _saveProfile,
                  ),
                if (_isEditing)
                  const SizedBox(width: 20),
                if (_isEditing)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('İptal'),
                    onPressed: _cancelEditing,
                  ),
                if (!_isEditing)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzenle'),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Profil verilerini Firestore'dan çek ve controllerlara ata
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _profileImageUrl = data['photoUrl'] ?? '';
        _nameController.text = data['name'] ?? '';
        _ageController.text = (data['age']?.toString() ?? '');
        _cityController.text = data['city'] ?? '';
        _aboutController.text = data['about'] ?? '';
        _gender = data['gender'] ?? '';

        // Orijinal değerleri tut
        _originalName = _nameController.text;
        _originalAge = _ageController.text;
        _originalCity = _cityController.text;
        _originalAbout = _aboutController.text;
        _originalGender = _gender;
      }
    } catch (e) {
      debugPrint('Profil yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil bilgileri yüklenemedi')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dosya seçici ile fotoğraf seç
  Future<void> _pickImage() async {
    final typeGroup = XTypeGroup(
      label: 'image',
      extensions: ['jpg', 'jpeg', 'png'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    setState(() {
      _profileImageFile = File(file.path);
    });
  }

  // Fotoğrafı Firestore ve Storage'dan kaldır
  Future<void> _removeImage() async {
    setState(() {
      _profileImageFile = null;
      _profileImageUrl = null;
    });

    if (user == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}');
      await ref.delete();
    } catch (e) {
      // Fotoğraf yoksa ya da hata varsa yok say
    }
  }

  // Profili kaydet (Firestore ve Storage)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedImageUrl = _profileImageUrl;

      if (_profileImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}');
        await ref.putFile(_profileImageFile!);
        uploadedImageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'city': _cityController.text.trim(),
        'about': _aboutController.text.trim(),
        'gender': _gender,
        'photoUrl': uploadedImageUrl ?? '',
      }, SetOptions(merge: true));

      // Orijinal değerleri güncelle
      _originalName = _nameController.text;
      _originalAge = _ageController.text;
      _originalCity = _cityController.text;
      _originalAbout = _aboutController.text;
      _originalGender = _gender;
      _profileImageUrl = uploadedImageUrl;

      setState(() {
        _isEditing = false;
        _profileImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
    } catch (e) {
      debugPrint('Profil kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellenirken hata oluştu')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Düzenleme iptal edilince orijinal değerlere geri dön
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = _originalName ?? '';
      _ageController.text = _originalAge ?? '';
      _cityController.text = _originalCity ?? '';
      _aboutController.text = _originalAbout ?? '';
      _gender = _originalGender;
      _profileImageFile = null;
    });
  }
}
