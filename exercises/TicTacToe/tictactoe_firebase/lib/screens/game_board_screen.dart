import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'game_board_screen.dart';

import 'dart:developer' as developer; // Import developer log


class GameBoardScreen extends StatefulWidget {

  final String gameId;

  GameBoardScreen({required this.gameId});


  @override

  _GameBoardScreenState createState() => _GameBoardScreenState();

}


class _GameBoardScreenState extends State<GameBoardScreen> {

  List<dynamic>? _localBoardState;

  User? _currentUser;

  Map<String, dynamic>? _currentGameData;


  @override

  void initState() {

    super.initState();

    _currentUser = FirebaseAuth.instance.currentUser;

    developer.log(

      "GameBoardScreen Init - Current User UID: ${_currentUser?.uid}",

      name: "GameBoardScreen",

    );

  }


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Tic Tac Toe'),

      ),

      body: StreamBuilder<DocumentSnapshot>(

        stream:

        FirebaseFirestore.instance

            .collection('games')

            .doc(widget.gameId)

            .snapshots(),

        builder: (context, snapshot) {

          // --- Update local state based on stream ---

          if (snapshot.hasData && snapshot.data!.exists) {

            _currentGameData = snapshot.data!.data() as Map<String, dynamic>;

            _localBoardState = List<dynamic>.from(

              _currentGameData!['board'] ?? List.filled(9, null),

            );

            developer.log(

              "Stream Update Received - Status: ${_currentGameData!['status']}, Turn: ${_currentGameData!['currentTurn']}",

              name: "GameBoardScreen.Stream",

            );

          } else if (snapshot.connectionState == ConnectionState.active &&

              snapshot.hasData &&

              !snapshot.data!.exists) {

            // Handle case where game is deleted after screen is opened

            _currentGameData = null;

            _localBoardState = null;

          } // Keep showing old state during brief disconnects if _currentGameData exists


          // --- Loading / Error / Not Found States ---

          if (_currentGameData == null) {

            if (snapshot.connectionState == ConnectionState.waiting) {

              return Center(child: CircularProgressIndicator());

            }

            if (snapshot.hasError) {

              developer.log(

                "Stream Error: ${snapshot.error}",

                name: "GameBoardScreen.Stream",

                error: snapshot.error,

              );

              return Center(

                child: Text('Error loading game: ${snapshot.error}'),

              );

            }

            return Center(child: Text('Game not found or has been deleted.'));

          }

          // --- End State Handling ---


          // We have _currentGameData here, proceed to build UI

          final game = _currentGameData!;

          String? winnerText; // Winner text logic (same as before)

          if (game['status'] == 'completed' && game['winner'] != null) {

            if (game['winner'] == 'draw')

              winnerText = 'It\'s a Draw!';

            else {

              String winnerName = '';

              if (game['winner'] == 'X')

                winnerName = game['playerX']?['displayName'] ?? 'Player X';

              else if (game['winner'] == 'O')

                winnerName = game['playerO']?['displayName'] ?? 'Player O';

              winnerText = 'Winner: $winnerName (${game['winner']})';

            }

          }


          return Column(

            // Main layout column

            crossAxisAlignment: CrossAxisAlignment.center,

            children: [

              Padding(

                // Player Info

                padding: const EdgeInsets.symmetric(vertical: 16.0),

                child: _buildPlayerInfo(game, _currentUser),

              ),

              Expanded(

                // Board Area

                child: Center(

                  child: ConstrainedBox(

                    constraints: BoxConstraints(maxWidth: 450, maxHeight: 450),

                    child: Padding(

                      padding: const EdgeInsets.all(16.0),

                      child: _buildBoard(game, _currentUser), // Build the board

                    ),

                  ),

                ),

              ),

              if (winnerText != null) // Winner Text

                Padding(

                  padding: const EdgeInsets.symmetric(vertical: 20.0),

                  child: Text(

                    winnerText,

                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

                  ),

                ),

              if (game['status'] == 'active') // Turn Indicator

                Padding(

                  padding: const EdgeInsets.only(bottom: 20.0),

                  child: Text(

                    'Turn: ${game['currentTurn'] ?? ''}',

                    style: TextStyle(fontSize: 18),

                  ),

                ),

            ],

          );

        },

      ),

    );

  }


  // _buildPlayerInfo (with highlighting) remains the same

  Widget _buildPlayerInfo(Map<String, dynamic> game, User? user) {

    if (user == null) return Text('Not logged in');

    if (game['status'] == 'waiting' &&

        game['playerO'] == null &&

        game['playerX']?['userId'] != user.uid) {

      return ElevatedButton(

        onPressed: () => _joinGame(user),

        child: Text('Join as Player O'),

      );

    }

    String playerXName = game['playerX']?['displayName'] ?? 'Player X';

    String playerOName = game['playerO']?['displayName'] ?? 'Waiting...';

    String currentTurn = game['currentTurn'] ?? '';

    bool isXTurn = currentTurn == 'X';

    bool isOTurn = currentTurn == 'O';

    bool isCompleted = game['status'] == 'completed';

    const normalStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

    const boldStyle = TextStyle(

      fontSize: 18,

      fontWeight: FontWeight.bold,

      color: Colors.blue,

    );

    final xStyle = !isCompleted && isXTurn ? boldStyle : normalStyle;

    final oStyle = !isCompleted && isOTurn ? boldStyle : normalStyle;

    return RichText(

      textAlign: TextAlign.center,

      text: TextSpan(

        style: normalStyle.copyWith(

          color: Theme.of(context).textTheme.bodyLarge?.color,

        ),

        children: <TextSpan>[

          TextSpan(text: '$playerXName (X)', style: xStyle),

          TextSpan(text: ' vs '),

          TextSpan(text: '$playerOName (O)', style: oStyle),

        ],

      ),

    );

  }


  Widget _buildBoard(Map<String, dynamic> game, User? user) {

    final boardList = _localBoardState ?? List.filled(9, null);


    if (user == null) {

      developer.log(

        "BuildBoard: User is null, cannot build board.",

        name: "GameBoardScreen.BuildBoard",

      );

      return Center(child: Text('Login required to play.'));

    }

    final currentUserUID = user.uid; // User is non-null here


    // Get game details needed for checks (use cached _currentGameData for consistency within this build)

    final gameStatus = game['status'];

    final currentTurn = game['currentTurn'];

    final playerXUserId = game['playerX']?['userId'];

    final playerOData = game['playerO'] as Map<String, dynamic>?;

    final playerOUserId = playerOData?['userId'];


    // Calculate isMyTurn status FOR THIS BUILD

    bool isMyTurnCheck = false;

    if (gameStatus == 'active') {

      if (currentTurn == 'X' && playerXUserId == currentUserUID)

        isMyTurnCheck = true;

      else if (currentTurn == 'O' && playerOUserId == currentUserUID)

        isMyTurnCheck = true;

    }


    // --- Log Overall Turn Status ONCE Per Build ---

    // Use developer.log for potentially large output or structured logging

    developer.log(

      "BuildBoard Check: Status='$gameStatus', Turn='$currentTurn', PlayerX='$playerXUserId', PlayerO='$playerOUserId', CurrentUser='$currentUserUID' => isMyTurnCheck=$isMyTurnCheck",

      name: "GameBoardScreen.BuildBoard",

    );

    // --- End Overall Log ---


    return GridView.builder(

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount: 3,

        crossAxisSpacing: 8.0,

        mainAxisSpacing: 8.0,

      ),

      itemCount: boardList.length,

      itemBuilder: (context, index) {

        String notation = _getChessNotation(index);

        String? cellValue =

        boardList.length > index

            ? boardList[index]?.toString()

            : null; // Read from local state

        String displayValue = cellValue ?? notation;


        // Calculate canTap FOR THIS CELL

        bool cellValueIsNullCheck = cellValue == null;

        // Use the isMyTurnCheck calculated above for this build cycle

        bool canTap =

            gameStatus == 'active' && isMyTurnCheck && cellValueIsNullCheck;


        // --- Log Details for a Specific Cell (e.g., center, index 4) ---

        if (index == 4) {

          developer.log(

            "Cell $index Check: gameStatusActive=${gameStatus == 'active'}, isMyTurn=$isMyTurnCheck, cellValueIsNull=$cellValueIsNullCheck (value='$cellValue') => canTap=$canTap",

            name: "GameBoardScreen.BuildBoard.Cell",

          );

        }

        // --- End Cell Log ---


        return GestureDetector(

          onTap:

          canTap

              ? () {

            final player =

            (playerXUserId == currentUserUID)

                ? 'X'

                : 'O'; // Determine player based on initial data

            developer.log(

              "Cell $index TAPPED by Player $player. Current local value: '${_localBoardState?[index]}'",

              name: "GameBoardScreen.Tap",

            );


            // Optimistic UI update

            setState(() {

              _localBoardState ??= List.filled(9, null);

              if (index >= 0 && index < _localBoardState!.length) {

                if (_localBoardState![index] == null) {

                  // Double check it's still null locally

                  _localBoardState![index] = player;

                  developer.log(

                    "Optimistic Update: Set cell $index to $player",

                    name: "GameBoardScreen.Tap",

                  );

                } else {

                  developer.log(

                    "Optimistic Update SKIPPED: Cell $index already has value '${_localBoardState![index]}'",

                    name: "GameBoardScreen.Tap",

                  );

                  return; // Don't proceed if cell occupied locally

                }

              } else {

                developer.log(

                  "Optimistic Update ERROR: Invalid index $index",

                  name: "GameBoardScreen.Tap",

                );

                return; // Don't proceed

              }

            });


            // Call Firestore update (pass the game data as it was when the board was built)

            _makeMove(index, game);

          }

              : null, // onTap is null if canTap is false

          child: Container(

            // Styling... (same as before)

            decoration: BoxDecoration(

              border: Border.all(color: Colors.grey.shade400),

              borderRadius: BorderRadius.circular(4.0),

              color:

              canTap

                  ? Colors.lightBlue.shade50

                  : (cellValue == null

                  ? Colors.white

                  : Colors.grey.shade200),

            ),

            child: Center(

              /* ... Text display ... */

              child: Text(

                displayValue,

                style: TextStyle(

                  fontSize: 32,

                  fontWeight: FontWeight.bold,

                  color:

                  cellValue == 'X'

                      ? Colors.redAccent

                      : (cellValue == 'O'

                      ? Colors.blueAccent

                      : (canTap

                      ? Colors.black54

                      : Colors.grey.shade600)),

                ),

              ),

            ),

          ),

        );

      },

    );

  }


  // --- _joinGame, _makeMove, _getChessNotation, _checkWinner remain the same ---

  void _joinGame(User user) {

    developer.log(

      "Attempting to join game ${widget.gameId} as Player O.",

      name: "GameBoardScreen.Join",

    );

    FirebaseFirestore.instance

        .collection('games')

        .doc(widget.gameId)

        .update({

      'playerO': {

        'userId': user.uid,

        'displayName': user.displayName ?? user.email ?? 'Player O',

      },

      'status': 'active', // CRITICAL: Ensure status becomes active

    })

        .then((_) {

      developer.log(

        "Successfully joined game. Status set to active.",

        name: "GameBoardScreen.Join",

      );

    })

        .catchError((error) {

      developer.log(

        "Failed to join game: $error",

        name: "GameBoardScreen.Join",

        error: error,

      );

      if (mounted)

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Error joining game: $error')),

        );

    });

  }


  void _makeMove(int index, Map<String, dynamic> game) async {

    // Use cached user for consistency

    if (_currentUser == null) {

      developer.log(

        "MakeMove Error: Current user is null.",

        name: "GameBoardScreen.MakeMove",

      );

      return;

    }

    final player = game['playerX']?['userId'] == _currentUser!.uid ? 'X' : 'O';

    developer.log(

      "Attempting move at index $index by Player $player.",

      name: "GameBoardScreen.MakeMove",

    );


    // Use the local state which should reflect the optimistic update

    final boardAfterMove = List<dynamic>.from(

      _localBoardState ?? List.filled(9, null),

    );


    // --- CRITICAL CHECK ---

    // Verify the move is valid according to the board state *just before* updating Firestore

    // This prevents race conditions or overwrites if Firestore is slow/state mismatch

    if (index < 0 ||

        index >= boardAfterMove.length ||

        boardAfterMove[index] != player) {

      developer.log(

        "MakeMove Firestore Update SKIPPED. Mismatch found. Index: $index, Expected Player: $player, Board Value: '${boardAfterMove.length > index ? boardAfterMove[index] : 'OOB'}'",

        name: "GameBoardScreen.MakeMove",

        level: 900, // Warning level

      );

      // Optionally: Force refresh local state from Firestore? Or show error?

      // For now, we just prevent the invalid Firestore write.

      return;

    }

    // --- END CRITICAL CHECK ---


    final move = {

      'position': index,

      'player': player,

      'notation': _getChessNotation(index),

      // 'timestamp': FieldValue.serverTimestamp(), // REMOVED

    };

    String? winner = _checkWinner(boardAfterMove);

    String nextTurn = player == 'X' ? 'O' : 'X';

    String newStatus =

    game['status']; // Status from the game data when build happened


    Map<String, dynamic> updateData = {

      'board': boardAfterMove,

      'moves': FieldValue.arrayUnion([

        move,

      ]), // Add move map (without timestamp)

      // --- FIX: Add separate top-level timestamp field ---

      'lastMoveTimestamp': FieldValue.serverTimestamp(),

      // --- End FIX ---

    };


    if (winner != null) {

      developer.log(

        "Winner detected: $winner",

        name: "GameBoardScreen.MakeMove",

      );

      updateData['winner'] = winner;

      updateData['status'] = 'completed';

      updateData['endedAt'] = FieldValue.serverTimestamp();

    } else {

      updateData['currentTurn'] = nextTurn;

      // Ensure status is active (should be, but safety)

      if (newStatus != 'active') updateData['status'] = 'active';

    }


    developer.log(

      "Updating Firestore with: ${updateData.keys.toList()}",

      name: "GameBoardScreen.MakeMove",

    );

    await FirebaseFirestore.instance

        .collection('games')

        .doc(widget.gameId)

        .update(updateData)

        .then((_) {

      developer.log(

        "Firestore update successful for move at index $index.",

        name: "GameBoardScreen.MakeMove",

      );

    })

        .catchError((error) {

      developer.log(

        "Firestore update FAILED: $error",

        name: "GameBoardScreen.MakeMove",

        error: error,

        level: 1000,

      ); // Error Level

      if (mounted)

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Error making move: $error')),

        );

      // Consider reverting the optimistic update if Firestore fails?

      // setState(() { _localBoardState = List<dynamic>.from(game['board'] ?? List.filled(9, null)); });

    });

  }


  String _getChessNotation(int index) {

    /* ... same ... */

    final row = ['a', 'b', 'c'][index ~/ 3];

    final col = ['1', '2', '3'][index % 3];

    return '$row$col';

  }


  String? _checkWinner(List board) {

    /* ... same ... */

    const lines = [

      [0, 1, 2],

      [3, 4, 5],

      [6, 7, 8],

      [0, 3, 6],

      [1, 4, 7],

      [2, 5, 8],

      [0, 4, 8],

      [2, 4, 6],

    ];

    for (var line in lines) {

      if (board.length > line[2] &&

          board[line[0]] != null &&

          board[line[0]] == board[line[1]] &&

          board[line[0]] == board[line[2]])

        return board[line[0]]?.toString();

    }

    if (!board.contains(null)) return 'draw';

    return null;

  }

}

