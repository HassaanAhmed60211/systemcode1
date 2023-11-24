import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  final db = FirebaseFirestore.instance;
  String username = '';
  storeData() {}

  User? user = FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot>? userStream;

  UserProvider() {
    if (user != null) {
      userStream = db.collection('user').doc(user!.uid).snapshots();
    }
  }

  String currentUser = '';

  void setUser(String user) {
    currentUser = user;
    notifyListeners();
  }
}
