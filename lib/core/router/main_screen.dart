import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'authenticated_app_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final title = navigationShell.currentIndex == 0 ? 'Profile' : 'Categories';
    return Scaffold(
      appBar: AuthenticatedAppBar(title: title),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}
