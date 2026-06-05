import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../themes/colors.dart';
import '../widgets/navbar.dart';
import '../widgets/header.dart';
import 'trip_details_page.dart';

class TripDashboardPage extends StatefulWidget {
  const TripDashboardPage({super.key});

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchTrips();
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  IconData _getTripIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('beach') || titleLower.contains('coast') || titleLower.contains('sea')) return Icons.sailing_rounded;
    if (titleLower.contains('mountain') || titleLower.contains('hike')) return Icons.terrain_rounded;
    if (titleLower.contains('city') || titleLower.contains('town')) return Icons.location_city_rounded;
    return Icons.explore_rounded;
  }

  Color _getSolidCardColor(int index) {
    final colors = [
      PlanneyColors.green,
      PlanneyColors.yellow,
      PlanneyColors.blue,
      PlanneyColors.purple,
      PlanneyColors.orange,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      backgroundColor: PlanneyColors.white,
      appBar: const PlanneyHeader(title: 'Dashboard'),
      
      body: RefreshIndicator(
        color: PlanneyColors.pink,
        onRefresh: () => tripProvider.fetchTrips(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PlanneyColors.pink,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: PlanneyColors.pink.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${authProvider.username ?? 'Traveler'}! 🌍',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ready to coordinate your next adventure?',
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Trips',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PlanneyColors.text),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (tripProvider.isLoading && tripProvider.trips.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: PlanneyColors.pink)))
            else if (tripProvider.trips.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tripProvider.trips.length,
                itemBuilder: (context, index) {
                  final trip = tripProvider.trips[index];
                  return _buildSolidTripCard(trip, index);
                },
              ),
              
            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: const PlanneyNavbar(
        currentIndex: 0, 
      ),
    );
  }

  Widget _buildSolidTripCard(Trip trip, int index) {
    final cardColor = _getSolidCardColor(index);
    final iconData = _getTripIcon(trip.tripTitle);
    
    final now = DateTime.now();
    final isPast = trip.endDate.isBefore(now);
    final statusText = isPast ? 'Completed' : 'Upcoming';
    final badgeColor = isPast ? Colors.black54 : Colors.black87;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailsPage(tripId: trip.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: cardColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    statusText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Icon(iconData, color: Colors.black87, size: 28),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(
              trip.tripTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(trip.startDate)} — ${_formatDate(trip.endDate)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAvatarStack(trip.members),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<TripMember> members) {
    if (members.isEmpty) return const SizedBox();
    
    int displayCount = members.length > 3 ? 3 : members.length;
    int remaining = members.length - 3;

    return Row(
      children: [
        for (int i = 0; i < displayCount; i++)
          Align(
            widthFactor: 0.75,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.black87,
                child: Text(
                  members[i].username.isNotEmpty ? members[i].username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        if (remaining > 0)
          Align(
            widthFactor: 0.75,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: PlanneyColors.pink,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: PlanneyColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PlanneyColors.divider),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 64, color: PlanneyColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No trips found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PlanneyColors.text),
          ),
          SizedBox(height: 8),
          Text(
            'Hit the create button below to start planning your first group adventure!',
            textAlign: TextAlign.center,
            style: TextStyle(color: PlanneyColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}