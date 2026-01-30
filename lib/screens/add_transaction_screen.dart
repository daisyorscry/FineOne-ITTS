import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../widgets/transaction_form_fields.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.initialEntry,
  });

  final String initialType;
  final TransactionEntry? initialEntry;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _type;
  String _category = 'Shopping';
  String _method = 'Cash';
  TransactionEntry? _editingEntry;
  List<PocketEntry> _pockets = [];
  int? _selectedPocketId;

  final List<String> _categories = const [
    'Shopping',
    'Food',
    'Transport',
    'Salary',
    'Education',
    'Other',
  ];
  final List<String> _methods = const [
    'Cash',
    'Debit',
    'Credit',
    'E-Wallet',
  ];

  @override
  void initState() {
    super.initState();
    _editingEntry = widget.initialEntry;
    _type = widget.initialEntry?.type ?? widget.initialType;
    _selectedPocketId = widget.initialEntry?.pocketId;
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _titleController.text = entry.title;
      _amountController.text = _formatInputAmount(entry.amount);
      _notesController.text = entry.notes ?? '';
      _category = entry.category;
      _method = entry.method ?? _method;
    }
    _loadPockets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final amount = int.parse(_amountController.text.replaceAll('.', '').trim());
    final editing = _editingEntry;
    final baseBalance =
        await AppDatabase.instance.getBalance(pocketId: _selectedPocketId);
    final adjustedBalance = _adjustedBalanceForEdit(editing, baseBalance);
    if (_type == 'expense') {
      if (amount > adjustedBalance) {
        if (!mounted) {
          return;
        }
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (context) {
            return SafeArea(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Color(0xFF1B1C20),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Opps, nominal uang kamu tidak mencukupi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return;
      }
    }
    final entry = TransactionEntry(
      id: editing?.id,
      title: _titleController.text.trim(),
      category: _category,
      amount: amount,
      type: _type,
      date: editing?.date ?? DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      method: _method,
      pocketId: _selectedPocketId,
    );
    if (editing == null) {
      await AppDatabase.instance.insertTransaction(entry);
    } else {
      await AppDatabase.instance.updateTransaction(entry);
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _formatShortDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  String _formatInputAmount(int value) {
    final digits = value.abs().toString().split('');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  int _adjustedBalanceForEdit(TransactionEntry? editing, int baseBalance) {
    if (editing == null) {
      return baseBalance;
    }
    if (editing.type == 'expense') {
      return baseBalance + editing.amount;
    }
    return baseBalance - editing.amount;
  }

  Future<void> _loadPockets() async {
    var pockets = await AppDatabase.instance.fetchPockets();
    if (pockets.isEmpty) {
      await AppDatabase.instance.insertPocket(
        'Main',
        colorValue: 0xFFBFFFE3,
      );
      pockets = await AppDatabase.instance.fetchPockets();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pockets = pockets;
      _selectedPocketId ??= pockets.isNotEmpty ? pockets.first.id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(_editingEntry == null ? 'Transaksi' : 'Edit Transaksi'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF1B1C20),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tips: catat transaksi kecil juga biar balance tetap akurat.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B1C20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kantong',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _pockets.isEmpty
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Belum ada kantong.',
                          style: TextStyle(color: Color(0xFF8C8F96)),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _pockets
                            .map(
                              (pocket) => ChoiceChip(
                                label: Text(pocket.name),
                                selected: _selectedPocketId == pocket.id,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedPocketId = pocket.id;
                                  });
                                },
                                checkmarkColor: Colors.white,
                                selectedColor: const Color(0xFF1B1C20),
                                labelStyle: TextStyle(
                                  color: _selectedPocketId == pocket.id
                                      ? Colors.white
                                      : const Color(0xFF1B1C20),
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFFDDDFE4),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kategori transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item),
                          selected: _category == item,
                          onSelected: (_) {
                            setState(() => _category = item);
                          },
                          checkmarkColor: Colors.white,
                          selectedColor: const Color(0xFF1B1C20),
                          labelStyle: TextStyle(
                            color: _category == item
                                ? Colors.white
                                : const Color(0xFF1B1C20),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFDDDFE4)),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Form transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: inputDecoration('Nama transaksi'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: inputDecoration('Nominal (Rp)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final parsed = int.tryParse(
                            value.replaceAll('.', '').trim(),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Nominal tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tipe transaksi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B1C20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeToggle(
                              label: 'Pemasukan',
                              selected: _type == 'income',
                              color: const Color(0xFFD9FCEB),
                              onTap: () => setState(() => _type = 'income'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeToggle(
                              label: 'Pengeluaran',
                              selected: _type == 'expense',
                              color: const Color(0xFFFFE7E7),
                              onTap: () => setState(() => _type = 'expense'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(height: 14),
                      PickerField(
                        label: 'Metode pembayaran',
                        value: _method,
                        onTap: () async {
                          final selected = await showOptionSheet(
                            context,
                            title: 'Pilih Metode',
                            options: _methods,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() => _method = selected);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: inputDecoration('Catatan (opsional)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + keyboardInset),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1C20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_editingEntry == null ? 'Simpan' : 'Update'),
                  ),
                ),
              ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? color : Colors.white;
    final border = selected ? Colors.transparent : const Color(0xFFDDDFE4);
    final textColor = selected ? const Color(0xFF1B1C20) : const Color(0xFF8C8F96);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
