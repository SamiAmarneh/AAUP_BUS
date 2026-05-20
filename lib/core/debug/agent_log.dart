import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AgentLog {
  static const _ingestUrl =
      'http://127.0.0.1:7691/ingest/34074152-cccc-4af4-80ad-d51e0538ad9d';
  static const _logPath =
      '/Users/aymanyehia/Documents/GitHub/AAUP_BUS/.cursor/debug-3d79ac.log';
  static const _sessionId = '3d79ac';

  static void write({
    required String location,
    required String message,
    required String hypothesisId,
    Map<String, Object?>? data,
    String runId = 'role-routing',
  }) {
    final payload = <String, Object?>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'hypothesisId': hypothesisId,
      'data': data ?? <String, Object?>{},
      'runId': runId,
    };
    // #region agent log
    debugPrint('[agent-log] ${jsonEncode(payload)}');
    () async {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse(_ingestUrl));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Debug-Session-Id', _sessionId);
        request.write(jsonEncode(payload));
        await request.close();
        client.close();
      } catch (_) {
        try {
          File(_logPath).writeAsStringSync(
            '${jsonEncode(payload)}\n',
            mode: FileMode.append,
          );
        } catch (_) {}
      }
    }();
    // #endregion
  }
}
