import 'dart:typed_data';

enum LogoImageType { png, jpeg, webp }

extension LogoImageTypeX on LogoImageType {
  String get contentType {
    switch (this) {
      case LogoImageType.png:
        return 'image/png';
      case LogoImageType.jpeg:
        return 'image/jpeg';
      case LogoImageType.webp:
        return 'image/webp';
    }
  }
}

bool doesLogoExtensionMatchType(String extension, LogoImageType type) {
  final normalized = extension.trim().toLowerCase();
  return switch (type) {
    LogoImageType.png => normalized == 'png',
    LogoImageType.jpeg => normalized == 'jpg' || normalized == 'jpeg',
    LogoImageType.webp => normalized == 'webp',
  };
}

String? extractLogoExtension(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == fileName.length - 1) {
    return null;
  }
  return fileName.substring(dotIndex + 1).toLowerCase();
}

LogoImageType? detectLogoImageType(Uint8List bytes) {
  if (_startsWithSignature(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
    return LogoImageType.png;
  }
  if (_startsWithSignature(bytes, const [0xFF, 0xD8, 0xFF])) {
    return LogoImageType.jpeg;
  }
  if (_startsWithSignature(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      bytes.length > 11 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return LogoImageType.webp;
  }
  return null;
}

bool _startsWithSignature(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) {
    return false;
  }
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      return false;
    }
  }
  return true;
}
