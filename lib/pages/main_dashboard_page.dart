import 'package:flutter/material.dart';

import 'blood_pressure_page.dart';
import 'food_log_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'resources_page.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({
    super.key,
  });

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          onOpenFoodLog: () {
            _selectTab(1);
          },
          onOpenBloodPressure: () {
            _selectTab(2);
          },
        );

      case 1:
        return const FoodLogPage();

      case 2:
        return const BloodPressurePage();

      case 3:
        return const ResourcesPage();

      case 4:
        return const ProfilePage();

      default:
        return HomePage(
          onOpenFoodLog: () {
            _selectTab(1);
          },
          onOpenBloodPressure: () {
            _selectTab(2);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSelectedPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.restaurant_menu_outlined,
            ),
            selectedIcon: Icon(
              Icons.restaurant_menu,
            ),
            label: 'Food Log',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.favorite_outline,
            ),
            selectedIcon: Icon(
              Icons.favorite,
            ),
            label: 'BP',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            selectedIcon: Icon(
              Icons.menu_book,
            ),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
