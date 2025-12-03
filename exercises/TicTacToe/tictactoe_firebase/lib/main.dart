import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'screens/sign_in_screen.dart';

import 'screens/main_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(TicTacToeApp());

}


class TicTacToeApp extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Tic Tac Toe',

      theme: ThemeData(

        primarySwatch: Colors.blue,

        visualDensity: VisualDensity.adaptivePlatformDensity,

      ),

      home: StreamBuilder<User?>(

        stream: FirebaseAuth.instance.authStateChanges(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {

            return Center(child: CircularProgressIndicator());

          }

          if (snapshot.hasData) {

            return MainScreen();

          }

          return SignInScreen();

        },

      ),

    );

  }

}