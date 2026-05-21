import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.resourceType,
    required this.format,
    required this.bytes,
  });

  final String publicId;
  final String secureUrl;
  final String resourceType;
  final String format;
  final int bytes;

  bool get isVideo => resourceType == 'video';

  String thumbnailUrl({int width = 900, int height = 1200}) {
    if (!isVideo) {
      return secureUrl;
    }
    return 'https://res.cloudinary.com/${CloudinaryService.cloudName}/video/upload/'
        'so_auto,w_$width,h_$height,c_fill,q_auto,f_jpg/$publicId.jpg';
  }

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      publicId: json['public_id'] as String? ?? '',
      secureUrl: json['secure_url'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? 'image',
      format: json['format'] as String? ?? '',
      bytes: json['bytes'] as int? ?? 0,
    );
  }
}

class CloudinaryService {
  const CloudinaryService();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dg0grjaj3',
  );

  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'shootr_unsigned',
  );

  Future<CloudinaryUploadResult> uploadFile({
    required XFile file,
    required String folder,
    List<String> tags = const <String>[],
  }) async {
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) {
      throw const CloudinaryException(
        'Cloudinary is missing a cloud name or unsigned upload preset.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/auto/upload'),
    );
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    if (tags.isNotEmpty) {
      request.fields['tags'] = tags.join(',');
    }

    final filename = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[\\/]')).last;
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path, filename: filename),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw CloudinaryException(
        error?['message'] as String? ?? 'Cloudinary upload failed.',
      );
    }

    final result = CloudinaryUploadResult.fromJson(decoded);
    if (result.secureUrl.isEmpty) {
      throw const CloudinaryException('Cloudinary did not return a media URL.');
    }
    return result;
  }
}

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);

  final String message;

  @override
  String toString() => message;
}
