import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDashboardScreen extends StatefulWidget {
  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _quizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token = await _storage.read(key: 'jwt_token');
      final response = await _dio.get(
        'http://localhost:8080/api/user/quizzes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _quizzes = response.data;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data['message'] ?? "Failed to load quizzes";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Dashboard")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : ListView.builder(
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return ListTile(
            title: Text(quiz['title']),
            subtitle: Text("Duration: ${quiz['duration']} mins"),
            trailing: ElevatedButton(
              onPressed: () {
                // Navigate to quiz screen
              },
              child: const Text("Start"),
            ),
          );
        },
      ),
    );
  }
}
