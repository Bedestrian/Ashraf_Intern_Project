import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class OrderInProgressPage extends StatefulWidget {
  final String orderId;
  final String userId;
  final String token;

  const OrderInProgressPage({
    super.key,
    required this.orderId,
    required this.userId,
    required this.token,
  });

  @override
  State<OrderInProgressPage> createState() => _OrderInProgressPageState();
}

class _OrderInProgressPageState extends State<OrderInProgressPage> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  String currentStatus = "Fetching status...";
  String? robotPin;
  final TextEditingController _pinInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _pinInputController.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _fetchOrderStatus();
        if (currentStatus != 'delivered' && currentStatus != 'picked_up') {
          _startStatusPolling();
        }
      }
    });
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8090/api/collections/orders/records/${widget.orderId}?expand=product_id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          order = data;
          currentStatus = order!['status'];
          robotPin = order!['pin'];
          isLoading = false;
        });
        print('✅ Order status fetched: $currentStatus');

        if (currentStatus == 'pending') {
          _dispatchRobot(widget.orderId, widget.userId);
        }

      } else {
        print('🔴 Failed to fetch order status: ${response.body}');
        setState(() {
          isLoading = false;
          currentStatus = "Error fetching status";
        });
      }
    } catch (e) {
      print('🔴 Error fetching order status: $e');
      setState(() {
        isLoading = false;
        currentStatus = "Network error";
      });
    }
  }

  Future<void> _dispatchRobot(String orderId, String userId) async {
    final simulatedRobotIp = '127.0.0.1:5000';
    final url = Uri.parse('http://$simulatedRobotIp/dispatch_robot');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Robot dispatched successfully for order $orderId!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Robot dispatched!')),
        );
      } else {
        print("❌ Failed to dispatch robot: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispatch robot: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print("❌ Error dispatching robot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error dispatching robot: $e")),
      );
    }
  }

  void _scanQrCodeAndLaunch() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulating QR scan. The robot should now be displaying a PIN.')),
    );
  }

  Future<void> _verifyPinAndOpenBox() async {
    final enteredPin = _pinInputController.text.trim();
    if (enteredPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the PIN.')),
      );
      return;
    }

    final simulatedRobotIp = '127.0.0.1:5000';
    final url = Uri.parse('http://$simulatedRobotIp/verify_pin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': widget.orderId,
          'pin': enteredPin,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN verified! Robot box opening...')),
        );
        _updateOrderStatus('box_opened');
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN verification failed: ${errorData['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying PIN: $e')),
      );
    }
  }

  Future<void> _markPackageReceived() async {
    await _updateOrderStatus('delivered');

    final simulatedRobotIp = '127.0.0.1:5000';
    final url = Uri.parse('http://$simulatedRobotIp/package_received');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package marked as received!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to signal robot package received: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signaling robot: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    final url = 'http://127.0.0.1:8090/api/collections/orders/records/${widget.orderId}';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        print("✅ Order status updated to $newStatus in PocketBase.");
        setState(() {
          currentStatus = newStatus;
          if (newStatus != 'arrived') {
            _pinInputController.clear();
          }
        });
      } else {
        print("❌ Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating order status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order In Progress")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${widget.orderId}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Product: ${order?['expand']['product_id']['name'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "Current Status: ${currentStatus.toUpperCase()}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (currentStatus == 'arrived' && robotPin != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  "Robot PIN: ${robotPin!}",
                  style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 30),
            if (currentStatus == 'pending')
              const Text('Your order is pending. Robot is being dispatched.'),
            if (currentStatus == 'delivery_started')
              const Text('Your order is on its way!'),
            if (currentStatus == 'arrived')
              Column(
                children: [
                  const Text(
                    'Your delivery robot has arrived!',
                    style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _scanQrCodeAndLaunch,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Simulate Scan Robot QR Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinInputController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter PIN from Robot Screen',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _verifyPinAndOpenBox(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _verifyPinAndOpenBox,
                    child: const Text('Verify PIN'),
                  ),
                ],
              ),
            if (currentStatus == 'box_opened')
              Column(
                children: [
                  const Text(
                    'Robot box is open! Please take your package.',
                    style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _markPackageReceived,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Package Received'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            if (currentStatus == 'delivered' || currentStatus == 'picked_up')
              const Text(
                'Order completed! Thank you for using RoboDelivery.',
                style: TextStyle(fontSize: 18, color: Colors.purple, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}