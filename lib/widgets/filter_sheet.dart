import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'transaction_form_fields.dart';

class FilterResult {
  const FilterResult({
    required this.range,
    required this.type,
    required this.category,
    required this.minAmount,
    required this.maxAmount,
  });

  final DateTimeRange? range;
  final String type;
  final String category;
  final int? minAmount;
  final int? maxAmount;
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initialRange,
    required this.initialType,
    required this.initialCategory,
    required this.initialMinAmount,
    required this.initialMaxAmount,
    required this.formatDate,
  });

  final DateTimeRange? initialRange;
  final String initialType;
  final String initialCategory;
  final int? initialMinAmount;
  final int? initialMaxAmount;
  final String Function(DateTime date) formatDate;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTimeRange? _range;
  late String _type;
  late String _category;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _type = widget.initialType;
    _category = widget.initialCategory;
    _minController =
        TextEditingController(text: widget.initialMinAmount?.toString() ?? '');
    _maxController =
        TextEditingController(text: widget.initialMaxAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _range = null;
      _type = 'all';
      _category = 'all';
      _minController.clear();
      _maxController.clear();
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _range = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
  }

  void _apply() {
    final minValue = int.tryParse(_minController.text.replaceAll('.', ''));
    final maxValue = int.tryParse(_maxController.text.replaceAll('.', ''));
    Navigator.of(context).pop(
      FilterResult(
        range: _range,
        type: _type,
        category: _category,
        minAmount: minValue,
        maxAmount: maxValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E3E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C20),
                      ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PickerField(
                        label: 'Tipe',
                        value: _type == 'all'
                            ? 'Semua'
                            : _type == 'income'
                                ? 'Pemasukan'
                                : 'Pengeluaran',
                        onTap: () async {
                          final selected = await showOptionSheet(
                            context,
                            title: 'Pilih Tipe',
                            options: const ['Semua', 'Pemasukan', 'Pengeluaran'],
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _type = selected == 'Semua'
                                ? 'all'
                                : selected == 'Pemasukan'
                                    ? 'income'
                                    : 'expense';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PickerField(
                        label: 'Kategori',
                        value: _category == 'all' ? 'Semua' : _category,
                        onTap: () async {
                          final selected = await showOptionSheet(
                            context,
                            title: 'Pilih Kategori',
                            options: const [
                              'Semua',
                              'Shopping',
                              'Food',
                              'Transport',
                              'Salary',
                              'Education',
                              'Other',
                            ],
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _category = selected == 'Semua' ? 'all' : selected;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration('Min nominal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration('Max nominal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _pickRange,
                  child: Text(
                    _range == null
                        ? 'Pilih Date Range'
                        : '${widget.formatDate(_range!.start)} - ${widget.formatDate(_range!.end)}',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1C20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Terapkan'),
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
