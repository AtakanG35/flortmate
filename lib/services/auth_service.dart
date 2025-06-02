import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> registerWithEmail(String email, String password, {String? name}) async {
    UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;

    if (user != null && name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
      user = _firebaseAuth.currentUser;
    }

    return user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
