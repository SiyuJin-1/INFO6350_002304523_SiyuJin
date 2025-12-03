import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardListScreen extends StatelessWidget {
  const LeaderboardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leaderboard: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No completed games yet.\nPlay some games first!'),
            );
          }

          final Map<String, _PlayerStats> statsMap = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = data['status'];
            if (status != 'completed') continue;

            final winner = data['winner']; // 'X' / 'O' / 'draw'
            final playerX = data['playerX'] as Map<String, dynamic>? ?? {};
            final playerO = data['playerO'] as Map<String, dynamic>? ?? {};

            final xId = playerX['userId'] as String?;
            final oId = playerO['userId'] as String?;

            final xName =
            (playerX['displayName'] as String?)?.trim().isNotEmpty == true
                ? playerX['displayName'] as String
                : 'Player X';
            final oName =
            (playerO['displayName'] as String?)?.trim().isNotEmpty == true
                ? playerO['displayName'] as String
                : 'Player O';

            if (xId != null) {
              statsMap.putIfAbsent(
                xId,
                    () => _PlayerStats(userId: xId, displayName: xName),
              );
              statsMap[xId]!.displayName ??= xName;
              statsMap[xId]!.gamesPlayed++;
            }

            if (oId != null) {
              statsMap.putIfAbsent(
                oId,
                    () => _PlayerStats(userId: oId, displayName: oName),
              );
              statsMap[oId]!.displayName ??= oName;
              statsMap[oId]!.gamesPlayed++;
            }

            if (winner == 'draw') {
              if (xId != null) statsMap[xId]!.draws++;
              if (oId != null) statsMap[oId]!.draws++;
            } else if (winner == 'X') {
              if (xId != null) statsMap[xId]!.wins++;
              if (oId != null) statsMap[oId]!.losses++;
            } else if (winner == 'O') {
              if (oId != null) statsMap[oId]!.wins++;
              if (xId != null) statsMap[xId]!.losses++;
            }
          }

          final entries = statsMap.values.toList()
            ..sort((a, b) {
              if (b.wins != a.wins) return b.wins.compareTo(a.wins);
              if (b.gamesPlayed != a.gamesPlayed) {
                return b.gamesPlayed.compareTo(a.gamesPlayed);
              }
              final nameA = a.displayName ?? '';
              final nameB = b.displayName ?? '';
              return nameA.toLowerCase().compareTo(nameB.toLowerCase());
            });

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ranked by number of wins (then total games).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final isCurrentUser = e.userId == currentUserId;
                      final winRate = e.gamesPlayed == 0
                          ? 0.0
                          : e.wins / e.gamesPlayed;

                      return Container(
                        color: isCurrentUser
                            ? Colors.blue.withOpacity(0.07)
                            : Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          title: Text(
                            e.displayName ?? 'Unknown Player',
                            style: TextStyle(
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Games: ${e.gamesPlayed}  |  '
                                'W: ${e.wins}  L: ${e.losses}  D: ${e.draws}',
                          ),
                          trailing: Text(
                            '${(winRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: winRate >= 0.5
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayerStats {
  final String userId;
  String? displayName;
  int gamesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;

  _PlayerStats({
    required this.userId,
    this.displayName,
  });
}
