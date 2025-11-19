import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum QuestionType { single, multi, boolean }
QuestionType _parseType(String? s) {
  switch (s) {
    case 'multi': return QuestionType.multi;
    case 'boolean': return QuestionType.boolean;
    default: return QuestionType.single;
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final List<int> correct;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.correct,
  });

  factory QuizQuestion.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawOptions = (data['options'] as List?) ?? const [];
    final rawCorrect = (data['correct'] as List?) ?? const [];
    return QuizQuestion(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      type: _parseType(data['type']?.toString()),
      options: rawOptions.map((e) => e.toString()).toList(),
      correct: rawCorrect
          .map<int>((e) => (e is num) ? e.toInt() : int.parse(e.toString()))
          .toList(),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String quizId;
  final String title;
  const QuizPage({super.key, required this.quizId, required this.title});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final List<QuizQuestion> _questions = [];
  final Map<String, List<int>> _answers = {}; // q.id -> picked indexes

  int _index = 0;
  int _score = 0;
  bool _finished = false;
  bool _timedOut = false;

  static const int _totalSeconds = 60;
  int _left = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions')
        .get();

    final docs = qs.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    final list = docs.map((d) => QuizQuestion.fromDoc(d)).toList();

    list.shuffle(Random());
    _questions
      ..clear()
      ..addAll(list.take(10));

    _startTimer();
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _left = _totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _left--;
        if (_left <= 0) {
          _timedOut = true;
          _finishQuiz(forceZero: true);
        }
      });
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz({bool forceZero = false}) {
    _timer?.cancel();
    if (_finished) return;
    _score = forceZero ? 0 : _calcScore();
    _finished = true;
    setState(() {});
    _saveResult();
  }

  int _calcScore() {
    int s = 0;
    for (final q in _questions) {
      final picked = _answers[q.id] ?? const <int>[];
      final a = Set<int>.from(picked);
      final b = Set<int>.from(q.correct);
      if (a.length == b.length && a.containsAll(b)) s++;
    }
    return s;
  }

  Future<void> _saveResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('results').add({
      'quizId': widget.quizId,
      'score': _score,
      'total': _questions.length,
      'timestamp': Timestamp.now(),
      'timedOut': _timedOut,
      'durationSeconds': _totalSeconds - _left,
    });
  }

  // === 新增：显示最近三次成绩 ===
  void _showRecentAttempts() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final query = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('results')
        .where('quizId', isEqualTo: widget.quizId)
        .orderBy('timestamp', descending: true)
        .limit(3);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Recent 3 Attempts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No attempts yet.'),
                  );
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final score = d['score'] ?? 0;
                    final total = d['total'] ?? 0;
                    final timedOut = d['timedOut'] == true;
                    final ts = (d['timestamp'] as Timestamp?)?.toDate();
                    final when = ts != null
                        ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
                        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                        : '-';
                    return ListTile(
                      leading: Icon(
                        timedOut ? Icons.timer_off : Icons.check_circle,
                        color: timedOut ? Colors.redAccent : Colors.green,
                      ),
                      title: Text('Score: $score / $total'),
                      subtitle: Text('Time: $when'),
                      trailing: timedOut ? const Text('Timeout') : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  // === 新增结束 ===

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && !_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_timedOut ? Icons.timer_off : Icons.emoji_events,
                  size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                _timedOut
                    ? 'Time Out! Score: 0 / ${_questions.length}'
                    : 'Your Score: $_score / ${_questions.length}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showRecentAttempts,
                icon: const Icon(Icons.history),
                label: const Text('Last 3 Attempts'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: $_left s'),
                Text('Q ${_index + 1} / ${_questions.length}'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _left / _totalSeconds),
            const SizedBox(height: 24),
            Text(
              '${q.text} (${q.type == QuestionType.multi ? 'Multiple Choice' : q.type == QuestionType.boolean ? 'True/False' : 'Single Choice'})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (_, i) {
                  final picked = _answers[q.id] ?? const <int>[];
                  if (q.type == QuestionType.multi) {
                    final checked = picked.contains(i);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(q.options[i]),
                      onChanged: (v) {
                        final next = List<int>.from(picked);
                        if (v == true) {
                          if (!next.contains(i)) next.add(i);
                        } else {
                          next.remove(i);
                        }
                        setState(() => _answers[q.id] = next);
                      },
                    );
                  } else {
                    final selected = picked.isEmpty ? -1 : picked.first;
                    return RadioListTile<int>(
                      value: i,
                      groupValue: selected,
                      title: Text(q.options[i]),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _answers[q.id] = <int>[v]);
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _index == _questions.length - 1 ? 'Submit' : 'Next',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
