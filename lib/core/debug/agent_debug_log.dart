import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

// #region agent log
const _logPath =
    '/Users/aymanyehia/Documents/GitHub/AAUP_BUS/.cursor/debug-ce4a34.log';
const _ingestUrl =
    'http://127.0.0.1:7691/ingest/34074152-cccc-4af4-80ad-d51e0538ad9d';

Future<void> agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'pre-fix',
}) async {
  final payload = jsonEncode({
    'sessionId': 'ce4a34',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? <String, dynamic>{},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });

  debugPrint('[AGENT_DEBUG] $payload');

  if (!kIsWeb) {
    try {
      File(_logPath).writeAsStringSync('$payload\n', mode: FileMode.append);
    } catch (_) {}

    final hosts = <String>[
      '127.0.0.1',
      if (Platform.isAndroid) '10.0.2.2',
    ];

    for (final host in hosts) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(
          Uri.parse(_ingestUrl.replaceFirst('127.0.0.1', host)),
        );
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Debug-Session-Id', 'ce4a34');
        request.write(payload);
        await request.close();
        client.close();
        break;
      } catch (_) {}
    }
  }
}
// #endregion
