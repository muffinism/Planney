import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../themes/colors.dart';
import '../widgets/navbar.dart';
import '../widgets/header.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  final List<int> _selectedFriendIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchFriends();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDateRange() {
    if (_startDate == null || _endDate == null) return "Pick dates";
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final startStr = "${months[_startDate!.month - 1]} ${_startDate!.day}";
    final endStr = "${months[_endDate!.month - 1]} ${_endDate!.day}, ${_endDate!.year}";
    return "$startStr - $endStr";
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            platform: TargetPlatform.windows, 
            colorScheme: ColorScheme.light(
              primary: PlanneyColors.blue, 
              onPrimary: Colors.black87, 
              primaryContainer: PlanneyColors.blue.withValues(alpha: 0.3), 
              onPrimaryContainer: Colors.black87,
              surface: PlanneyColors.white,
              onSurface: PlanneyColors.text,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your travel dates.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    
    final success = await tripProvider.createTrip(
      title: _titleController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      initiatorUsername: authProvider.username ?? 'Unknown',
      memberIds: _selectedFriendIds,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip initialized! Let\'s build the itinerary.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tripProvider.errorMessage ?? 'Failed to create trip.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      backgroundColor: PlanneyColors.bg,

      appBar: const PlanneyHeader(title: 'Create Trip'),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Trip', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Step 1 of 1', style: TextStyle(fontSize: 14, color: PlanneyColors.textMuted, fontWeight: FontWeight.w600)),
                  Text('Next: Build Itinerary', style: TextStyle(fontSize: 14, color: PlanneyColors.green.withRed(0).withGreen(120).withBlue(0), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 1, 
                    child: Container(
                      height: 6, 
                      decoration: const BoxDecoration(
                        color: PlanneyColors.pink, 
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))
                      )
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: PlanneyColors.white, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: PlanneyColors.pink.withValues(alpha: 0.4), width: 2)
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, size: 16, color: PlanneyColors.pink),
                  ),
                  Expanded(
                    flex: 1, 
                    child: Container(
                      height: 6, 
                      decoration: const BoxDecoration(
                        color: PlanneyColors.divider, 
                        borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
                      )
                    )
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PlanneyColors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: PlanneyColors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, color: PlanneyColors.green.withRed(0).withGreen(120).withBlue(0), size: 20),
                            const SizedBox(width: 8),
                            Text('The Basics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PlanneyColors.green.withRed(0).withGreen(120).withBlue(0))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      const Text('Trip Name', style: TextStyle(fontSize: 14, color: PlanneyColors.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: PlanneyColors.text),
                        decoration: InputDecoration(
                          hintText: 'e.g. Summer Soul Searching 2026',
                          hintStyle: const TextStyle(color: PlanneyColors.textMuted, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: PlanneyColors.bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a trip name' : null,
                      ),
                      const SizedBox(height: 24),

                      const Text('Travel Dates', style: TextStyle(fontSize: 14, color: PlanneyColors.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDateRange(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          decoration: BoxDecoration(color: PlanneyColors.bg, borderRadius: BorderRadius.circular(100)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: PlanneyColors.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _formatDateRange(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _startDate != null ? PlanneyColors.text : PlanneyColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: PlanneyColors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add_rounded, color: PlanneyColors.blue.withRed(0).withGreen(100).withBlue(150), size: 20),
                            const SizedBox(width: 8),
                            Text('Travel Buddies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PlanneyColors.blue.withRed(0).withGreen(100).withBlue(150))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (authProvider.friends.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: PlanneyColors.bg, borderRadius: BorderRadius.circular(24)),
                          child: const Text('No friends found. You can add friends from the Dashboard later!', style: TextStyle(color: PlanneyColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: authProvider.friends.length,
                          itemBuilder: (context, index) {
                            final friend = authProvider.friends[index];
                            final friendId = friend['id'] as int;
                            final friendName = friend['username'] as String;
                            final isSelected = _selectedFriendIds.contains(friendId);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedFriendIds.remove(friendId);
                                  } else {
                                    _selectedFriendIds.add(friendId);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? PlanneyColors.pink.withValues(alpha: 0.1) : PlanneyColors.bg,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: isSelected ? PlanneyColors.pink.withValues(alpha: 0.3) : Colors.transparent, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: PlanneyColors.purple.withValues(alpha: 0.2),
                                      child: Text(friendName[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: PlanneyColors.purple)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('@$friendName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: PlanneyColors.text))),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: PlanneyColors.pink, size: 22)
                                    else
                                      const Icon(Icons.circle_outlined, color: PlanneyColors.textMuted, size: 22),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: tripProvider.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PlanneyColors.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 8,
                            shadowColor: PlanneyColors.pink.withValues(alpha: 0.5),
                          ),
                          child: tripProvider.isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Create & Plan Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PlanneyNavbar(
        currentIndex: 1, 
      ),
    );
  }
}