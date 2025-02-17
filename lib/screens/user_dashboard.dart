import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserDashboardScreen extends StatefulWidget {
  final String token;
  const UserDashboardScreen({super.key, required this.token});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  List<dynamic> quizzes = [];
  final String baseUrl = "http://localhost:8080/api/user/quizzes";

  @override
  void initState() {
    super.initState();
    fetchQuizzes();
  }

  Future<void> fetchQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          quizzes = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to load quizzes");
      }
    } catch (e) {
      print("Error fetching quizzes: $e");
    }
  }

  Future<void> startQuiz(int quizId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$quizId/start"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final quizSession = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              quizData: quizzes.firstWhere((quiz) => quiz["id"] == quizId),
              sessionId: quizSession["id"],
              token: widget.token,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error starting quiz: $e");
    }
  }

  Future<void> submitQuiz(int quizId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$quizId/submit"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        fetchQuizzes(); // Refresh quizzes after submission
      }
    } catch (e) {
      print("Error submitting quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: quizzes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return ListTile(
            title: Text(quiz["title"]),
            subtitle: Text("Total Marks: ${quiz["totalMarks"]}, Duration: ${quiz["duration"]} mins"),
            trailing: ElevatedButton(
              onPressed: () {
                startQuiz(quiz["id"]);
              },
              child: const Text("Start"),
            ),
          );
        },
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final int sessionId;
  final String token;

  const QuizScreen({super.key, required this.quizData, required this.sessionId, required this.token});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;

  void _submitQuiz() async {
    final response = await http.post(
      Uri.parse("http://localhost:8080/api/user/quizzes/${widget.quizData["id"]}/submit"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    }
  }

  void _nextQuestion(bool correct) {
    if (correct) _score += 10;
    if (_currentQuestionIndex < widget.quizData["questions"].length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quizData["questions"][_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.quizData["title"])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q${_currentQuestionIndex + 1}: ${question["questionText"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Column(
              children: List.generate(question["options"].length, (index) {
                final option = question["options"][index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _nextQuestion(option["correct"]),
                    child: Text(option["optionText"]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
