// main.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for Clipboard
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

// ML Kit
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// === FCM bootstrap (use your actual file name) ===
import 'notification.dart'; // contains initLocalNotifications(), initFcmAndGetToken()

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initLocalNotifications();
  final token = await initFcmAndGetToken();
  debugPrint('App started. Token: $token');
  runApp(MyApp(fcmToken: token));
}

class MyApp extends StatelessWidget {
  final String? fcmToken;
  const MyApp({super.key, required this.fcmToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kindacode.com',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(fcmToken: fcmToken),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? fcmToken;
  const HomePage({super.key, required this.fcmToken});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Face detection via ML Kit (on-device)
  Future<int> _detectFaces(String imagePath) async {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: false,
      enableLandmarks: false,
      minFaceSize: 0.1,
    );
    final detector = FaceDetector(options: options);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final faces = await detector.processImage(input);
      return faces.length;
    } finally {
      await detector.close();
    }
  }

  // Pick -> detect -> snackbar -> upload -> refresh
  Future<void> _pickDetectUpload(String source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
      );

      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected or operation cancelled')),
        );
        return;
      }

      // 1) Face detection
      final int faceCount = await _detectFaces(picked.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            faceCount > 0 ? 'Detected $faceCount face(s)' : 'No faces detected',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // 2) Upload to Firebase Storage (under "uploads/")
      final fileName = path.basename(picked.path);
      final file = File(picked.path);
      await storage.ref('uploads/$fileName').putFile(
        file,
        SettableMetadata(
          customMetadata: {
            'picture': fileName,
            'description': 'faceCount: $faceCount',
          },
        ),
      );

      // 3) Refresh
      if (mounted) setState(() {});
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  // Load all images under "uploads/"
  Future<List<Map<String, dynamic>>> _loadImages() async {
    final List<Map<String, dynamic>> files = [];
    final ListResult result = await storage.ref('uploads').listAll();
    for (final file in result.items) {
      final url = await file.getDownloadURL();
      final meta = await file.getMetadata();
      files.add({
        'url': url,
        'path': file.fullPath,
        'uploaded_by': meta.customMetadata?['uploaded_by'] ?? 'Unknown',
        'description': meta.customMetadata?['description'] ?? '',
      });
    }
    return files;
  }

  Future<void> _delete(String fullPath) async {
    await storage.ref(fullPath).delete();
    if (mounted) setState(() {});
  }

  void _copyToken() {
    final token = widget.fcmToken ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No FCM token yet')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FCM token copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenShort = (widget.fcmToken ?? '').isEmpty
        ? 'No token'
        : '${widget.fcmToken!.substring(0, 12)}...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kindacode.com'),
        actions: [
          IconButton(
            tooltip: 'Copy FCM token',
            onPressed: _copyToken,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Small token hint line (helpful for console sending)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FCM: $tokenShort',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickDetectUpload('camera'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickDetectUpload('gallery'),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadImages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No images found'));
                  }
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final img = data[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          leading: Image.network(
                            img['url'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                          title: Text(img['uploaded_by']),
                          subtitle: Text(img['description']),
                          trailing: IconButton(
                            onPressed: () => _delete(img['path']),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
