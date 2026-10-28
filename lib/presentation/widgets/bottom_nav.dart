import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int               currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap:        onTap,
        backgroundColor: Colors.transparent,
        elevation:       0,
        selectedItemColor:   AppColors.rose,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize:   10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendário'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Novo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sticky_note_2_outlined),
              activeIcon: Icon(Icons.sticky_note_2),
              label: 'Notas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Clientes'),
        ],
      ),
    );
  }
}

/// Menu lateral usado em telas largas (PC/notebook). Mesmos 6 destinos e
/// mesma numeração da barra de baixo, então `onTap` funciona igual.
class AppSideNav extends StatelessWidget {
  final int               currentIndex;
  final ValueChanged<int> onTap;

  const AppSideNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        labelType: NavigationRailLabelType.all,
        indicatorColor: AppColors.rose.withValues(alpha: 0.15),
        selectedIconTheme:   const IconThemeData(color: AppColors.rose),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle:
            const TextStyle(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 11),
        destinations: const [
          NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Início')),
          NavigationRailDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: Text('Calendário')),
          NavigationRailDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: Text('Novo')),
          NavigationRailDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: Text('Stats')),
          NavigationRailDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: Text('Notas')),
          NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Text('Clientes')),
        ],
      ),
    );
  }
}
