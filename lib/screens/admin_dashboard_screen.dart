import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Option {
  String optionText;
  bool isCorrect;

  Option({required this.optionText, required this.isCorrect});
}

class Question {
  String questionText;
  List<Option> options;

  Question({required this.questionText, required this.options});
}

class AdminDashboardScreen extends StatefulWidget {
  final String jwtToken;

  const AdminDashboardScreen({Key? key, required this.jwtToken}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isCreateQuizScreenVisible = false;
  bool _isQuestionEntryScreenVisible = false;
  String _quizTitle = '';
  int _totalMarks = 0;
  int _duration = 0;
  List<Question> _questions = [
    Question(questionText: '', options: List.generate(4, (index) => Option(optionText: '', isCorrect: false))),
  ];
  int _currentQuestionIndex = 0;
  List<dynamic> _quizzes = [];
  int? _createdQuizId;

  // Fetch quizzes from the backend API with JWT token
  Future<void> _fetchQuizzes() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/admin/quizzes'),
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _quizzes = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load quizzes');
    }
  }

  // Fetch participants of a quiz
  Future<List<dynamic>> _fetchParticipants(int quizId) async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/admin/quizzes/$quizId/participants'),
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load participants');
    }
  }

  // Show participants in a dialog
  void _showParticipantsDialog(int quizId) async {
    try {
      final participants = await _fetchParticipants(quizId);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Participants'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    title: Text(participant['username']),
                    subtitle: Text('Completed: ${participant['completed']}, Score: ${participant['score']}'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load participants')));
    }
  }

  // Create a new quiz via POST request with JWT token
  Future<void> _createQuiz() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/admin/quizzes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
      body: json.encode({
        'title': _quizTitle,
        'totalMarks': _totalMarks,
        'duration': _duration,
      }),
    );

    if (response.statusCode == 200) {
      var quizData = json.decode(response.body);
      setState(() {
        _createdQuizId = quizData['id'];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz created successfully')));
      setState(() {
        _isCreateQuizScreenVisible = false;
        _isQuestionEntryScreenVisible = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create quiz')));
    }
  }

  // Add question to the quiz via POST request with JWT token
  Future<void> _addQuestion() async {
    if (_createdQuizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No quiz created yet')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/admin/quizzes/$_createdQuizId/questions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
      body: json.encode({
        'questionText': _questions[_currentQuestionIndex].questionText,
        'options': _questions[_currentQuestionIndex].options.map((option) {
          return {
            'optionText': option.optionText,
            'isCorrect': option.isCorrect,
          };
        }).toList(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Question added successfully')));
      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
        } else {
          _isQuestionEntryScreenVisible = false;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add question')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Handle logout logic here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCreateQuizScreenVisible = false;
                      _isQuestionEntryScreenVisible = false;
                    });
                  },
                  child: Text('Dashboard'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCreateQuizScreenVisible = true;
                      _isQuestionEntryScreenVisible = false;
                    });
                  },
                  child: Text('Create Quiz'),
                ),
              ],
            ),
            SizedBox(height: 20),
            _isCreateQuizScreenVisible
                ? _createQuizScreen()
                : _isQuestionEntryScreenVisible
                ? _questionEntryScreen()
                : _dashboardScreen(),
            SizedBox(height: 20),
            if (_quizzes.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Quiz')),
                    DataColumn(label: Text('Total Marks')),
                    DataColumn(label: Text('Duration')),
                  ],
                  rows: _quizzes
                      .map((quiz) => DataRow(cells: [
                    DataCell(Text(quiz['title'])),
                    DataCell(Text(quiz['totalMarks'].toString())),
                    DataCell(Text(quiz['duration'].toString())),
                  ], onSelectChanged: (selected) {
                    if (selected != null && selected) {
                      _showParticipantsDialog(quiz['id']);
                    }
                  }))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardScreen() {
    return Center(
      child: Text('Select an action from the buttons above'),
    );
  }

  Widget _createQuizScreen() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Quiz Title'),
          onChanged: (value) => _quizTitle = value,
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Total Marks'),
          onChanged: (value) => _totalMarks = int.tryParse(value) ?? 0,
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Duration (in minutes)'),
          onChanged: (value) => _duration = int.tryParse(value) ?? 0,
        ),
        ElevatedButton(
          onPressed: () {
            if (_quizTitle.isNotEmpty && _totalMarks > 0 && _duration > 0) {
              _createQuiz();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the fields.')));
            }
          },
          child: Text('Create Quiz'),
        ),
      ],
    );
  }

  Widget _questionEntryScreen() {
    // Ensure that we don't access out-of-range index in _questions list
    if (_questions.isEmpty) {
      _questions.add(Question(
        questionText: '',
        options: List.generate(4, (index) => Option(optionText: '', isCorrect: false)),
      ));
    }

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Question ${_currentQuestionIndex + 1}'),
          onChanged: (value) => _questions[_currentQuestionIndex].questionText = value,
        ),
        for (int i = 0; i < 4; i++)
          TextField(
            decoration: InputDecoration(labelText: 'Option ${i + 1}'),
            onChanged: (value) {
              _questions[_currentQuestionIndex].options[i].optionText = value;
            },
          ),
        Wrap(
          spacing: 10,
          children: List.generate(4, (index) {
            return ChoiceChip(
              label: Text('Option ${index + 1}'),
              selected: _questions[_currentQuestionIndex].options[index].isCorrect,
              onSelected: (selected) {
                setState(() {
                  _questions[_currentQuestionIndex].options[index].isCorrect = selected;
                });
              },
            );
          }),
        ),
        ElevatedButton(
          onPressed: () {
            _addQuestion();
          },
          child: Text('Add Question'),
        ),
      ],
    );
  }
}
