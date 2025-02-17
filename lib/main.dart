import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quiz_app/screens/login.dart';
import 'package:quiz_app/screens/user_dashboard.dart';
import 'package:quiz_app/screens/admin_dashboard_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Widget> _checkAuthStatus() async {
    String? token = await _storage.read(key: 'jwt_token');
    String? role = await _storage.read(key: 'user_role');

    if (token != null && role != null) {
      if (role == "ROLE_ADMIN") {
        return AdminDashboardScreen(jwtToken: token,);
      } else {
        return UserDashboardScreen();
      }
    }
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _checkAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
