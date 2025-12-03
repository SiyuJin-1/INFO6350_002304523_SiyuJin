import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'game_board_screen.dart';


import 'dart:developer' as developer; // For detailed logging


// Convert to StatefulWidget

class GameListScreen extends StatefulWidget {

  @override

  _GameListScreenState createState() => _GameListScreenState();

}


class _GameListScreenState extends State<GameListScreen> {

  User? _currentUser; // Cache current user


  @override

  void initState() {

    super.initState();

    _currentUser = FirebaseAuth.instance.currentUser; // Get user once

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text('Tic-Tac-Toe Games')),

      // Use a Column to stack Active and Completed sections

      body: Column(

        children: [

          // --- Section 1: Active and Waiting Games ---

          Expanded(

            // Use Expanded to make this section fill the space above Completed

            child: _buildActiveGamesList(),

          ),

          // --- Divider ---

          Divider(height: 1.5, thickness: 1.5, color: Colors.grey[400]),

          // --- Section 2: Completed Games (Expandable) ---

          _buildCompletedGamesSection(),


        ],

      ),

      floatingActionButton: FloatingActionButton(

        onPressed: () => _createNewGame(context),

        tooltip: 'Create New Game',

        child: Icon(Icons.add),

      ),

    );

  }


  // Widget to build the list of Active/Waiting games

  Widget _buildActiveGamesList() {

    return StreamBuilder<QuerySnapshot>(

      stream:

      FirebaseFirestore.instance

          .collection('games')

          .where('status', whereIn: ['active', 'waiting'])

          .orderBy('createdAt', descending: true)

          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {

          return Center(child: CircularProgressIndicator());

        }

        if (snapshot.hasError) {

          print('Firestore Stream Error (Active): ${snapshot.error}');

          return Center(child: Text('Error loading active games.'));

        }

        final docs = snapshot.data?.docs;

        if (docs == null || docs.isEmpty) {

          return Center(child: Text('No active or waiting games found.'));

        }


        // This ListView can scroll because it's inside Expanded

        return ListView.builder(

          itemCount: docs.length,

          itemBuilder: (context, index) {

            return _buildActiveGameTile(context, docs[index]);

          },

        );

      },

    );

  }


  // Builds the full expandable Completed Games Section

  Widget _buildCompletedGamesSection() {

    return ExpansionTile(

      title: _buildCompletedGamesHeader(),

      controlAffinity: ListTileControlAffinity.leading,

      initiallyExpanded: false,

      tilePadding: EdgeInsets.zero,

      childrenPadding: EdgeInsets.zero,

      backgroundColor: Colors.white,

      collapsedBackgroundColor: Colors.blueGrey[50],

      children: <Widget>[_buildCompletedGamesListInsideExpansion()],

    );

  }


  Widget _buildCompletedGamesHeader() {

    // Requires current user to filter count

    final userId = _currentUser?.uid;

    if (userId == null) {

      // Handle case where user might somehow be null here

      return _buildHeaderContent('Completed Games', null);

    }


    // StreamBuilder specifically for the COUNT

    return StreamBuilder<QuerySnapshot>(

      // Query ALL completed games for counting purposes

      stream:

      FirebaseFirestore.instance

          .collection('games')

          .where('status', isEqualTo: 'completed')

      // No ordering needed for count, but add if required by Firestore rules/index later

          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {

          developer.log(

            "Error fetching completed games for count: ${snapshot.error}",

            name: "GameListScreen.Count",

          );

          // Show header without count on error

          return _buildHeaderContent('Completed Games', null);

        }


        int userCompletedCount = 0;

        if (snapshot.hasData) {

          // --- Client-side filtering for count ---

          final docs = snapshot.data!.docs;

          for (var doc in docs) {

            final data = doc.data() as Map<String, dynamic>? ?? {};

            final playerXUserId = data['playerX']?['userId'];

            final playerOUserId = data['playerO']?['userId'];

            if (playerXUserId == userId || playerOUserId == userId) {

              userCompletedCount++;

            }

          }

          // ----------------------------------------

        }

        // Pass count (or null if still loading/error) to the actual header widget

        return _buildHeaderContent('Completed Games', userCompletedCount);

      },

    );

  }


  Widget _buildHeaderContent(String title, int? count) {

    return Container(

      color: Colors.blueGrey[50],

      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

      // Use horizontal: 0 if controlAffinity handles padding

      child: Row(

        mainAxisAlignment: MainAxisAlignment.start, // Align content to start

        children: [

          // Title text takes available space

          Expanded(

            child: Text(

              title,

              style: TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 16,

                color: Colors.blueGrey[800],

              ),

            ),

          ),

          // Display count if available

          if (count != null)

            Padding(

              padding: const EdgeInsets.only(left: 8.0), // Space before count

              child: Text(

                '($count)', // Display count in parentheses

                style: TextStyle(

                  fontSize: 14,

                  fontWeight: FontWeight.normal,

                  color: Colors.blueGrey[600],

                ),

              ),

            ),

          // The arrow icon will be placed by controlAffinity

        ],

      ),

    );

  }


  // Builds the list *inside* the ExpansionTile (check query/index)

  Widget _buildCompletedGamesListInsideExpansion() {

    return StreamBuilder<QuerySnapshot>(

      stream:

      FirebaseFirestore.instance

          .collection('games')

          .where('status', isEqualTo: 'completed')

      // Check Debug Console for link to create index, or create manually:

      // Index Fields: status (Asc), endedAt (Desc)

          .orderBy('endedAt', descending: true)

          .limit(50) // Limit fetched docs for performance

          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {

          return Padding(

            padding: const EdgeInsets.all(16.0),

            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),

          );

        }

        if (snapshot.hasError) {

          // Log the specific error

          developer.log(

            "Error loading completed games list: ${snapshot.error}",

            name: "GameListScreen.CompletedList",

            error: snapshot.error,

            level: 1000,

          );

          // Provide guidance IF it's likely an index error

          String errorText = 'Error loading completed games.';

          if (snapshot.error.toString().toLowerCase().contains('index')) {

            errorText +=

            '\nPlease check the debug console for a Firestore index creation link, or create the required index manually in the Firebase Console.';

          }

          return Padding(

            padding: const EdgeInsets.all(16.0),

            child: Center(child: Text(errorText, textAlign: TextAlign.center)),

          );

        }

        final docs = snapshot.data?.docs;

        if (docs == null || docs.isEmpty) {

          return Padding(

            padding: const EdgeInsets.all(16.0),

            child: Center(child: Text('No completed games found.')),

          );

        }


        return ListView.builder(

          shrinkWrap: true,

          physics: NeverScrollableScrollPhysics(),

          itemCount: docs.length,

          itemBuilder: (context, index) {

            // Check if widget is still mounted before accessing context potentially

            if (!mounted) return SizedBox.shrink();

            return _buildCompletedGameTile(context, docs[index]);

          },

        );

      },

    );

  }


  // --- Helper Methods for Building ListTiles ---


  // Builds a ListTile for an Active or Waiting game

  Widget _buildActiveGameTile(BuildContext context, DocumentSnapshot gameDoc) {

    var data = gameDoc.data() as Map<String, dynamic>? ?? {};


    var playerXData = data['playerX'] as Map<String, dynamic>? ?? {};

    var playerOData = data['playerO'] as Map<String, dynamic>?;


    String playerXName = playerXData['displayName'] ?? "Unknown Player";

    String playerOName = playerOData?['displayName'] ?? "Waiting...";


    var status = data['status'] ?? "Unknown";

    String displayStatus = status[0].toUpperCase() + status.substring(1);

    var createdAtData = data['createdAt'];

    String started = _formatTimestamp(createdAtData); // Use helper


    String tileTitle;

    if (status == 'waiting') {

      tileTitle = 'Game created by $playerXName';

    } else {

      tileTitle = '$playerXName vs $playerOName';

    }


    return ListTile(

      title: Text(tileTitle),

      subtitle: Text('Status: $displayStatus\nStarted: $started'),

      trailing: Icon(Icons.chevron_right),

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (context) => GameBoardScreen(gameId: gameDoc.id),

          ),

        );

      },

    );

  }


  // Builds a ListTile for a Completed game

  Widget _buildCompletedGameTile(

      BuildContext context,

      DocumentSnapshot gameDoc,

      ) {

    var data = gameDoc.data() as Map<String, dynamic>? ?? {};


    var playerXData = data['playerX'] as Map<String, dynamic>? ?? {};

    var playerOData =

        data['playerO'] as Map<String, dynamic>? ??

            {}; // Assume O exists if completed


    String playerXName = playerXData['displayName'] ?? "Player X";

    String playerOName = playerOData['displayName'] ?? "Player O";


    var winner = data['winner']; // 'X', 'O', or 'draw'

    var endedAtData = data['endedAt']; // Timestamp when game ended

    String endedDate = _formatTimestamp(endedAtData); // Use helper


    String resultText;

    Icon resultIcon;


    if (winner == 'draw') {

      resultText = 'Result: Draw';

      resultIcon = Icon(Icons.handshake_outlined, color: Colors.orange);

    } else if (winner == 'X') {

      resultText = 'Winner: $playerXName (X)';

      resultIcon = Icon(Icons.emoji_events_outlined, color: Colors.redAccent);

    } else if (winner == 'O') {

      resultText = 'Winner: $playerOName (O)';

      resultIcon = Icon(Icons.emoji_events_outlined, color: Colors.blueAccent);

    } else {

      resultText = 'Result: Unknown'; // Fallback

      resultIcon = Icon(Icons.question_mark, color: Colors.grey);

    }


    return ListTile(

      leading: resultIcon,

      title: Text('$playerXName vs $playerOName'),

      subtitle: Text('$resultText\nEnded: $endedDate'),

      dense: true, // Make completed tiles a bit smaller

    );

  }


  // Helper function to format Timestamps consistently

  String _formatTimestamp(dynamic timestampData) {

    if (timestampData is Timestamp) {

      try {

        // Using intl package for nice formatting

        return DateFormat.yMd().add_jm().format(

          timestampData.toDate().toLocal(),

        );

      } catch (e) {

        // Fallback if intl formatting fails for some reason

        final dt = timestampData.toDate().toLocal();

        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

      }

    }

    return "N/A";

  }


  // _createNewGame function (moved into State class)

  void _createNewGame(BuildContext context) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {

      /* ... handle not logged in ... */

      return;

    }


    // Show loading indicator (Use context mounted check)

    if (!mounted) return; // Check if widget is still mounted before async gap

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) => Center(child: CircularProgressIndicator()),

    );


    try {

      final gameData = {

        /* ... game data ... */

        'playerX': {

          'userId': user.uid,

          'displayName':

          user.displayName?.isNotEmpty ?? false

              ? user.displayName

              : user.email ?? 'Player X',

        },

        'playerO': null,

        'status': 'waiting',

        'currentTurn': 'X',

        'board': List.filled(9, null),

        'winner': null,

        'createdAt': FieldValue.serverTimestamp(),

        'moves': [],

        'endedAt': null, // Ensure endedAt exists for ordering maybe?

      };

      var doc = await FirebaseFirestore.instance

          .collection('games')

          .add(gameData);


      if (!mounted) return; // Check again after await

      Navigator.pop(context); // Dismiss loading


      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) => GameBoardScreen(gameId: doc.id),

        ),

      );

    } catch (e) {

      print('Error creating game: $e');

      if (!mounted) return; // Check again

      Navigator.pop(context); // Dismiss loading on error

      ScaffoldMessenger.of(

        context,

      ).showSnackBar(SnackBar(content: Text('Failed to create game: $e')));

    }

  }

} // End of _GameListScreenState