import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';
import '../services/gemini_service.dart';
import 'insight_history_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  String _segment = 'income';
  List<TransactionEntry> _transactions = [];
  bool _isLoading = true;
  String? _insight;
  bool _insightLoading = false;
  String? _insightError;
  String? _geminiApiKey;
  DateTime? _insightCreatedAt;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final rangeStart = _monthStart(_addMonths(now, -3));
      final rangeEnd = _monthEnd(now);
      final transactions = await AppDatabase.instance.fetchTransactions(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      final profile = await AppDatabase.instance.fetchProfile();
      final monthKey = _monthKey(now);
      final insightRecord = await AppDatabase.instance.fetchInsightRecord(monthKey);
      final insight = insightRecord?['content'] as String?;
      final createdAt = insightRecord?['created_at'] as String?;
      if (!mounted) {
        return;
      }
      setState(() {
        _transactions = transactions;
        _insight = insight;
        _insightCreatedAt =
            createdAt == null ? null : DateTime.tryParse(createdAt);
        _geminiApiKey = profile?.geminiApiKey;
        _insightError = null;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _addMonths(DateTime date, int offset) {
    return DateTime(date.year, date.month + offset, 1);
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _monthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _sumForMonth(DateTime month, String type) {
    return _transactions
        .where((entry) =>
            entry.type == type && _isSameMonth(entry.date, month))
        .fold<int>(0, (sum, entry) => sum + entry.amount);
  }

  List<int> _monthlyTotals(String type) {
    final now = DateTime.now();
    return List.generate(4, (index) {
      final month = _addMonths(now, index - 3);
      return _sumForMonth(month, type);
    });
  }

  List<String> _monthLabels() {
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
    final now = DateTime.now();
    return List.generate(4, (index) {
      final month = _addMonths(now, index - 3);
      return months[month.month - 1];
    });
  }

  Map<String, int> _categoryTotals(String type) {
    final now = DateTime.now();
    final totals = <String, int>{};
    for (final entry in _transactions) {
      if (entry.type != type || !_isSameMonth(entry.date, now)) {
        continue;
      }
      totals.update(entry.category, (value) => value + entry.amount,
          ifAbsent: () => entry.amount);
    }
    return totals;
  }

  int _countTransactionsForMonth(DateTime month) {
    return _transactions
        .where((entry) => _isSameMonth(entry.date, month))
        .length;
  }

  Future<void> _generateInsight() async {
    if (_insightLoading) {
      return;
    }
    if (_insightCreatedAt != null &&
        _isSameDay(_insightCreatedAt!, DateTime.now())) {
      setState(() {
        _insightError = 'You can generate a new insight tomorrow.';
      });
      return;
    }
    final apiKey = _geminiApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      setState(() {
        _insightError = 'Please add your Gemini API key in Profile.';
      });
      return;
    }
    setState(() {
      _insightLoading = true;
      _insightError = null;
    });
    try {
      final now = DateTime.now();
      final monthKey = _monthKey(now);
      final monthLabel = _monthLabels().last;
      final periodStart = _monthStart(now);
      final periodEnd = _monthEnd(now);
      final incomeByCategory = _categoryTotals('income');
      final expenseByCategory = _categoryTotals('expense');
      final totalIncome = _sumForMonth(now, 'income');
      final totalExpense = _sumForMonth(now, 'expense');
      final transactionCount = _countTransactionsForMonth(now);
      final service = GeminiService(apiKey: apiKey);
      final insight = await service.generateMonthlyInsight(
        monthLabel: monthLabel,
        incomeByCategory: incomeByCategory,
        expenseByCategory: expenseByCategory,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        transactionCount: transactionCount,
      );
      await AppDatabase.instance.saveInsight(
        monthKey: monthKey,
        content: insight,
        periodStart: periodStart.toIso8601String(),
        periodEnd: periodEnd.toIso8601String(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _insight = insight;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _insightError = 'Failed to generate insight: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _insightLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthTotal = _sumForMonth(now, _segment);
    final previousMonthTotal = _sumForMonth(_addMonths(now, -1), _segment);
    final diff = currentMonthTotal - previousMonthTotal;
    final changeText = previousMonthTotal == 0
        ? 'No data from last month'
        : diff == 0
            ? 'Same as last month'
            : '${diff > 0 ? 'Increase' : 'Decrease'} of '
                '${((diff.abs() / previousMonthTotal) * 100).round()}% from last month';
    final monthlyTotals = _monthlyTotals(_segment);
    final categoryTotals = _categoryTotals(_segment);
    final categoryItems = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedControl(
                value: _segment,
                onChanged: (value) => setState(() => _segment = value),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Text(
                      _segment == 'income' ? 'Income This Month' : 'Expense This Month',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(currentMonthTotal),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1C20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      changeText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8F96),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SummaryChart(
                values: monthlyTotals,
                labels: _monthLabels(),
                highlightValue: _formatRupiah(monthlyTotals.isNotEmpty
                    ? monthlyTotals.last
                    : 0),
              ),
              const SizedBox(height: 18),
              Text(
                'Categories',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1C20),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (categoryItems.isEmpty)
                Text(
                  'Belum ada transaksi bulan ini.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C8F96),
                  ),
                )
              else
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryItems.length.clamp(0, 6).toInt(),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = categoryItems[index];
                      return _CategoryCard(
                        title: item.key,
                        subtitle: 'Bulan ini',
                        amount: _formatRupiah(item.value),
                        color: index.isEven
                            ? const Color(0xFFBFFFE3)
                            : const Color(0xFFD7B6FF),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Insight',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1C20),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InsightHistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'History',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InsightCard(
                insight: _insight,
                isLoading: _insightLoading,
                error: _insightError,
                onGenerate: _generateInsight,
                hasApiKey: _geminiApiKey != null && _geminiApiKey!.isNotEmpty,
                lastGeneratedAt: _insightCreatedAt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.isLoading,
    required this.error,
    required this.onGenerate,
    required this.hasApiKey,
    required this.lastGeneratedAt,
  });

  final String? insight;
  final bool isLoading;
  final String? error;
  final VoidCallback onGenerate;
  final bool hasApiKey;
  final DateTime? lastGeneratedAt;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate =
        hasApiKey && (lastGeneratedAt == null || !_isSameDay(lastGeneratedAt!, DateTime.now()));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insight != null && insight!.isNotEmpty) ...[
            Text(
              insight!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFF1B1C20),
              ),
            ),
            if (lastGeneratedAt != null &&
                _isSameDay(lastGeneratedAt!, DateTime.now())) ...[
              const SizedBox(height: 12),
              Text(
                'You can generate a new insight tomorrow.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
            ] else if (canGenerate) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C20),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Generate again'),
                ),
              ),
            ],
          ] else if (isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            Text(
              hasApiKey
                  ? 'Generate a monthly insight from your transactions.'
                  : 'Add your Gemini API key in Profile to enable insights.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 12),
            if (canGenerate)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C20),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Generate insight'),
                ),
              ),
            if (!canGenerate && lastGeneratedAt != null)
              Text(
                'You can generate a new insight tomorrow.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Income',
              selected: value == 'income',
              onTap: () => onChanged('income'),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Expenses',
              selected: value == 'expense',
              onTap: () => onChanged('expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B1C20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF1B1C20),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChart extends StatelessWidget {
  const _SummaryChart({
    required this.values,
    required this.labels,
    required this.highlightValue,
  });

  final List<int> values;
  final List<String> labels;
  final String highlightValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 170,
        child: CustomPaint(
          painter: _LineChartPainter(
            values: values,
            highlightValue: highlightValue,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 28, right: 8, bottom: 20),
            child: Column(
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels
                      .map((label) => Text(label))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.highlightValue,
  });

  final List<int> values;
  final String highlightValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF1B1C20);
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E4EA);

    final chartRect = Rect.fromLTWH(28, 8, size.width - 36, size.height - 32);
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (values.isEmpty) {
      return;
    }
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    final stepX =
        values.length > 1 ? chartRect.width / (values.length - 1) : 0;
    final points = List.generate(values.length, (index) {
      final value = values[index];
      final x = chartRect.left + stepX * index;
      final ratio = value / safeMax;
      final y = chartRect.bottom - (chartRect.height * ratio);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final next = points[i];
      final control = Offset((prev.dx + next.dx) / 2, prev.dy);
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }

    canvas.drawPath(path, paint);

    final focus = points.last;
    final dotPaint = Paint()..color = const Color(0xFF1B1C20);
    canvas.drawCircle(focus, 5, dotPaint);

    final labelRect = Rect.fromCenter(
      center: Offset(focus.dx, focus.dy - 26),
      width: 86,
      height: 24,
    );
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B1C20));
    final tp = TextPainter(
      text: TextSpan(
        text: highlightValue,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: labelRect.width);
    tp.paint(
      canvas,
      Offset(labelRect.left + 6, labelRect.top + 6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: Color(0xFF1B1C20),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B1C20),
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C20),
            ),
          ),
        ],
      ),
    );
  }
}
