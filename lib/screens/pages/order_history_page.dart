import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

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

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Processing';
    }

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
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

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'shipping':
        return 'Shipping';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFE8F0FE);
      case 'shipping':
        return const Color(0xFFFFF3E0);
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      case 'pending':
      default:
        return const Color(0xFFF2F2F2);
    }
  }

  Color _statusForeground(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF2457A7);
      case 'shipping':
        return const Color(0xFF9A5B00);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'MY ORDERS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: user == null
          ? _buildMessage(
              icon: Icons.lock_outline,
              title: 'Sign in required',
              message: 'Please sign in to view your orders.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.error_outline,
                    title: 'Unable to load orders',
                    message: snapshot.error.toString(),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                final documents = [...?snapshot.data?.docs];

                documents.sort((first, second) {
                  final firstDate = first.data()['createdAt'];
                  final secondDate = second.data()['createdAt'];

                  final firstMilliseconds = firstDate is Timestamp
                      ? firstDate.millisecondsSinceEpoch
                      : 0;
                  final secondMilliseconds = secondDate is Timestamp
                      ? secondDate.millisecondsSinceEpoch
                      : 0;

                  return secondMilliseconds.compareTo(firstMilliseconds);
                });

                if (documents.isEmpty) {
                  return _buildMessage(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Your completed purchases will appear here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final data = document.data();

                    return _buildOrderCard(
                      context: context,
                      orderId: (data['orderId'] ?? document.id).toString(),
                      data: data,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final totalItems = data['totalItems'] is num
        ? (data['totalItems'] as num).toInt()
        : items.fold<int>(
            0,
            (total, item) => total + ((item['quantity'] as num?)?.toInt() ?? 0),
          );

    final totalPrice = data['totalPrice'] is num
        ? data['totalPrice'] as num
        : 0;
    final status = (data['status'] ?? 'pending').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        _showOrderDetails(
          context: context,
          orderId: orderId,
          data: data,
          items: items,
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${_shortOrderId(orderId)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackground(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusForeground(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _formatDate(data['createdAt']),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (items.isNotEmpty) _buildProductPreview(items.first),
            if (items.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${items.length - 1} more product${items.length > 2 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Text(
                  '$totalItems item${totalItems == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                const Text('Total: ', style: TextStyle(fontSize: 13)),
                Text(
                  _formatPrice(totalPrice),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.black38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreview(Map<String, dynamic> item) {
    final imageBytes = _decodeImage((item['image'] ?? '').toString());
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = item['price'] is num ? item['price'] as num : 0;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageBytes == null
              ? Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFFF2F2F2),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                )
              : Image.memory(
                  imageBytes,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 68,
                      height: 68,
                      color: const Color(0xFFF2F2F2),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['name'] ?? 'Product').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatPrice(price)}  ×  $quantity',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showOrderDetails({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> items,
  }) async {
    final totalPrice = data['totalPrice'] is num
        ? data['totalPrice'] as num
        : 0;
    final status = (data['status'] ?? 'pending').toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      _detailRow('Order ID', orderId),
                      _detailRow('Order date', _formatDate(data['createdAt'])),
                      _detailRow('Status', _statusLabel(status)),
                      const SizedBox(height: 18),
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDetailProduct(item),
                        ),
                      ),
                      const Divider(height: 28),
                      Row(
                        children: [
                          const Text(
                            'Order total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatPrice(totalPrice),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailProduct(Map<String, dynamic> item) {
    final imageBytes = _decodeImage((item['image'] ?? '').toString());
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final subtotal = item['subtotal'] is num
        ? item['subtotal'] as num
        : ((item['price'] as num?) ?? 0) * quantity;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageBytes == null
                ? Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFFECECEC),
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  )
                : Image.memory(
                    imageBytes,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['name'] ?? 'Product').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatPrice(subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) {
      return orderId.toUpperCase();
    }

    return orderId.substring(0, 8).toUpperCase();
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.black45),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
