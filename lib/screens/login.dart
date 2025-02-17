import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quiz_app/screens/user_dashboard.dart';

import 'admin_dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.post(
        'http://localhost:8080/api/auth/login', // Update with your backend URL
        data: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      final token = response.data['token'];
      final role = response.data['role']; // Backend should return role

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_role', value: role);

      if (role == 'ROLE_ADMIN') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AdminDashboardScreen(jwtToken: token,)));
      } else if (role == 'ROLE_USER') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => UserDashboardScreen()));
      } else {
        setState(() {
          _errorMessage = "Invalid role received from server.";
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data['message'] ?? "Login failed";
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
      appBar: AppBar(title: Center(child: const Text("Welcome To Sparkl"))),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text("Login"),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
