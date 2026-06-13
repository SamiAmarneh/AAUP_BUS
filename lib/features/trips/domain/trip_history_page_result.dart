import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_profile.dart';

class TripHistoryPageResult {
  const TripHistoryPageResult({
    required this.trips,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TripProfile> trips;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}
