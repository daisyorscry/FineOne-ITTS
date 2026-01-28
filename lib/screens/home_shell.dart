import 'package:flutter/material.dart';

import 'add_transaction_screen.dart';
import 'dashboard_screen.dart';
import 'summary_screen.dart';
import '../widgets/nav_action_button.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _summaryKey = GlobalKey<SummaryScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: _dashboardKey),
      const _PlaceholderScreen(label: 'Cards'),
      SummaryScreen(key: _summaryKey),
      const _PlaceholderScreen(label: 'Profile'),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: SizedBox(
        height: 98,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavIcon(
                    icon: Icons.home_filled,
                    active: _index == 0,
                    onTap: () {
                      setState(() => _index = 0);
                      _dashboardKey.currentState?.refresh();
                    },
                  ),
                  _NavIcon(
                    icon: Icons.credit_card_rounded,
                    active: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  const SizedBox(width: 40),
                  _NavIcon(
                    icon: Icons.pie_chart_rounded,
                    active: _index == 2,
                    onTap: () {
                      setState(() => _index = 2);
                      _summaryKey.currentState?.refresh();
                    },
                  ),
                  _NavIcon(
                    icon: Icons.person_rounded,
                    active: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: NavActionButton(
                icon: Icons.swap_horiz_rounded,
                onTap: () async {
                  final updated = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                  if (updated == true) {
                    _dashboardKey.currentState?.refresh();
                    _summaryKey.currentState?.refresh();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1B1C20);
    const inactiveColor = Color(0xFFB6B7BC);

    return InkWell(
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 1.12 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: active ? activeColor : inactiveColor,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, color, child) {
            return Icon(
              icon,
              color: color,
            );
          },
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(label),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text('$label (coming soon)'),
      ),
    );
  }
}
