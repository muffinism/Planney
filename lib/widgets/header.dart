import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/colors.dart';

class PlanneyHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const PlanneyHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: PlanneyColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flight_takeoff_rounded, color: PlanneyColors.purple, size: 30),
                  const SizedBox(width: 12),
                  const Text(
                    'Planney',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: PlanneyColors.text, letterSpacing: -0.5),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: PlanneyColors.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pop(ctx);
                          }, 
                          child: const Text('Logout', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: PlanneyColors.pink.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: PlanneyColors.pink,
                    child: Text(
                      authProvider.username?.isNotEmpty == true ? authProvider.username![0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}