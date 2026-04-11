import 'package:flutter/material.dart';
import 'package:pro2/features/student/domain/models/trip_model.dart';
import 'trip_details_page.dart';

class BrowseTripsPage extends StatefulWidget {
  const BrowseTripsPage({super.key});

  @override
  State<BrowseTripsPage> createState() => _BrowseTripsPageState();
}

class _BrowseTripsPageState extends State<BrowseTripsPage> {
  final List<String> cities = [
    'All Cities',
    'Jenin',
    'Tulkarm',
    'Nablus',
    'Ramallah',
    'Bethlehem',
    'Hebron',
  ];

  final List<Trip> trips = [
    Trip(
      city: 'Jenin',
      route: 'Jenin → AAUP',
      company: 'Taneen Bus Company',
      price: 15,
      from: 'Jenin Bus Terminal',
      to: 'Arab American University',
      departure: '07:00',
      availableSeats: 8,
      totalSeats: 45,
    ),
    Trip(
      city: 'Jenin',
      route: 'Jenin → AAUP',
      company: 'Al-Quds Transport',
      price: 15,
      from: 'Jenin City Center',
      to: 'Arab American University',
      departure: '08:30',
      availableSeats: 12,
      totalSeats: 45,
    ),
    Trip(
      city: 'Jenin',
      route: 'Jenin → AAUP',
      company: 'Palestine Transport',
      price: 15,
      from: 'Jenin Bus Terminal',
      to: 'Arab American University',
      departure: '10:00',
      availableSeats: 25,
      totalSeats: 50,
    ),
    Trip(
      city: 'Tulkarm',
      route: 'Tulkarm → AAUP',
      company: 'Jenin Express',
      price: 12,
      from: 'Tulkarm Central Station',
      to: 'Arab American University',
      departure: '07:30',
      availableSeats: 5,
      totalSeats: 40,
    ),
    Trip(
      city: 'Nablus',
      route: 'Nablus → AAUP',
      company: 'Al-Quds Transport',
      price: 10,
      from: 'Nablus Old City',
      to: 'Arab American University',
      departure: '08:00',
      availableSeats: 15,
      totalSeats: 45,
    ),
    Trip(
      city: 'Ramallah',
      route: 'Ramallah → AAUP',
      company: 'Jenin Express',
      price: 18,
      from: 'Ramallah Center',
      to: 'Arab American University',
      departure: '07:15',
      availableSeats: 10,
      totalSeats: 40,
    ),
    Trip(
      city: 'Bethlehem',
      route: 'Bethlehem → AAUP',
      company: 'Palestine Transport',
      price: 20,
      from: 'Bethlehem Station',
      to: 'Arab American University',
      departure: '06:30',
      availableSeats: 30,
      totalSeats: 50,
    ),
  ];

  late List<Trip> filteredTrips;
  String selectedCity = 'All Cities';

  @override
  void initState() {
    super.initState();
    filteredTrips = trips;
  }

  void _filterTrips(String city) {
    setState(() {
      selectedCity = city;
      if (city == 'All Cities') {
        filteredTrips = trips;
      } else {
        filteredTrips = trips.where((trip) => trip.city == city).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Trip>> groupedTrips = {};
    for (var trip in filteredTrips) {
      groupedTrips.putIfAbsent(trip.city, () => []).add(trip);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Trips',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose your departure city',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // City Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cities.map((city) {
                    final isSelected = selectedCity == city;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (_) => _filterTrips(city),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF62758A),
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Trips List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...groupedTrips.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // City Header
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F3A57),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.length} trips available',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF62758A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Trip Cards
                        ...entry.value.map((trip) => _buildTripCard(trip)),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final isLowSeats = trip.availableSeats <= 8;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 14,
                          color: Color(0xFF62758A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trip.company,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF62758A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₪ ${trip.price}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'per seat',
                      style: TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // From and To
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 8, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(fontSize: 11, color: Color(0xFF62758A)),
                    ),
                    Text(
                      trip.from,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(color: Colors.grey[300], thickness: 1.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86F),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 8, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(fontSize: 11, color: Color(0xFF62758A)),
                    ),
                    Text(
                      trip.to,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Departure and Available
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Color(0xFF62758A),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Departure',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF62758A),
                        ),
                      ),
                      Text(
                        trip.departure,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F3A57),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    size: 18,
                    color: Color(0xFF00A86F),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF62758A),
                        ),
                      ),
                      Text(
                        '${trip.availableSeats}/${trip.totalSeats} seats',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A86F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Book Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDetailsPage(trip: trip),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Low Seats Warning
          if (isLowSeats)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: Color(0xFFE74C3C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Only ${trip.availableSeats} seats left!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
