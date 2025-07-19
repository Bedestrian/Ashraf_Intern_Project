import 'package:flutter/material.dart';
import 'pages/login_page.dart'; // Make sure this path is correct
// import 'pages/product_page.dart'; // No longer initial route
// import 'pages/home_page.dart'; // No longer initial route, we'll integrate its functionality later if needed

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Delivery Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // Set LoginPage as the initial route
        // ProductPage will be navigated to directly from LoginPage after successful login.
        // Other routes like home_page and pickup_page will be integrated later as needed.
      },
    );
  }
}