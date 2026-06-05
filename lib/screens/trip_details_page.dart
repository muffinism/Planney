import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../models/trip.dart';
import '../themes/colors.dart';

class TripDetailsPage extends StatefulWidget {
  final int tripId;
  const TripDetailsPage({super.key, required this.tripId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchTripDetails(widget.tripId);
      Provider.of<AuthProvider>(context, listen: false).fetchFriends();
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  String _formatDateTime(DateTime dt) {
    return "${_formatDate(dt)} ${_formatTime(dt)}";
  }

  Map<int, List<ItineraryActivity>> _groupActivitiesByDay(DateTime tripStartDate, List<ItineraryActivity> activities) {
    Map<int, List<ItineraryActivity>> grouped = {};
    activities.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));

    for (var activity in activities) {
      final activityDate = DateTime(activity.startDatetime.year, activity.startDatetime.month, activity.startDatetime.day);
      final startDate = DateTime(tripStartDate.year, tripStartDate.month, tripStartDate.day);
      final dayNumber = activityDate.difference(startDate).inDays + 1;
      
      if (!grouped.containsKey(dayNumber)) {
        grouped[dayNumber] = [];
      }
      grouped[dayNumber]!.add(activity);
    }
    return grouped;
  }

  Color _getDayColor(int dayNumber) {
    final colors = [
      PlanneyColors.green,
      PlanneyColors.yellow,
      PlanneyColors.blue,
      PlanneyColors.purple,
      PlanneyColors.orange,
      PlanneyColors.pink,
    ];
    return colors[(dayNumber - 1) % colors.length];
  }

