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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(
        onOpenFoodLog: () {
          _selectTab(1);
        },
        onOpenBloodPressure: () {
          _selectTab(2);
        },
      ),
      const FoodLogPage(),
      const BloodPressurePage(),
      const ResourcesPage(),
      const ProfilePage(),
    ];
  }

  void _selectTab(
    int index,
  ) {
    if (index < 0 || index >= _pages.length || index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.07,
                ),
                blurRadius: 14,
                offset: const Offset(
                  0,
                  -3,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: NavigationBar(
              height: 82,
              elevation: 0,
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectTab,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              indicatorColor: colors.primaryContainer,
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.home_rounded,
                  ),
                  label: 'Home',
                  tooltip: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.restaurant_menu_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.restaurant_menu_rounded,
                  ),
                  label: 'Food Log',
                  tooltip: 'Food Log',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.favorite_border_rounded,
                  ),
                  selectedIcon: Icon(
                    Icons.favorite_rounded,
                  ),
                  label: 'BP',
                  tooltip: 'Blood Pressure',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.menu_book_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.menu_book_rounded,
                  ),
                  label: 'Resources',
                  tooltip: 'Health Resources',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline_rounded,
                  ),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                  ),
                  label: 'Profile',
                  tooltip: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
