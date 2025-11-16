import 'package:flutter/material.dart';
import 'features/feed/feed_screen.dart';
import 'features/studio/studio_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/studio/services/stripe_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/widgets/lucky_wrappers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  await StripeService.initialize();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hack Social',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = AppConstants.feedIndex;

  final List<Widget> _screens = const [
    FeedScreen(),
    StudioScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: LuckyNavBarWrapper(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          LuckyNavBarItemWrapper(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            label: '',
          ),
          LuckyNavBarItemWrapper(
            icon: Icons.add_circle_outline,
            selectedIcon: Icons.add_circle,
            label: '',
          ),
          LuckyNavBarItemWrapper(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: '',
          ),
        ],
      ),
    );
  }
}
