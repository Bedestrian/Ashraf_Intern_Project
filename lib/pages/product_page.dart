import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductPage extends StatefulWidget {
  final String userId;
  final String token;

  const ProductPage({super.key, required this.userId, required this.token});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8090/api/collections/products/records'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('🟡 Response status: ${response.statusCode}');
      print('🟢 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['items'];
          isLoading = false;
        });
      } else {
        print('🔴 Failed to fetch products: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('🔴 Error fetching products: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> placeOrder(String productId) async {
    final url = 'http://127.0.0.1:8090/api/collections/orders/records';

    final body = {
      "user_id": widget.userId,
      "product_id": productId,
      "status": "pending",
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Order created successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed!")),
        );
        // You can navigate to Order In Progress page here
      } else {
        print("❌ Failed to place order: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to place order")),
        );
      }
    } catch (e) {
      print("❌ Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No products available."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final imageUrl = product['image'] != null && product['image'] != ""
                        ? 'http://127.0.0.1:8090/api/files/products/${product['id']}/${product['image']}'
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(product['name']),
                        subtitle: Text("\$${product['price']}"),
                        trailing: ElevatedButton(
                          onPressed: () {
                            placeOrder(product['id']);
                          },
                          child: const Text("Order"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}