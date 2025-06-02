import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flortmate/pages/chat_page.dart';

class MatchesPage extends StatefulWidget {
  @override
  _MatchesPageState createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<String> matches = [];

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  void fetchMatches() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    if (doc.exists) {
      setState(() {
        matches = List<String>.from(doc['matches'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eşleşmelerim'),
      ),
      body: matches.isEmpty
          ? Center(child: Text('Henüz eşleşmen yok.'))
          : ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final matchedUserId = matches[index];
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(matchedUserId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return ListTile(title: Text('Yükleniyor...'));

              final userDoc = snapshot.data!;
              final name = userDoc['name'] ?? 'İsim yok';
              final photoUrl = userDoc['photoUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? Icon(Icons.person) : null,
                ),
                title: Text(name),
                trailing: Icon(Icons.chat),
                onTap: () {
                  // Burada sohbet sayfasına yönlendirme olacak
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        matchedUserId: matchedUserId,
                        matchedUserName: name,
                        matchedUserPhotoUrl: photoUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
