import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class TelegramService {
  static const _botToken = '8236588895:AAF7zCz196lk2jogsW7_MnTVaiZyvi_n12E';
  static const _chatId = '-5164569115';

  static bool get isConfigured =>
      _botToken.trim().isNotEmpty && _chatId.trim().isNotEmpty;

  static Future<String?> uploadPhotoToGroup({
    required XFile file,
    required String caption,
  }) async {
    if (!isConfigured) return null;

    final uri = Uri.parse('https://api.telegram.org/bot$_botToken/sendPhoto');
    final request = http.MultipartRequest('POST', uri)
      ..fields['chat_id'] = _chatId
      ..fields['caption'] = caption;

    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: file.name.isEmpty ? 'bukti_bayar.jpg' : file.name,
      ),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      return null;
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final ok = data['ok'] == true;
    if (!ok) return null;

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final directPhotoUrl = await _resolvePhotoUrl(result);
    if (directPhotoUrl != null) {
      return directPhotoUrl;
    }

    final messageId = result['message_id'];
    if (messageId == null) return null;
    return _buildMessageLink(messageId.toString());
  }

  static Future<String?> _resolvePhotoUrl(Map<String, dynamic> result) async {
    final photos = result['photo'];
    if (photos is! List || photos.isEmpty) return null;

    final lastPhoto = photos.last;
    if (lastPhoto is! Map<String, dynamic>) return null;
    final fileId = lastPhoto['file_id'];
    if (fileId is! String || fileId.isEmpty) return null;

    final getFileUri = Uri.parse(
        'https://api.telegram.org/bot$_botToken/getFile?file_id=$fileId');
    final getFileResponse = await http.get(getFileUri);
    if (getFileResponse.statusCode < 200 || getFileResponse.statusCode >= 300) {
      return null;
    }

    final getFileData =
        jsonDecode(getFileResponse.body) as Map<String, dynamic>;
    if (getFileData['ok'] != true) return null;
    final getFileResult = getFileData['result'] as Map<String, dynamic>?;
    final filePath = getFileResult?['file_path'];
    if (filePath is! String || filePath.isEmpty) return null;

    return 'https://api.telegram.org/file/bot$_botToken/$filePath';
  }

  static String? _buildMessageLink(String messageId) {
    final raw = _chatId.trim();
    if (!raw.startsWith('-100')) {
      return 'telegram_uploaded:$messageId';
    }
    final internalId = raw.substring(4);
    return 'https://t.me/c/$internalId/$messageId';
  }
}
