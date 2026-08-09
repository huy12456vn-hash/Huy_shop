import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../l10n/app_strings.dart';
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

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    final t = AppStrings.of(context);

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
          _discount > 0 ? t.voucherApplied : t.voucherInvalid,
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final t = AppStrings.of(context);

    if (_items.isEmpty) {
      _showMessage(t.cartEmptyForCheckout);
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(t.signInBeforeOrder);
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

      final t2 = AppStrings.of(context);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.black, size: 58),
            title: Text(t2.orderPlacedTitle),
            content: Text(
              t2.orderPlacedContent(
                orderReference.id.substring(0, 8).toUpperCase(),
              ),
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
                child: Text(t2.viewMyOrders),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage(AppStrings.of(context).unableToPlaceOrder(error.toString()));
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
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final t = AppStrings(locale);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              t.checkoutTitle,
              style: const TextStyle(
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
                      _sectionTitle(t.deliveryInfoSection),
                      const SizedBox(height: 10),
                      _buildCard(
                        child: Column(
                          children: [
                            _textField(
                              controller: _nameController,
                              label: t.fullNameLabel,
                              icon: Icons.person_outline,
                              t: t,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _phoneController,
                              label: t.phoneNumberLabel,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              t: t,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _addressController,
                              label: t.deliveryAddressLabel,
                              icon: Icons.location_on_outlined,
                              maxLines: 3,
                              t: t,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(t.orderItemsSection),
                      const SizedBox(height: 10),
                      _buildCard(
                        child: Column(
                          children: _items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildOrderItem(item, t),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(t.paymentMethodSection),
                      const SizedBox(height: 10),
                      _buildCard(
                        child: Column(
                          children: [
                            _paymentOption(
                              value: 'Cash on Delivery',
                              label: t.cashOnDelivery,
                              icon: Icons.payments_outlined,
                            ),
                            const Divider(),
                            _paymentOption(
                              value: 'Bank Transfer',
                              label: t.bankTransfer,
                              icon: Icons.account_balance_outlined,
                            ),
                            const Divider(),
                            _paymentOption(
                              value: 'E-Wallet',
                              label: t.eWallet,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(t.voucherSection),
                      const SizedBox(height: 10),
                      _buildCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _voucherController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: t.voucherHint,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _applyVoucher,
                              child: Text(t.applyButton),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(t.orderSummarySection),
                      const SizedBox(height: 10),
                      _buildCard(
                        child: Column(
                          children: [
                            _summaryRow(t.subtotalLabel, _subtotal, t),
                            const SizedBox(height: 10),
                            _summaryRow(t.shippingFeeLabel, _shippingFee, t),
                            const SizedBox(height: 10),
                            _summaryRow(t.discountLabel, -_discount, t),
                            const Divider(height: 28),
                            _summaryRow(
                              t.totalSummaryLabel,
                              _total,
                              t,
                              isTotal: true,
                            ),
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
                        t.placeOrderButton(t.formatPrice(_total)),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
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
    required AppStrings t,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return t.pleaseEnterField(label);
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

  Widget _buildOrderItem(CartItemModel item, AppStrings t) {
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
                t.quantityLabel(item.quantity),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          t.formatPrice(item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _paymentOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: value,
      groupValue: _paymentMethod,
      activeColor: Colors.black,
      secondary: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onChanged: (newValue) {
        if (newValue == null) {
          return;
        }

        setState(() {
          _paymentMethod = newValue;
        });
      },
    );
  }

  Widget _summaryRow(
    String label,
    num value,
    AppStrings t, {
    bool isTotal = false,
  }) {
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
          t.formatPrice(value),
          style: TextStyle(
            fontSize: isTotal ? 19 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}