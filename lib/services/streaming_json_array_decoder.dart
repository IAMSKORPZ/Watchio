import 'dart:async';
import 'dart:convert';

class StreamingJsonArrayDecoder {
  Stream<Map<String, dynamic>> decodeObjects(Stream<String> input) async* {
    final buffer = StringBuffer();
    var inString = false;
    var escaped = false;
    var depth = 0;
    var capturing = false;

    await for (final chunk in input) {
      for (var i = 0; i < chunk.length; i++) {
        final char = chunk[i];

        if (escaped) {
          if (capturing) buffer.write(char);
          escaped = false;
          continue;
        }
        if (char == '\\') {
          if (capturing) buffer.write(char);
          escaped = inString;
          continue;
        }
        if (char == '"') {
          if (capturing) buffer.write(char);
          inString = !inString;
          continue;
        }
        if (inString) {
          if (capturing) buffer.write(char);
          continue;
        }

        if (char == '{') {
          capturing = true;
          depth++;
          buffer.write(char);
        } else if (char == '}') {
          if (capturing) buffer.write(char);
          depth--;
          if (depth == 0) {
            final decoded = jsonDecode(buffer.toString());
            buffer.clear();
            capturing = false;
            if (decoded is Map<String, dynamic>) {
              yield decoded;
            } else if (decoded is Map) {
              yield Map<String, dynamic>.from(decoded);
            }
          }
        } else if (capturing) {
          buffer.write(char);
        }
      }
    }
  }
}
