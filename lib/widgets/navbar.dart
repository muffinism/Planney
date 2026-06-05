import 'package:flutter/material.dart';
import '../themes/colors.dart';
import '../screens/trip_dashboard_page.dart';
import '../screens/create_trip_page.dart';
import '../screens/add_friend_page.dart';

class PlanneyNavbar extends StatelessWidget {
  final int currentIndex;

  const PlanneyNavbar({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const TripDashboardPage();
        break;
      case 1:
        page = const CreateTripPage();
        break;
      case 2:
        page = const AddFriendPage();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PlanneyColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                label: 'Home',
                activeColor: PlanneyColors.pink,
                isSelected: currentIndex == 0,
                onTap: () => _navigate(context, 0),
              ),
              _NavItem(
                icon: currentIndex == 1 ? Icons.add_circle_rounded : Icons.add_circle_outline_rounded,
                label: 'Create',
                activeColor: PlanneyColors.green,
                isSelected: currentIndex == 1,
                onTap: () => _navigate(context, 1),
              ),
              _NavItem(
                icon: currentIndex == 2 ? Icons.people_alt_rounded : Icons.people_outline_rounded,
                label: 'Friends',
                activeColor: PlanneyColors.purple,
                isSelected: currentIndex == 2,
                onTap: () => _navigate(context, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container( 
        padding: const EdgeInsets.symmetric(
          horizontal: 24, 
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: PlanneyColors.text,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: PlanneyColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}