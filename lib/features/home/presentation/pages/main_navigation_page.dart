import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../extension_officer/presentation/pages/officer_dashboard_page.dart';
import '../../../manager/presentation/pages/manager_dashboard_page.dart';
import '../../../agro_dealer/presentation/pages/dealer_dashboard_page.dart';
import '../../../connectivity/presentation/bloc/connectivity_bloc.dart';
import 'home_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  UserRole _getUserRole() {
    try {
      final authState = context.read<AuthBloc>().state;
      return authState.user?.role ?? UserRole.farmer;
    } catch (e) {
      return UserRole.farmer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = _getUserRole();
    final pages = _getPagesForRole(userRole);
    final navItems = _getNavItemsForRole(userRole);

    return Scaffold(
      body: Column(
        children: [
          _buildConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textMuted,
        items: navItems,
      ),
    );
  }

  Widget _buildConnectivityBanner() {
    try {
      return BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, state) {
          if (state is ConnectivityOffline) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppTheme.warningAmber,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode - Data saved locally',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _getPagesForRole(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const [
          HomePage(),
          ScanPage(),
          HistoryPage(),
          SettingsPage(),
        ];
      case UserRole.extensionOfficer:
        return const [
          OfficerDashboardPage(),
          HistoryPage(),
          SettingsPage(),
        ];
      case UserRole.agricultureManager:
        return const [
          ManagerDashboardPage(),
          HistoryPage(),
          SettingsPage(),
        ];
      case UserRole.agroDealer:
        return const [
          DealerDashboardPage(),
          HistoryPage(),
          SettingsPage(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case UserRole.extensionOfficer:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case UserRole.agricultureManager:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case UserRole.agroDealer:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
    }
  }
}
