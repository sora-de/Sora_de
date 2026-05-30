import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataMigrationService {
  static Future<void> migrateOldDataToTopLevel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(uid);
    
    // The collections we need to copy to the top level
    final collections = ['inventory', 'gift_orders', 'revenues', 'expenses'];
    
    for (final colName in collections) {
      final snap = await userRef.collection(colName).get();
      for (final doc in snap.docs) {
        // Write each document to the top-level collection with the same ID
        await db.collection(colName).doc(doc.id).set(doc.data(), SetOptions(merge: true));
      }
    }
  }
}
