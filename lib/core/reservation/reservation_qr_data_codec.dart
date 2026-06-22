import 'dart:convert';

class ReservationQrPayload {
  const ReservationQrPayload({
    required this.id,
    required this.trip,
    required this.bus,
  });

  final String id;
  final String trip;
  final String bus;
}

class ReservationQrDataCodecException implements Exception {
  const ReservationQrDataCodecException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class ReservationQrDataCodec {
  static const String idKey = 'id';
  static const String tripKey = 'trip';
  static const String busKey = 'bus';

  static String encodeReservationQrData({
    required String id,
    required String trip,
    required String bus,
  }) {
    return jsonEncode({
      idKey: id,
      tripKey: trip,
      busKey: bus,
    });
  }

  static ReservationQrPayload decodeReservationQrData(String rawData) {
    final decoded = jsonDecode(rawData);
    if (decoded is! Map<String, dynamic>) {
      throw const ReservationQrDataCodecException(
        'QR data must be a JSON object.',
      );
    }

    return ReservationQrPayload(
      id: _readRequiredString(decoded, idKey),
      trip: _readRequiredString(decoded, tripKey),
      bus: _readRequiredString(decoded, busKey),
    );
  }

  static String _readRequiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw ReservationQrDataCodecException(
        'QR data field "$key" must be a non-empty string.',
      );
    }
    return value;
  }
}
