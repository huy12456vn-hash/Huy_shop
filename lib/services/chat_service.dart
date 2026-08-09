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

  // Detects whether the user's message is Vietnamese or English based on
  // Vietnamese diacritics. This is a lightweight heuristic — no external
  // language-detection package is used, so it isn't 100% accurate for very
  // short or ambiguous messages, but it works well for normal chat text.
  static final RegExp _vietnameseDiacritics = RegExp(
    r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
    r'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
  );

  String _detectLanguage(String text) {
    return _vietnameseDiacritics.hasMatch(text) ? 'vi' : 'en';
  }

  Future<void> sendUserMessage(String text) async {
    final String message = text.trim();
    if (message.isEmpty) return;

    final String language = _detectLanguage(message);

    await _messagesRef.add({
      'text': message,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    String botReplyText;
    List<String> productIds = [];

    try {
      final result = await askAI(message, language);
      botReplyText = result.text;
      productIds = result.productIds;
    } catch (e) {
      print('REAL ERROR: $e');
      botReplyText = language == 'vi'
          ? 'Xin lỗi, chatbot đang gặp sự cố. Vui lòng thử lại sau.'
          : 'Sorry, the chatbot is having an issue. Please try again later.';
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

  String _buildSystemPrompt(String catalogText, String language) {
    final String languageInstruction = language == 'vi'
        ? 'Khách hàng đang nhắn tin bằng tiếng Việt. Hãy trả lời bằng tiếng Việt, lịch sự và như một nhân viên bán hàng.'
        : 'The customer is messaging in English. Reply in English, politely, like a sales associate.';

    return '''
Bạn là trợ lý bán hàng cho cửa hàng Gucci. / You are a sales assistant for a Gucci store.

$languageInstruction

Dưới đây là danh sách sản phẩm hiện có (id, tên, giá, danh mục). Chỉ đề xuất các sản phẩm có trong danh sách này, không bịa sản phẩm không có:
Below is the current product catalog (id, name, price, category). Only recommend products from this list, never invent products that aren't here:
$catalogText

QUAN TRỌNG - định dạng bắt buộc / IMPORTANT - required format:
Sau khi trả lời khách hàng bình thường, luôn thêm một dòng cuối cùng đúng theo định dạng:
After your normal reply to the customer, always add one final line in exactly this format:
PRODUCT_IDS: id1,id2
(liệt kê các id sản phẩm bạn vừa giới thiệu, cách nhau bằng dấu phẩy / list the ids of the products you just recommended, comma-separated)
Nếu không giới thiệu sản phẩm cụ thể nào, hãy viết / If you didn't recommend any specific product, write: PRODUCT_IDS: none
Không thêm nội dung nào sau dòng PRODUCT_IDS. / Do not add anything after the PRODUCT_IDS line.
''';
  }

  Future<_AIResult> askAI(String message, String language) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'GROQ_API_KEY is not configured. Run the app with: flutter run --dart-define=GROQ_API_KEY=your_key',
      );
    }

    final catalog = await _fetchProductCatalog();
    final catalogText = catalog
        .map((p) =>
            '- id: ${p['id']}, name: ${p['name']}, price: \$${p['price']}, category: ${p['category']}')
        .join('\n');

    final systemPrompt = _buildSystemPrompt(catalogText, language);

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