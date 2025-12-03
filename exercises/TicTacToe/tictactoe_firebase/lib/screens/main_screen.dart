import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'game_list_screen.dart';
import 'leaderboard_list_screen.dart';

class MainScreen extends StatelessWidget {

  Future<void> _signOut(BuildContext context) async {

    try {

      await GoogleSignIn().signOut();

      await FirebaseAuth.instance.signOut();

      // No need to navigate, auth state change will handle it

    } catch (e) {

      ScaffoldMessenger.of(

        context,

      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));

    }

  }


  @override

  Widget build(BuildContext context) {

    return DefaultTabController(

      length: 2,

      child: Scaffold(

        appBar: AppBar(

          title: Text('Tic Tac Toe'),

          bottom: TabBar(tabs: [Tab(text: 'Games'), Tab(text: 'Leaderboard')]),

          actions: [

            IconButton(

              icon: Icon(Icons.logout),

              onPressed: () => _signOut(context),

            ),

          ],

        ),

        // LeaderboardListScreen to be implemented later

        body: TabBarView(children: [GameListScreen(), LeaderboardListScreen()]),

      ),

    );

  }

}