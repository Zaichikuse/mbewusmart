import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../history/presentation/widgets/ai_assistant_tab.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../extension_officer/presentation/pages/officer_dashboard_page.dart';
import '../../../manager/presentation/pages/manager_dashboard_page.dart';
import '../../../agro_dealer/presentation/pages/dealer_dashboard_page.dart';
import '../../../connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../home/presentation/pages/home_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;

  const MainNavigationPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  late final AiAssistantService _assistantService;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _assistantService = di.sl<AiAssistantService>();
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
    final appLoc = LocalizationHelper.getAppLocalizations(context);
    final userRole = _getUserRole();
    final pages = _getPagesForRole(userRole);
    final navItems = _getNavItemsForRole(userRole, appLoc);
    final isSettingsTab = _currentIndex == navItems.length - 1;
    final isChichewa = LocalizationHelper.isChichewa(context);

    return Scaffold(
      body: Column(
        children: [
          _buildConnectivityBanner(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: pages),
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
      floatingActionButton: isSettingsTab
          ? null
          : FloatingActionButton(
              heroTag: 'global_ai_fab',
              backgroundColor: AppTheme.primaryGreen,
              tooltip: isChichewa ? 'Tsegulani AI chat' : 'Open AI chat',
              onPressed: () => _openGlobalAiChat(
                isChichewa: isChichewa,
                pageContext: _resolvePageContext(navItems),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
    );
  }

  String _resolvePageContext(List<BottomNavigationBarItem> navItems) {
    final label = navItems[_currentIndex].label ?? 'General';
    if (label == 'History') {
      return _assistantService.currentUiContext;
    }
    return label;
  }

  void _openGlobalAiChat({
    required bool isChichewa,
    required String pageContext,
  }) {
    _assistantService.setCurrentUiContext(pageContext);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: AiAssistantTab(
                isChichewa: isChichewa,
                floatingMode: true,
                pageContext: pageContext,
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
            );
          },
        );
      },
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
        return const [HomePage(), ScanPage(), HistoryPage(), SettingsPage()];
      case UserRole.extensionOfficer:
        return const [OfficerDashboardPage(), HistoryPage(), SettingsPage()];
      case UserRole.agricultureManager:
        return const [ManagerDashboardPage(), HistoryPage(), SettingsPage()];
      case UserRole.agroDealer:
        return const [DealerDashboardPage(), HistoryPage(), SettingsPage()];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(
    UserRole role,
    AppLocalizations appLoc,
  ) {
    switch (role) {
      case UserRole.farmer:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: appLoc.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt_outlined),
            activeIcon: const Icon(Icons.camera_alt),
            label: appLoc.scan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: appLoc.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appLoc.settings,
          ),
        ];
      case UserRole.extensionOfficer:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: appLoc.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: appLoc.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appLoc.settings,
          ),
        ];
      case UserRole.agricultureManager:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            activeIcon: const Icon(Icons.admin_panel_settings),
            label: appLoc.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: appLoc.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appLoc.settings,
          ),
        ];
      case UserRole.agroDealer:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: appLoc.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: appLoc.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appLoc.settings,
          ),
        ];
    }
  }
}
