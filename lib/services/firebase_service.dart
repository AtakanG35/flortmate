import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart'; // UserProfile sınıfını içe aktar (dosya yoluna göre ayarla)

Future<void> updateUserProfile(String userId, UserProfile profile) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(profile.toMap(), SetOptions(merge: true));
    print('Kullanıcı profili başarıyla güncellendi.');
  } catch (e) {
    print('Firestore güncelleme hatası: $e');
  }
}
