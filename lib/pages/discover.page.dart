  import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// MatchesPage dosyasını import et
import 'matches_page.dart';

class DiscoverPage extends StatefulWidget {
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<String> likedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchLikedUsers();
  }

  void fetchLikedUsers() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    if (doc.exists) {
      setState(() {
        likedUsers = List<String>.from(doc.data()?['likedUsers'] ?? []);
      });
    }
  }

  Future<void> likeUser(String likedUserId) async {
    if (likedUsers.contains(likedUserId)) return;

    setState(() {
      likedUsers.add(likedUserId);
    });

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final likedUserRef = FirebaseFirestore.instance.collection('users').doc(likedUserId);

    await userRef.update({
      'likedUsers': FieldValue.arrayUnion([likedUserId])
    });

    final likedUserSnap = await likedUserRef.get();
    final likedUserLikes = List<String>.from(likedUserSnap.data()?['likedUsers'] ?? []);

    if (likedUserLikes.contains(currentUserId)) {
      // Karşılıklı beğeni → Eşleşme
      await userRef.update({
        'matches': FieldValue.arrayUnion([likedUserId])
      });

      await likedUserRef.update({
        'matches': FieldValue.arrayUnion([currentUserId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Eşleşme! Artık mesajlaşabilirsiniz.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keşfet'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            tooltip: 'Eşleşmeler',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MatchesPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isNotEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final uid = user.id;
              final name = user['name'] ?? 'İsim yok';
              final photoUrl = user['photoUrl'];

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? Icon(Icons.person) : null,
                  ),
                  title: Text(name),
                  trailing: ElevatedButton.icon(
                    onPressed: () => likeUser(uid),
                    icon: Icon(
                      likedUsers.contains(uid) ? Icons.check : Icons.favorite_border,
                      color: likedUsers.contains(uid) ? Colors.green : Colors.red,
                    ),
                    label: Text(likedUsers.contains(uid) ? 'Beğenildi' : 'Beğen'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
