import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Kullanıcı oturumu yoksa login sayfasına yönlendirebilirsin
      // Navigator.of(context).pushReplacementNamed('/login');
      return Scaffold(
        body: Center(
          child: Text(
            'Kullanıcı bulunamadı. Lütfen giriş yapınız.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoş Geldin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Başarıyla çıkış yapıldı.')),
              );
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Veri alınırken hata oluştu: ${snapshot.error}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Profil bilgileri bulunamadı.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return Center(
              child: Text(
                'Profil verileri boş.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(data['fullName'] ?? 'Bilgi yok'),
                    subtitle: const Text('İsim Soyisim'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cake),
                    title: Text('${data['age'] ?? 'Bilgi yok'}'),
                    subtitle: const Text('Yaş'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(data['city'] ?? 'Bilgi yok'),
                    subtitle: const Text('Şehir'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.wc),
                    title: Text(data['gender'] ?? 'Bilgi yok'),
                    subtitle: const Text('Cinsiyet'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(data['email'] ?? 'Bilgi yok'),
                    subtitle: const Text('E-posta'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
