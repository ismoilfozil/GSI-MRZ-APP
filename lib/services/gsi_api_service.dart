import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/verification_response.dart';

class GsiApiService {
  static const _baseUrl = 'https://dev-gateway.tadi.uz';

  static Future<VerificationResponse> verify({
    required String docNumber,
    required String birthDate,
    required File videoFile,
  }) async {
    final videoBytes = await videoFile.readAsBytes();
    final videoBase64 = base64Encode(videoBytes);
    final requestId = const Uuid().v4();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/gsi/verify_b64'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'birth_date': birthDate,
        'clientId': 'unknown',
        'doc_number': docNumber,
        'doc_pinfl': '',
        'requestId': requestId,
        'serviceName': 'unknown',
        'token': videoBase64,
      }),
    );

    if (response.statusCode == 200) {
      return VerificationResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
