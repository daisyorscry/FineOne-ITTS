import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../widgets/activity_tile.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/nav_action_button.dart';
import '../widgets/quick_range_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionEntry> _transactions = [];
  int _balance = 0;
  DateTimeRange? _dateRange;
  String _quickRange = 'Today';
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  int? _minAmount;
  int? _maxAmount;

  @override
  void initState() {
    super.initState();
    _setQuickRange('Today', reload: false);
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await AppDatabase.instance.getBalance();
    final transactions = await AppDatabase.instance.fetchTransactions(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      category: _categoryFilter,
      type: _typeFilter,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _balance = balance;
      _transactions = transactions;
    });
  }

  Future<void> _openTransactionForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (saved == true) {
      _loadData();
    }
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
                        'Welcome back',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1C20),
                        ),
                      ),
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
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1F24),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B4B3F),
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
                        'FinOne Card',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRupiah(_balance),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'EX 06/26',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                        Text(
                          'Activities',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1C20),
                          ),
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
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TransactionDetailScreen(entry: item),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 98,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 26, 24, 16),
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
                        const Icon(Icons.home_filled, color: Color(0xFF1B1C20)),
                        const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFFB6B7BC),
                        ),
                        const SizedBox(width: 40),
                        const Icon(
                          Icons.pie_chart_rounded,
                          color: Color(0xFFB6B7BC),
                        ),
                        const Icon(Icons.person_rounded, color: Color(0xFFB6B7BC)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: NavActionButton(
                      icon: Icons.swap_horiz_rounded,
                      onTap: _openTransactionForm,
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
}
