import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/product_page.dart';
import 'pages/home_page.dart'; // do not import pickup_page here anymore

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
        '/': (context) => const HomePage(),
        // Don't include pickup here since it requires a parameter
      },
    );
  }
}
