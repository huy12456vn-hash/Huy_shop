import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  final CollectionReference<Map<String, dynamic>> _messagesRef =
      _firestore.collection('chat_messages');

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream() {
    return _messagesRef.orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> sendUserMessage(String text) async {
    final String message = text.trim();
    if (message.isEmpty) return;

    await _messagesRef.add({
      'text': message,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    String botReplyText;
    List<String> productIds = [];

    try {
      final result = await askAI(message);
      botReplyText = result.text;
      productIds = result.productIds;
    } catch (e) {
      print('LỖI THẬT: $e');
      botReplyText = 'Xin lỗi, chatbot đang gặp lỗi. Vui lòng thử lại sau.';
    }

    await _messagesRef.add({
      'text': botReplyText,
      'sender': 'bot',
      'productIds': productIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProductCatalog() async {
    final snapshot = await _firestore.collection('products').limit(40).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'price': data['price'] ?? 0,
        'category': data['categoryName'] ?? '',
      };
    }).toList();
  }

  Future<_AIResult> askAI(String message) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'Chưa cấu hình GROQ_API_KEY. Chạy app với: flutter run --dart-define=GROQ_API_KEY=your_key',
      );
    }

    final catalog = await _fetchProductCatalog();
    final catalogText = catalog
        .map((p) =>
            '- id: ${p['id']}, tên: ${p['name']}, giá: \$${p['price']}, danh mục: ${p['category']}')
        .join('\n');

    final systemPrompt = '''
Bạn là chatbot tư vấn của cửa hàng Gucci.

- Trả lời bằng tiếng Việt, lịch sự, như một nhân viên bán hàng.
- Dưới đây là danh sách sản phẩm hiện có (id, tên, giá, danh mục). Chỉ được giới thiệu sản phẩm có trong danh sách này, không được bịa sản phẩm không có:
$catalogText

QUAN TRỌNG - định dạng bắt buộc:
Sau khi trả lời khách hàng bình thường, LUÔN thêm một dòng cuối cùng theo đúng định dạng:
PRODUCT_IDS: id1,id2
(liệt kê id của các sản phẩm bạn vừa giới thiệu, cách nhau bằng dấu phẩy)
Nếu không giới thiệu sản phẩm cụ thể nào, viết: PRODUCT_IDS: none
Không thêm nội dung nào khác sau dòng PRODUCT_IDS.
''';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': message},
        ],
      }),
    );

    if (response.statusCode != 200) {
      print('Groq error ${response.statusCode}: ${response.body}');
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String raw =
        data['choices'][0]['message']['content']?.toString() ?? '';

    return _parseAIResponse(raw);
  }

  _AIResult _parseAIResponse(String raw) {
    const marker = 'PRODUCT_IDS:';
    final idx = raw.lastIndexOf(marker);

    if (idx == -1) {
      return _AIResult(text: raw.trim(), productIds: []);
    }

    final textPart = raw.substring(0, idx).trim();
    final idsPart = raw.substring(idx + marker.length).trim();

    if (idsPart.toLowerCase() == 'none' || idsPart.isEmpty) {
      return _AIResult(text: textPart, productIds: []);
    }

    final ids = idsPart
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
        .toList();

    return _AIResult(text: textPart, productIds: ids);
  }
}

class _AIResult {
  final String text;
  final List<String> productIds;

  _AIResult({required this.text, required this.productIds});
}