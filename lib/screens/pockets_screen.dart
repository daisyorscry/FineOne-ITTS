import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_database.dart';
import 'pocket_create_screen.dart';

class PocketsScreen extends StatefulWidget {
  const PocketsScreen({super.key});

  @override
  State<PocketsScreen> createState() => _PocketsScreenState();
}

class _PocketsScreenState extends State<PocketsScreen> {
  List<PocketEntry> _pockets = [];
  Map<int, int> _pocketBalances = {};
  bool _loading = true;
  List<Map<String, Object?>> _tabs = [];
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadPockets();
    _searchController.addListener(_onSearchChanged);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadPockets();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPockets() async {
    final tabs = await AppDatabase.instance.fetchTabs();
    if (_selectedTab > tabs.length) {
      _selectedTab = 0;
    }
    final selectedTabId = _selectedTab == 0
        ? null
        : tabs.isNotEmpty
            ? tabs[_selectedTab - 1]['id'] as int?
            : null;
    final pockets = await AppDatabase.instance.fetchPockets(tabId: selectedTabId);
    final balances = <int, int>{};
    for (final pocket in pockets) {
      final id = pocket.id;
      if (id == null) {
        continue;
      }
      balances[id] = await AppDatabase.instance.getBalance(pocketId: id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pockets = pockets;
      _pocketBalances = balances;
      _tabs = tabs;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _searchQuery) {
      return;
    }
    setState(() {
      _searchQuery = next;
    });
  }

  Future<void> _openCreatePocket() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PocketCreateScreen(),
      ),
    );
    if (created == true) {
      _loadPockets();
    }
  }

  Future<void> _openEditPocket(PocketEntry pocket) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PocketCreateScreen(pocket: pocket),
      ),
    );
    if (updated == true) {
      _loadPockets();
    }
  }

  Future<void> _openAddTabSheet() async {
    final controller = TextEditingController();
    final created = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add tab',
                style: GoogleFonts.bakbakOne(
                  fontSize: 18,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tab name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141416),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Create tab'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (created == null || created.trim().isEmpty) {
      return;
    }
    final name = created.trim();
    if (_tabs.any(
      (tab) =>
          (tab['name'] as String?)?.toLowerCase() == name.toLowerCase(),
    )) {
      return;
    }
    await AppDatabase.instance.insertTab(name);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTab = _tabs.length + 1;
    });
    _loadPockets();
  }

  int _totalBalance() {
    var total = 0;
    for (final value in _pocketBalances.values) {
      total += value;
    }
    return total;
  }

  String _formatRupiah(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString().split('');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${isNegative ? '-' : ''}Rp.${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredPockets = _searchQuery.isEmpty
        ? _pockets
        : _pockets
            .where(
              (pocket) =>
                  pocket.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(
          'Your Pockets',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF6F7F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _SearchField(controller: _searchController),
              const SizedBox(height: 12),
              _FilterRow(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  setState(() => _selectedTab = index);
                  _loadPockets();
                },
                onAddTab: _openAddTabSheet,
              ),
              const SizedBox(height: 10),
              _DividerLine(),
              const SizedBox(height: 10),
              _TotalBalanceCard(
                totalBalance: _formatRupiah(_totalBalance()),
              ),
              const SizedBox(height: 10),
              _DividerLine(),
              const SizedBox(height: 14),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _PocketCardGrid(
                          pockets: filteredPockets,
                          balances: _pocketBalances,
                          onAdd: _openCreatePocket,
                          onTap: _openEditPocket,
                        ),
                        if (filteredPockets.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'No pockets found.',
                            style: TextStyle(color: Color(0xFF6B6B6B)),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PocketCardGrid extends StatelessWidget {
  const _PocketCardGrid({
    required this.pockets,
    required this.balances,
    required this.onAdd,
    required this.onTap,
  });

  final List<PocketEntry> pockets;
  final Map<int, int> balances;
  final VoidCallback onAdd;
  final ValueChanged<PocketEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final double cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(pockets.length + 1, (index) {
            if (index == pockets.length) {
              return SizedBox(
                width: cardWidth,
                child: _AddPocketGridCard(onTap: onAdd),
              );
            }
            final pocket = pockets[index];
            final color = pocket.colorValue != null
                ? Color(pocket.colorValue!)
                : const Color(0xFFBFFFE3);
            final balance = balances[pocket.id ?? -1] ?? 0;
            return SizedBox(
              width: cardWidth,
              child: _PocketListCard(
                name: pocket.name,
                balance: balance,
                color: color,
                onTap: () => onTap(pocket),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AddPocketGridCard extends StatelessWidget {
  const _AddPocketGridCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFCACDD6),
          radius: 20,
        ),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 28),
                SizedBox(height: 6),
                Text(
                  'Add pocket',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PocketListCard extends StatelessWidget {
  const _PocketListCard({
    required this.name,
    required this.balance,
    required this.color,
    required this.onTap,
  });

  final String name;
  final int balance;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForName(name);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(balance),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString().split('');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${isNegative ? '-' : ''}Rp.${buffer.toString()}';
  }

  IconData _iconForName(String name) {
    final value = name.toLowerCase();
    if (value.contains('makan') ||
        value.contains('food') ||
        value.contains('jajan') ||
        value.contains('kuliner')) {
      return Icons.lunch_dining_rounded;
    }
    if (value.contains('transport') ||
        value.contains('bensin') ||
        value.contains('fuel') ||
        value.contains('ojek') ||
        value.contains('motor')) {
      return Icons.directions_car_rounded;
    }
    if (value.contains('belanja') ||
        value.contains('shopping') ||
        value.contains('shop')) {
      return Icons.shopping_bag_rounded;
    }
    if (value.contains('liburan') ||
        value.contains('travel') ||
        value.contains('trip')) {
      return Icons.flight_takeoff_rounded;
    }
    if (value.contains('kesehatan') || value.contains('health')) {
      return Icons.favorite_rounded;
    }
    if (value.contains('hiburan') ||
        value.contains('entertain') ||
        value.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    if (value.contains('darurat') || value.contains('emergency')) {
      return Icons.shield_rounded;
    }
    if (value.contains('tagihan') ||
        value.contains('bill') ||
        value.contains('listrik') ||
        value.contains('air') ||
        value.contains('wifi')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashLength = 6.0;
    const gapLength = 4.0;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        final extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.totalBalance,
  });

  final String totalBalance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Total Balance',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const Spacer(),
        Text(
          totalBalance,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1C20),
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFE6E8ED),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D1D1F),
        ),
        decoration: InputDecoration(
          hintText: 'Search pockets',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onAddTab,
  });

  final List<Map<String, Object?>> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length + 1, (index) {
                final label = index == 0
                    ? 'All'
                    : (tabs[index - 1]['name'] as String? ?? 'Tab');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(14),
                    child: _FilterChip(
                      label: label,
                      selected: index == selectedIndex,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        InkWell(
          onTap: onAddTab,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE6E8ED)),
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D1D1F) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF6B6B6B),
        ),
      ),
    );
  }
}
