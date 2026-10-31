import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_sender.dart';
import 'restaurant_data.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final CartModel _cart = CartModel.instance;
  final TextEditingController _addressController =
      TextEditingController(text: 'Nandambakkam, Chennai, Tamil Nadu');

  bool _placingOrder = false;

  static const double _deliveryFee = 30;
  static const double _taxRate = 0.05;

  double get _subtotal => _cart.totalPrice;
  double get _tax => _subtotal * _taxRate;
  double get _grandTotal => _subtotal + _deliveryFee + _tax;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address')),
      );
      return;
    }

    setState(() => _placingOrder = true);

    final itemCount = _cart.totalItems;
    final total = _grandTotal;
    final orderId = await _saveOrderToFirebase();

    if (!mounted) return;
    setState(() => _placingOrder = false);

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place order. Try again.')),
      );
      return;
    }

    _cart.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order placed! 🎉'),
        content: Text(
          'Your order of $itemCount item${itemCount > 1 ? 's' : ''} worth '
          '₹${total.toStringAsFixed(0)} has been placed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to cart
              Navigator.pop(context); // back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _saveOrderToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _cart.items.isEmpty) return null;

    final ref = FirebaseDatabase.instanceFor(
      app: FirebaseAuth.instance.app,
      databaseURL:
          'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('orders/${user.uid}').push();

    await ref.set({
      'restaurantName': _cart.items.first.restaurantName,
      'deliveryAddress': _addressController.text.trim(),
      'items': {
        for (final item in _cart.items)
          item.id: {
            'name': item.name,
            if (item.imagePath != null) 'imagePath': item.imagePath,
            'price': item.price,
            'quantity': item.quantity,
          },
      },
      'subtotal': _subtotal,
      'deliveryFee': _deliveryFee,
      'tax': _tax,
      'total': _grandTotal,
      'status': 'Placed',
      'placedAt': DateTime.now().toIso8601String(),
    });

    _sendOrderPlacedNotification(restaurantName: _cart.items.first.restaurantName);

    return ref.key;
  }

  void _sendOrderPlacedNotification({required String restaurantName}) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FcmSender.instance.sendNotification(
      token: token,
      title: 'Order placed! 🎉',
      body: 'Your order from $restaurantName is on its way to being prepared.',
    );
  }

  Widget _itemThumbnail(CartItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.imagePath != null
          ? Image.asset(
              item.imagePath!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            )
          : Container(
              width: 44,
              height: 44,
              color: Colors.grey.shade200,
              child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on, color: Colors.deepOrange),
              filled: true,
              fillColor: const Color(0xFFF7F1EC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Items from ${items.isNotEmpty ? items.first.restaurantName : ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final item in items) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        _itemThumbnail(item),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '₹${item.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (item != items.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bill Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _billRow('Subtotal', _subtotal),
                _billRow('Delivery Fee', _deliveryFee),
                _billRow('Taxes (5%)', _tax),
                const Divider(height: 20),
                _billRow('To Pay', _grandTotal, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placingOrder ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _placingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm Order • ₹${_grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${amount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}