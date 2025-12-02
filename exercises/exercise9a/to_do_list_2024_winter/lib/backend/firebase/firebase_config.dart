import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
      if (kIsWeb) {
      await Firebase.initializeApp(options: FirebaseOptions(
    apiKey: "AIzaSyC50JMG_msE6dAMV_fH8WBPWR6NhM-0Fkk",
      authDomain: "neu-winter2024.firebaseapp.com",
      projectId: "neu-winter2024",
      storageBucket: "neu-winter2024.appspot.com",
      messagingSenderId: "715129016837",
      appId: "1:715129016837:web:e77c43155d3541eebcc26c",
      measurementId: "G-TZH078223G"
    ));
    } else {
      await Firebase.initializeApp();
    }
  
}
