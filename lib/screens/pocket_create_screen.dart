import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';

class PocketCreateScreen extends StatefulWidget {
  const PocketCreateScreen({super.key, this.pocket});

  final PocketEntry? pocket;

  @override
  State<PocketCreateScreen> createState() => _PocketCreateScreenState();
}

class _PocketCreateScreenState extends State<PocketCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  int _selectedColor = 0;
  List<Map<String, Object?>> _tabs = [];
  int? _selectedTabId;

  final List<Color> _palette = const [
    Color(0xFFFFE7E7),
    Color(0xFFFFF4E8),
    Color(0xFFEDE7FF),
    Color(0xFFD9FCEB),
    Color(0xFFE2F0FF),
    Color(0xFFFFF0F6),
    Color(0xFFEFF7E8),
    Color(0xFFE6ECFF),
    Color(0xFFFFF7E0),
    Color(0xFFF0F2FF),
    Color(0xFFEAF5FF),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    final pocket = widget.pocket;
    if (pocket != null) {
      _nameController.text = pocket.name;
      _selectedTabId = pocket.tabId;
      final colorValue = pocket.colorValue;
      if (colorValue != null) {
        final index = _palette.indexWhere((color) => color.value == colorValue);
        _selectedColor = index >= 0 ? index : 0;
      }
    }
    _loadTabs();
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadTabs() async {
    var tabs = await AppDatabase.instance.fetchTabs();
    if (tabs.isEmpty) {
      final id = await AppDatabase.instance.insertTab('My pockets');
      await AppDatabase.instance.insertTab('Shared');
      tabs = await AppDatabase.instance.fetchTabs();
      _selectedTabId ??= id;
    } else {
      _selectedTabId ??= tabs.first['id'] as int?;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _tabs = tabs;
    });
  }

  Future<void> _create() async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final editing = widget.pocket;
    if (editing == null) {
      await AppDatabase.instance.insertPocket(
        trimmed,
        colorValue: _palette[_selectedColor].value,
        tabId: _selectedTabId,
      );
    } else {
      await AppDatabase.instance.updatePocket(
        PocketEntry(
          id: editing.id,
          name: trimmed,
          colorValue: _palette[_selectedColor].value,
          tabId: _selectedTabId,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final pocket = widget.pocket;
    if (pocket?.id == null) {
      return;
    }
    await AppDatabase.instance.deletePocket(pocket!.id!);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _selectColor(int index) {
    setState(() {
      _selectedColor = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.pocket == null ? 'Add Pocket' : 'Edit Pocket'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalize pocket',
                style: GoogleFonts.bakbakOne(
                  fontSize: 22,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set the name and color for this pocket.',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 20),
              Center(
                child: _PocketPreviewCard(
                  name: _nameController.text.trim().isEmpty
                      ? 'Create Pocket'
                      : _nameController.text.trim(),
                  color: _palette[_selectedColor],
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Tap to change color',
                  style: TextStyle(color: Color(0xFF6B6B6B)),
                ),
              ),
              const SizedBox(height: 16),
              _ColorPickerRow(
                colors: _palette,
                selected: _selectedColor,
                onTap: _selectColor,
              ),
              const SizedBox(height: 20),
              _InputCard(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Pocket name',
                hint: 'Example: Food, Transport',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tab',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) {
                    final id = tab['id'] as int?;
                    final name = tab['name'] as String? ?? '';
                    final selected = id == _selectedTabId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedTabId = id);
                        },
                        selectedColor: const Color(0xFF1B1C20),
                        labelStyle: TextStyle(
                          color: selected
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
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141416),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (widget.pocket != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Delete Pocket'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PocketPreviewCard extends StatelessWidget {
  const _PocketPreviewCard({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: 180,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                size: 18,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bakbakOne(
                    fontSize: 18,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rp0',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = index == selected;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B4B3F)
                      : const Color(0xFFDADCE2),
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF141416)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF3B4B3F),
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