  void _confirmDelete(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: Text('Are you sure you want to delete "${trip.tripTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<TripProvider>(context, listen: false).deleteTrip(trip.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted.'), backgroundColor: Colors.green));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete trip.'), backgroundColor: Colors.redAccent));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteActivity(ItineraryActivity activity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${activity.agendaTitle}" from the itinerary?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: PlanneyColors.textMuted))
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              
              final tripProvider = Provider.of<TripProvider>(context, listen: false);
              final success = await tripProvider.deleteItineraryActivity(widget.tripId, activity.id);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity deleted!'), backgroundColor: PlanneyColors.green));
                } else {
                  final errorMsg = tripProvider.errorMessage ?? 'Failed to delete activity.';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTripDialog(Trip trip) {
    final titleController = TextEditingController(text: trip.tripTitle);
    DateTime editStart = trip.startDate;
    DateTime editEnd = trip.endDate;
    final List<int> editMemberIds = trip.members.map((m) => m.id).toList();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Edit Trip', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: titleController, 
                        decoration: const InputDecoration(labelText: 'Trip Title', prefixIcon: Icon(Icons.title_rounded)),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Title must be at least 3 characters.' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text('Travel Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PlanneyColors.text)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context, initialDate: editStart,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (d != null) {
                                  setModalState(() {
                                    editStart = d;
                                    if (editEnd.isBefore(editStart)) editEnd = editStart;
                                  });
                                }
                              },
                              icon: const Icon(Icons.date_range_rounded, size: 16, color: PlanneyColors.textMuted),
                              label: Text(_formatDate(editStart), style: const TextStyle(color: PlanneyColors.text)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: PlanneyColors.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context, initialDate: editEnd,
                                  firstDate: editStart,
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (d != null) setModalState(() => editEnd = d);
                              },
                              icon: const Icon(Icons.date_range_rounded, size: 16, color: PlanneyColors.textMuted),
                              label: Text(_formatDate(editEnd), style: const TextStyle(color: PlanneyColors.text)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(context);
                            final success = await Provider.of<TripProvider>(context, listen: false).updateTrip(
                              tripId: trip.id,
                              title: titleController.text.trim(),
                              startDate: editStart,
                              endDate: editEnd,
                              initiatorUsername: trip.initiatorUsername, 
                              memberIds: editMemberIds,
                            );
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Trip updated!' : 'Update failed.'), backgroundColor: success ? Colors.green : Colors.red));
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: PlanneyColors.pink, foregroundColor: Colors.white),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItineraryDialog(Trip trip) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    DateTime startDT = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day, 9, 0);
    DateTime endDT = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day, 10, 0);
    final formKey = GlobalKey<FormState>();

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final tripStart = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
      final tripEnd = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
      
      DateTime pickerInitial = DateTime(initial.year, initial.month, initial.day);
      if (pickerInitial.isBefore(tripStart)) {
        pickerInitial = tripStart;
      } else if (pickerInitial.isAfter(tripEnd)) {
        pickerInitial = tripEnd;
      }

      final date = await showDatePicker(
        context: context,
        initialDate: pickerInitial,
        firstDate: tripStart, 
        lastDate: tripEnd,
      );
      if (date == null) return null;
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time == null) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add Activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Activity Title', prefixIcon: Icon(Icons.directions_run_rounded)),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: detailsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Details / Description', prefixIcon: Icon(Icons.notes_rounded))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final dt = await pickDateTime(startDT); if (dt != null) setModalState(() { startDT = dt; if (endDT.isBefore(startDT)) endDT = startDT.add(const Duration(hours: 1)); }); }, icon: const Icon(Icons.access_time), label: Text(_formatDateTime(startDT)))),
                          const SizedBox(width: 16),
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final dt = await pickDateTime(endDT); if (dt != null) setModalState(() => endDT = dt); }, icon: const Icon(Icons.access_time), label: Text(_formatDateTime(endDT)))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (endDT.isBefore(startDT)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity end date/time cannot be before start date/time.'), backgroundColor: Colors.redAccent));
                              return;
                            }
                            Navigator.pop(context); 
                            final success = await Provider.of<TripProvider>(context, listen: false).addItinerary(tripId: trip.id, agendaTitle: titleController.text.trim(), startDatetime: startDT, endDatetime: endDT, agendaDetails: detailsController.text.trim());
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Activity added!' : 'Failed.'), backgroundColor: success ? Colors.green : Colors.redAccent));
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: PlanneyColors.pink, foregroundColor: Colors.white),
                          child: const Text('Add to Itinerary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditItineraryDialog(Trip trip, ItineraryActivity activity) {
    final titleController = TextEditingController(text: activity.agendaTitle);
    final detailsController = TextEditingController(text: activity.agendaDetails ?? '');
    DateTime startDT = activity.startDatetime;
    DateTime endDT = activity.endDatetime;
    final formKey = GlobalKey<FormState>();

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final tripStart = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
      final tripEnd = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
      
      DateTime pickerInitial = DateTime(initial.year, initial.month, initial.day);
      if (pickerInitial.isBefore(tripStart)) {
        pickerInitial = tripStart;
      } else if (pickerInitial.isAfter(tripEnd)) {
        pickerInitial = tripEnd;
      }

      final date = await showDatePicker(
        context: context,
        initialDate: pickerInitial,
        firstDate: tripStart,
        lastDate: tripEnd,
      );
      if (date == null) return null;
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time == null) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Edit Activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Activity Title', prefixIcon: Icon(Icons.edit_road_rounded)),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: detailsController, 
                        maxLines: 2, 
                        decoration: const InputDecoration(labelText: 'Details / Description', prefixIcon: Icon(Icons.notes_rounded))
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async { 
                                final dt = await pickDateTime(startDT); 
                                if (dt != null) {
                                  setModalState(() { 
                                    startDT = dt; 
                                    if (endDT.isBefore(startDT)) endDT = startDT.add(const Duration(hours: 1)); 
                                  }); 
                                }
                              }, 
                              icon: const Icon(Icons.access_time), 
                              label: Text(_formatDateTime(startDT))
                            )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async { 
                                final dt = await pickDateTime(endDT); 
                                if (dt != null) setModalState(() => endDT = dt); 
                              }, 
                              icon: const Icon(Icons.access_time), 
                              label: Text(_formatDateTime(endDT))
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (endDT.isBefore(startDT)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity end date/time cannot be before start date/time.'), backgroundColor: Colors.redAccent));
                              return;
                            }
                            Navigator.pop(context);
                            
                            final success = await Provider.of<TripProvider>(context, listen: false).updateItineraryActivity(
                              tripId: trip.id, 
                              itineraryId: activity.id, 
                              agendaTitle: titleController.text.trim(), 
                              startDatetime: startDT, 
                              endDatetime: endDT, 
                              agendaDetails: detailsController.text.trim().isNotEmpty ? detailsController.text.trim() : null
                            );
                            
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Activity updated!' : 'Failed to update activity.'), backgroundColor: success ? PlanneyColors.green : Colors.redAccent));
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: PlanneyColors.blue, foregroundColor: Colors.white),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final trip = tripProvider.currentTrip;
    final isCreator = trip != null && authProvider.username == trip.initiatorUsername;

    if (tripProvider.isLoading && trip == null) {
      return const Scaffold(backgroundColor: PlanneyColors.white, body: Center(child: CircularProgressIndicator(color: PlanneyColors.pink)));
    }

    if (trip == null) {
      return Scaffold(backgroundColor: PlanneyColors.white, appBar: AppBar(title: const Text('Trip Details')), body: Center(child: ElevatedButton(onPressed: () => tripProvider.fetchTripDetails(widget.tripId), child: const Text('Retry Loading'))));
    }

    final groupedItinerary = _groupActivitiesByDay(trip.startDate, trip.itineraries);

    return Scaffold(
      backgroundColor: PlanneyColors.white, 
      appBar: AppBar(
        backgroundColor: PlanneyColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: PlanneyColors.text)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PlanneyColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: isCreator ? [
          IconButton(icon: const Icon(Icons.edit_note_rounded, color: PlanneyColors.text, size: 28), onPressed: () => _showEditTripDialog(trip)),
          IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 26), onPressed: () => _confirmDelete(trip)),
          const SizedBox(width: 8),
        ] : null,
      ),
      body: RefreshIndicator(
        color: PlanneyColors.pink,
        onRefresh: () => tripProvider.fetchTripDetails(widget.tripId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PlanneyColors.green, 
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: PlanneyColors.green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6)),
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
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Upcoming Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const Icon(Icons.flight_takeoff_rounded, color: Colors.black87, size: 28),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    trip.tripTitle,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5, height: 1.1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(trip.startDate)} — ${_formatDate(trip.endDate)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.person, size: 14, color: Colors.black)),
                      const SizedBox(width: 8),
                      Text('Organized by @${trip.initiatorUsername}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Itinerary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
            ),
            
            const SizedBox(height: 24),
            
            if (groupedItinerary.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: PlanneyColors.bg, borderRadius: BorderRadius.circular(24), border: Border.all(color: PlanneyColors.divider)),
                child: const Center(child: Text('No activities added yet.\nStart planning your timeline!', textAlign: TextAlign.center, style: TextStyle(color: PlanneyColors.textMuted, fontWeight: FontWeight.w600))),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: groupedItinerary.entries.map((entry) => _buildDayGroupBlock(entry.key, entry.value)).toList(),
                ),
              ),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Travel Buddies', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PlanneyColors.bg, 
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ...trip.members.map((member) {
                    final isOrganizer = member.username == trip.initiatorUsername;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20, backgroundColor: PlanneyColors.purple,
                            child: Text(member.username.isNotEmpty ? member.username[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${member.username}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PlanneyColors.text)),
                                Text(isOrganizer ? 'Organizer' : 'Buddy', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PlanneyColors.textMuted)),
                              ],
                            ),
                          ),
                          if (isOrganizer)
                            const Icon(Icons.verified_rounded, color: PlanneyColors.pink, size: 24),
                        ],
                      ),
                    );
                  }),

                  if (isCreator) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showInviteFriendsDialog(trip),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: PlanneyColors.pink, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Invite More Friends', style: TextStyle(color: PlanneyColors.pink, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PlanneyColors.pink,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showAddItineraryDialog(trip),
        icon: const Icon(Icons.add_location_alt_rounded, size: 24),
        label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildDayGroupBlock(int dayNumber, List<ItineraryActivity> activities) {
    final dayColor = _getDayColor(dayNumber);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: dayColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: dayColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Text('Day $dayNumber', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
        ),
        
        ...activities.asMap().entries.map((entry) {
          final isLast = entry.key == activities.length - 1;
          return _buildActivityCardTile(entry.value, dayColor, isLast);
        }),
      ],
    );
  }

  Widget _buildActivityCardTile(ItineraryActivity activity, Color dayColor, bool isLast) {
    IconData iconData = Icons.explore_rounded;
    final titleLower = activity.agendaTitle.toLowerCase();
    
    if (titleLower.contains('hotel') || titleLower.contains('check')) iconData = Icons.hotel_rounded;
    else if (titleLower.contains('eat') || titleLower.contains('lunch') || titleLower.contains('dinner') || titleLower.contains('breakfast')) iconData = Icons.restaurant_rounded;
    else if (titleLower.contains('boat') || titleLower.contains('sea')) iconData = Icons.sailing_rounded;
    else if (titleLower.contains('flight') || titleLower.contains('airport') || titleLower.contains('plane')) iconData = Icons.flight_takeoff_rounded;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 16, height: 16, margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(color: dayColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: dayColor.withOpacity(0.5), blurRadius: 4)]),
                ),
                if (!isLast) Expanded(child: Container(width: 3, color: dayColor.withOpacity(0.3))),
              ],
            ),
          ),
      
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PlanneyColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dayColor.withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dayColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: 20, color: dayColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(activity.agendaTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                      ),
                    ],
                  ),
                  
                  if (activity.agendaDetails != null && activity.agendaDetails!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(activity.agendaDetails!, style: const TextStyle(fontSize: 14, color: PlanneyColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: PlanneyColors.bg, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: PlanneyColors.textMuted),
                            const SizedBox(width: 6),
                            Text(_formatTime(activity.startDatetime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: dayColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text('Confirmed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: dayColor.withOpacity(0.8).withRed(0).withGreen(0).withBlue(0))),
                      ),
                      
                      const Spacer(),
                      
                      InkWell(
                        onTap: () {
                          final trip = Provider.of<TripProvider>(context, listen: false).currentTrip!;
                            _showEditItineraryDialog(trip, activity);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: PlanneyColors.bg, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit_note_rounded, size: 18, color: PlanneyColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _confirmDeleteActivity(activity),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteFriendsDialog(Trip trip) {
    List<int> editMemberIds = trip.members.map((m) => m.id).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: PlanneyColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invite Buddies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                  const SizedBox(height: 8),
                  const Text('Select friends to join this adventure.', style: TextStyle(color: PlanneyColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) return const Center(child: CircularProgressIndicator(color: PlanneyColors.pink));
                      if (auth.friends.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No friends found. Add them in the Friends tab first!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: auth.friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final friend = auth.friends[index];
                          final friendId = friend['id'] as int;
                          final friendName = friend['username'] as String;
                          final isSelected = editMemberIds.contains(friendId);

                          return CheckboxListTile(
                            title: Text('@$friendName', style: const TextStyle(fontWeight: FontWeight.w800, color: PlanneyColors.text)),
                            value: isSelected,
                            activeColor: PlanneyColors.pink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tileColor: PlanneyColors.bg,
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  editMemberIds.add(friendId);
                                } else {
                                  editMemberIds.remove(friendId);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); 
                        
                        final tripProvider = Provider.of<TripProvider>(context, listen: false);
                        final success = await tripProvider.updateTrip(
                          tripId: trip.id,
                          title: trip.tripTitle, 
                          startDate: trip.startDate,
                          endDate: trip.endDate,
                          initiatorUsername: trip.initiatorUsername, 
                          memberIds: editMemberIds, 
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? 'Travel buddies updated!' : 'Failed to update buddies.'),
                            backgroundColor: success ? PlanneyColors.green : Colors.redAccent,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: PlanneyColors.pink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
