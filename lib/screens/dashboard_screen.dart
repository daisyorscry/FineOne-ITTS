import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';
import '../screens/transaction_detail_screen.dart';
import '../widgets/activity_tile.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/quick_range_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<TransactionEntry> _transactions = [];
  int _balance = 0;
  DateTimeRange? _dateRange;
  String _quickRange = 'Today';
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  int? _minAmount;
  int? _maxAmount;
  String _displayName = '';
  String _goal = '';
  List<PocketEntry> _pockets = [];
  Map<int, int> _pocketBalances = {};
  int _selectedPocketIndex = 0;

  @override
  void initState() {
    super.initState();
    _setQuickRange('Today', reload: false);
    _loadData();
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    var pockets = await AppDatabase.instance.fetchPockets();
    if (pockets.isEmpty) {
      await AppDatabase.instance.insertPocket(
        'Main',
        colorValue: 0xFFBFFFE3,
      );
      pockets = await AppDatabase.instance.fetchPockets();
    }
    if (_selectedPocketIndex >= pockets.length) {
      _selectedPocketIndex = 0;
    }
    final selectedPocketId =
        pockets.isNotEmpty ? pockets[_selectedPocketIndex].id : null;
    final balance =
        await AppDatabase.instance.getBalance(pocketId: selectedPocketId);
    final transactions = await AppDatabase.instance.fetchTransactions(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      category: _categoryFilter,
      type: _typeFilter,
      pocketId: selectedPocketId,
    );
    final balances = <int, int>{};
    for (final pocket in pockets) {
      final id = pocket.id;
      if (id == null) {
        continue;
      }
      balances[id] = await AppDatabase.instance.getBalance(pocketId: id);
    }
    final profile = await AppDatabase.instance.fetchProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _balance = balance;
      _transactions = transactions;
      _displayName = profile?.name ?? '';
      _goal = profile?.goal ?? '';
      _pockets = pockets;
      _pocketBalances = balances;
    });
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTimeRange _rangeForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }

  String _labelForRange(DateTimeRange? range) {
    if (range == null) {
      return 'All';
    }
    final now = DateTime.now();
    if (_isSameDay(range.start, now) && _isSameDay(range.end, now)) {
      return 'Today';
    }
    return 'All';
  }

  void _setQuickRange(String value, {bool reload = true}) {
    DateTimeRange? nextRange;
    if (value == 'Today') {
      nextRange = _rangeForDay(DateTime.now());
    } else {
      nextRange = null;
    }
    setState(() {
      _quickRange = value;
      _dateRange = nextRange;
    });
    if (reload) {
      _loadData();
    }
  }

  Color _accentForBackground(Color background) {
    final hsl = HSLColor.fromColor(background);
    final double newLightness =
        (hsl.lightness - 0.18).clamp(0.12, 0.55).toDouble();
    final double newSaturation =
        (hsl.saturation + 0.08).clamp(0.2, 0.7).toDouble();
    return hsl
        .withLightness(newLightness)
        .withSaturation(newSaturation)
        .toColor();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return FilterSheet(
          initialRange: _dateRange,
          initialType: _typeFilter,
          initialCategory: _categoryFilter,
          initialMinAmount: _minAmount,
          initialMaxAmount: _maxAmount,
          formatDate: _formatDate,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _dateRange = result.range;
      _typeFilter = result.type;
      _categoryFilter = result.category;
      _minAmount = result.minAmount;
      _maxAmount = result.maxAmount;
      _quickRange = _labelForRange(result.range);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7D7F86),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayName.isEmpty
                            ? 'Welcome back'
                            : 'Welcome back, $_displayName',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1C20),
                        ),
                      ),
                      if (_goal.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _goal,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7D7F86),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: Color(0xFF1B1C20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 140,
                child: PageView.builder(
                  itemCount: _pockets.isEmpty ? 1 : _pockets.length,
                  onPageChanged: (index) {
                    setState(() => _selectedPocketIndex = index);
                    _loadData();
                  },
                  itemBuilder: (context, index) {
                    if (_pockets.isEmpty) {
                      return _PocketCardView(
                        title: 'FinOne Card',
                        balance: _balance,
                        backgroundColor: const Color(0xFF1D1F24),
                        textColor: Colors.white,
                        accentColor: _accentForBackground(
                          const Color(0xFF1D1F24),
                        ),
                      );
                    }
                    final pocket = _pockets[index];
                    final id = pocket.id ?? 0;
                    final balance = _pocketBalances[id] ?? 0;
                    final colorValue = pocket.colorValue;
                    final background = colorValue != null
                        ? Color(colorValue)
                        : const Color(0xFF1D1F24);
                    final bool useDarkText = colorValue != null;
                    final textColor =
                        useDarkText ? const Color(0xFF1D1F24) : Colors.white;
                    final accentColor = _accentForBackground(background);
                    return _PocketCardView(
                      title: pocket.name,
                      balance: balance,
                      backgroundColor: background,
                      textColor: textColor,
                      accentColor: accentColor,
                    );
                  },
                ),
              ),
            ),
            if (_pockets.length > 1) ...[
              const SizedBox(height: 8),
              _CardDots(
                count: _pockets.length,
                currentIndex: _selectedPocketIndex,
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                color: const Color(0xFFF5F6F8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Activities',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C20),
                              ),
                            ),
                            if (_pockets.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _pockets[_selectedPocketIndex].name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B1C20),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                QuickRangeSelector(
                                  value: _quickRange,
                                  onChanged: _setQuickRange,
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: _openFilterSheet,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: Color(0xFF1B1C20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _transactions.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada transaksi',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8C8F96),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _transactions[index];
                                return ActivityTile(
                                  item: item,
                                  amountText: _formatRupiah(item.amount),
                                  dateText: _formatDate(item.date),
                                  onTap: () async {
                                    final updated = await Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TransactionDetailScreen(entry: item),
                                      ),
                                    );
                                    if (updated == true) {
                                      _loadData();
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PocketCardView extends StatelessWidget {
  const _PocketCardView({
    required this.title,
    required this.balance,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  final String title;
  final int balance;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 16,
            child: Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.memory_rounded,
                size: 14,
                color: Color(0xFF1D1F24),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(balance),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'EX 06/26',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

class _CardDots extends StatelessWidget {
  const _CardDots({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1B1C20) : const Color(0xFFDADCE2),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
