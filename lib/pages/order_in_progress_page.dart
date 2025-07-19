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
  String? robotIp;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();

    _startStatusPolling();
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
          robotIp = order!['robot_ip'];
          isLoading = false;
        });
        print('✅ Order status fetched: $currentStatus');
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
  void _scanQrCodeAndLaunch() async {
    final simulatedRobotIp = '127.0.0.1:5000';

    final url = 'http://$simulatedRobotIp/pickup_ready?order_id=${widget.orderId}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL: $url')),
      );
    }
  }

  Future<void> _verifyPinAndOpenBox(String enteredPin) async {
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
          currentStatus = newStatus; // Update local state immediately
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
            const SizedBox(height: 30),
            // Conditional UI based on status
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
                    onPressed: _scanQrCodeAndLaunch, // Simulates QR scan. In real app, this would be scanner output
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Simulate Scan Robot QR Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Text field for PIN entry
                  TextField(
                    controller: TextEditingController(), // Needs a real controller
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter PIN from Robot Screen',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _verifyPinAndOpenBox(value),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // For demo, we'll just use a placeholder PIN or read from a controller
                      _verifyPinAndOpenBox('1234'); // Replace with actual controller value
                    },
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