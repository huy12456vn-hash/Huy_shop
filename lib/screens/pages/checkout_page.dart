import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import 'order_history_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItemModel>? directItems;

  const CheckoutPage({super.key, this.directItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _voucherController = TextEditingController();

  String _paymentMethod = 'Cash on Delivery';
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  double _discount = 0;

  List<CartItemModel> get _items {
    if (widget.directItems != null && widget.directItems!.isNotEmpty) {
      return widget.directItems!;
    }

    return context.read<CartProvider>().items;
  }

  double get _subtotal {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  double get _shippingFee => _subtotal >= 1000000 ? 0 : 30000;

  double get _total {
    final value = _subtotal + _shippingFee - _discount;
    return value < 0 ? 0 : value;
  }

  @override
  void initState() {
    super.initState();
    _loadCustomerInformation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerInformation() async {
    final preferences = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    _nameController.text =
        preferences.getString('account_full_name') ?? user?.displayName ?? '';

    _phoneController.text = preferences.getString('account_phone_number') ?? '';

    _addressController.text =
        preferences.getString('account_delivery_address') ?? '';

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Uint8List? _decodeImage(String image) {
    if (image.isEmpty) {
      return null;
    }

    try {
      return base64Decode(image);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final positionFromRight = digits.length - index;
      buffer.write(digits[index]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} ₫';
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();

    setState(() {
      if (code == 'GUCCI10') {
        _discount = _subtotal * 0.10;
      } else if (code == 'FREESHIP') {
        _discount = _shippingFee;
      } else {
        _discount = 0;
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _discount > 0
              ? 'Voucher applied successfully.'
              : 'Invalid voucher code.',
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in before placing an order.');
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(
        'account_full_name',
        _nameController.text.trim(),
      );

      await preferences.setString(
        'account_phone_number',
        _phoneController.text.trim(),
      );

      await preferences.setString(
        'account_delivery_address',
        _addressController.text.trim(),
      );

      final orderReference = FirebaseFirestore.instance
          .collection('orders')
          .doc();

      await orderReference.set({
        'orderId': orderReference.id,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'customerName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'deliveryAddress': _addressController.text.trim(),
        'paymentMethod': _paymentMethod,
        'voucherCode': _voucherController.text.trim().toUpperCase(),
        'discount': _discount,
        'shippingFee': _shippingFee,
        'subtotal': _subtotal,
        'totalPrice': _total,
        'totalItems': _items.fold(0, (total, item) => total + item.quantity),
        'status': 'pending',
        'items': _items.map((item) {
          return {
            'productId': item.productId,
            'name': item.name,
            'price': item.price,
            'image': item.image,
            'categoryId': item.categoryId,
            'description': item.description,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          };
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (widget.directItems == null) {
        await context.read<CartProvider>().clearCart();
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.black, size: 58),
            title: const Text('Order Placed'),
            content: Text(
              'Your order has been placed successfully.\n\n'
              'Order #${orderReference.id.substring(0, 8).toUpperCase()}',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('View My Orders'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage('Unable to place order: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'CHECKOUT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                children: [
                  _sectionTitle('DELIVERY INFORMATION'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      children: [
                        _textField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _phoneController,
                          label: 'Phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _addressController,
                          label: 'Delivery address',
                          icon: Icons.location_on_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('ORDER ITEMS'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      children: _items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderItem(item),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('PAYMENT METHOD'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      children: [
                        _paymentOption(
                          title: 'Cash on Delivery',
                          icon: Icons.payments_outlined,
                        ),
                        const Divider(),
                        _paymentOption(
                          title: 'Bank Transfer',
                          icon: Icons.account_balance_outlined,
                        ),
                        const Divider(),
                        _paymentOption(
                          title: 'E-Wallet',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('VOUCHER'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'GUCCI10 or FREESHIP',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _applyVoucher,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('ORDER SUMMARY'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      children: [
                        _summaryRow('Subtotal', _subtotal),
                        const SizedBox(height: 10),
                        _summaryRow('Shipping fee', _shippingFee),
                        const SizedBox(height: 10),
                        _summaryRow('Discount', -_discount),
                        const Divider(height: 28),
                        _summaryRow('Total', _total, isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.07),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black45,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Place Order • ${_formatPrice(_total)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label.';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    final imageBytes = _decodeImage(item.image);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageBytes == null
              ? Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF2F2F2),
                  child: const Icon(Icons.image_outlined),
                )
              : Image.memory(
                  imageBytes,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Quantity: ${item.quantity}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatPrice(item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _paymentOption({required String title, required IconData icon}) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: title,
      groupValue: _paymentMethod,
      activeColor: Colors.black,
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _paymentMethod = value;
        });
      },
    );
  }

  Widget _summaryRow(String label, num value, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          _formatPrice(value),
          style: TextStyle(
            fontSize: isTotal ? 19 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
