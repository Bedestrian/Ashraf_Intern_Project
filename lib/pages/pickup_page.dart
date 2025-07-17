import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PickupPage extends StatefulWidget {
  final String robotIp; // example: 35.1.132.242
  const PickupPage({super.key, required this.robotIp});

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final TextEditingController _pinController = TextEditingController();
  String resultMessage = '';
  bool accessGranted = false;

  Future<void> submitPin() async {
    final url = Uri.parse('http://${widget.robotIp}:8080/enter_pin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _pinController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          resultMessage = '✅ Access Granted';
          accessGranted = true;
        });
      } else {
        setState(() {
          resultMessage = '❌ Incorrect PIN';
          accessGranted = false;
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = '❗ Failed to connect to robot';
      });
    }
  }

  Future<void> markAsReceived() async {
    final url = Uri.parse('http://${widget.robotIp}:8080/package_received');
    try {
      await http.post(url);
      setState(() {
        resultMessage = '✅ Package received. Thank you!';
      });
    } catch (e) {
      setState(() {
        resultMessage = '❗ Failed to update robot state';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Package Ready for Pickup\nEnter the PIN shown on the robot',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: submitPin,
              child: const Text('Submit PIN'),
            ),
            const SizedBox(height: 20),
            Text(
              resultMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (accessGranted)
              ElevatedButton(
                onPressed: markAsReceived,
                child: const Text('Mark as Received'),
              ),
          ],
        ),
      ),
    );
  }
}
