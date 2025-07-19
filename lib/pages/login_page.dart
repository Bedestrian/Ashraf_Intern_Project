import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_page.dart'; // Add this line

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8090/api/collections/users/auth-with-password');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'identity': email, // Can be email or username
      'password': password,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('🟡 Login Response Status: ${response.statusCode}');
      print('🟢 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final authData = jsonDecode(response.body);
        final String userId = authData['record']['id'];
        final String token = authData['token'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );

        // Navigate to the ProductPage upon successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(userId: userId, token: token),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${errorData['message']}")),
        );
      }
    } catch (e) {
      print('🔴 Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: Could not connect to server.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delivery_dining, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 30),
              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Login"),
              ),
              const SizedBox(height: 20),
              // You could add a "Register" button here if needed
              TextButton(
                onPressed: () {
                  // Navigate to a registration page if you have one
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Register functionality not implemented in this demo.")),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}