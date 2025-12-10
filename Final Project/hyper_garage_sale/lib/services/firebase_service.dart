import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseService {
  /// Stream all posts, newest first.
  static Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream a single post document (for viewsCount etc.)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> postStream(
      String postId,
      ) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots();
  }

  /// Create a new post with optional images and optional location.
  static Future<void> createPost({
    required String title,
    required String price,
    required String description,
    required List<XFile> images,
    double? latitude,
    double? longitude,
    String? meetupAddress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final sellerName =
        user?.displayName ?? user?.email ?? user?.uid ?? 'Unknown seller';

    final storage = FirebaseStorage.instance;
    final List<String> imageUrls = [];

    for (final img in images) {
      final file = File(img.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${img.name}';

      final ref = storage.ref().child('posts').child(fileName);
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      imageUrls.add(url);
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'title': title,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'sellerName': sellerName,
      'userId': user?.uid,
      'viewsCount': 0,
      'meetupLat': latitude,
      'meetupLng': longitude,
      'meetupAddress': meetupAddress,
    });
  }

  /// Increment views count when opening detail page.
  static Future<void> incrementPostView(String postId) async {
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await docRef.update({
      'viewsCount': FieldValue.increment(1),
    });
  }

  /// Stream comments belonging to a specific post.
  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
      String postId,
      ) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Add a comment to a post.
  /// Guest / anonymous users are blocked here.
  static Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    // Block guest / anonymous users
    if (user == null || user.isAnonymous) {
      throw Exception('Guest users cannot post comments.');
    }

    final authorName =
        user.displayName ?? user.email ?? user.uid ?? 'Unknown user';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'text': text,
      'authorName': authorName,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
