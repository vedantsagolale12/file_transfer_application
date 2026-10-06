import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class ChecksumUtils {
  ChecksumUtils._();

  static Future<String> computeSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();

    return output.events.single.toString();
  }

  static Future<String> computeSha256FromBytes(List<int> bytes) async {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool compareChecksums(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }
}
