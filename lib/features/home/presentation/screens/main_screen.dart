import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/home/presentation/screens/bag_page.dart';
import 'package:season_app/features/home/providers.dart';
import 'package:season_app/features/home/presentation/widgets/custom_notched_bottom_bar.dart';
import 'package:season_app/features/home/presentation/screens/home_page.dart';
import 'package:season_app/features/home/presentation/screens/card_page.dart';
import 'package:season_app/features/home/presentation/screens/group_page.dart';
import 'package:season_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:season_app/shared/providers/locale_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  
  const MainScreen({super.key, this.initialTab});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    
    // Set initial tab based on query parameter
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tabIndex = _getTabIndex(widget.initialTab!);
        if (tabIndex != null) {
          ref.read(bottomNavIndexProvider.notifier).state = tabIndex;
        }
      });
    }
  }

  int? _getTabIndex(String tab) {
    switch (tab.toLowerCase()) {
      case 'bag':
        return 1; // BagPage
      case 'reminders':
      case 'reminder':
        return 2; // CardPage (Reminders)
      case 'groups':
      case 'group':
        return 3; // GroupPage
      case 'profile':
        return 4; // ProfileScreen
      default:
        return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final locale = ref.watch(localeProvider);
    final isRtl = locale.languageCode == 'ar';
    final loc = AppLocalizations.of(context);
    
    final List<Widget> pages = [
      const HomePage(),        // Index 0 - Home (opened by FAB)
      const BagPage(),         // Index 1 - Bag
      const CardPage(),        // Index 2 - Card
      const GroupPage(),       // Index 3 - Group
      const ProfileScreen(),   // Index 4 - Profile
    ];

    // Modern and awesome icons for each page
    final List<BottomNavItem> navItems = [
      BottomNavItem(
        icon: Icons.luggage,  // Travel bag icon
        label: isRtl ? 'الحقيبة' : loc.bag,
      ),
      BottomNavItem(
        icon: Icons.notifications_outlined,  // Reminder icon
        label: isRtl ? 'التذكيرات' : loc.bagRemindersTitle,
      ),
      BottomNavItem(
        icon: Icons.explore_outlined,  // Modern explore/no loss icon
        label: isRtl ? 'عدم الضياع' : loc.group,
      ),
      BottomNavItem(
        icon: Icons.person_outline_rounded,  // Modern profile icon
        label: isRtl ? 'حسابي' : loc.profile,
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ), 
      bottomNavigationBar: CustomNotchedBottomBar(
        currentIndex: currentIndex == 0 ? -1 : currentIndex - 1,
        onTap: (index) {
          // Map navigation bar index to page index
          // Nav items are [Bag(1), Card(2), Group(3), Profile(4)]
          ref.read(bottomNavIndexProvider.notifier).state = index + 1;
        },
        onFabTap: () {
          // FAB opens home page (index 0)
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
        items: isRtl ? navItems.reversed.toList() : navItems,
        isRtl: isRtl,
      ),
    );
  }
}

