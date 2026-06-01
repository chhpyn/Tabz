import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/widgets/top_banner.dart';
import '../widgets/member_avatar.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ocr_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final List<UserModel> members;
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedPayerId;
  SplitType _splitType = SplitType.equal;

  // Itemized
  List<_ItemRow> _itemRows = [];
  final _taxPercentageController = TextEditingController();
  final _serviceChargePercentageController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isDiscountPercentage = false;
  bool _isOcrLoading = false;
  bool _autoSyncAmountFromItems = false;

  // Custom
  final Map<String, TextEditingController> _customControllers = {};
  bool _usePercentage = false;

  String _lastSmartAssignText = '';

  @override
  void initState() {
    super.initState();
    _selectedPayerId =
        widget.existingExpense?.payerId ??
        context.read<AuthProvider>().currentUser?.id ??
        widget.members.first.id;

    if (widget.existingExpense != null) {
      final exp = widget.existingExpense!;
      _titleController.text = exp.title;
      _amountController.text = exp.amount.toStringAsFixed(2);
      _splitType = exp.splitType;
    }

    for (final m in widget.members) {
      _customControllers[m.id] = TextEditingController();
      if (widget.existingExpense != null &&
          widget.existingExpense!.splitType == SplitType.custom) {
        final split = widget.existingExpense!.splits
            .cast<SplitDetail?>()
            .firstWhere((s) => s?.userId == m.id, orElse: () => null);
        if (split != null) {
          _customControllers[m.id]!.text = split.amount.toStringAsFixed(2);
        }
      }
    }

    if (widget.existingExpense != null &&
        widget.existingExpense!.splitType == SplitType.itemized) {
      for (final item in widget.existingExpense!.items) {
        final row = _ItemRow(members: widget.members);
        row.nameCtrl.text = item.name;
        row.priceCtrl.text = item.price.toStringAsFixed(2);
        row.selectedMemberIds.addAll(item.assignedUserIds);
        _itemRows.add(row);
      }

      // Calculate tax/fees if any
      final totalItemsPrice = widget.existingExpense!.items.fold(
        0.0,
        (sum, i) => sum + i.price,
      );
      if (widget.existingExpense!.amount > totalItemsPrice &&
          totalItemsPrice > 0) {
        _taxPercentageController.text =
            (((widget.existingExpense!.amount - totalItemsPrice) /
                        totalItemsPrice) *
                    100)
                .toStringAsFixed(2);
      }

      _syncAmountFromItems();
    }

    if (_itemRows.isEmpty) {
      _addItemRow();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _taxPercentageController.dispose();
    _serviceChargePercentageController.dispose();
    _discountController.dispose();
    for (final theme in _customControllers.values) {
      theme.dispose();
    }
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amountController.text) ?? 0;

  double get _itemsTotal => _itemRows.fold(
    0.0,
    (sum, r) => sum + (double.tryParse(r.priceCtrl.text) ?? 0),
  );

  double _percentageValue(TextEditingController controller) {
    return double.tryParse(controller.text) ?? 0;
  }

  double get _taxPercentage => _percentageValue(_taxPercentageController);

  double get _serviceChargePercentage =>
      _percentageValue(_serviceChargePercentageController);

  double get _discountInputAmount =>
      double.tryParse(_discountController.text) ?? 0;

  double get _discountAmount {
    if (_discountInputAmount <= 0) return 0.0;
    if (_isDiscountPercentage) {
      return _itemsTotal * _discountInputAmount / 100;
    }
    return _discountInputAmount;
  }

  double get _discountedItemsTotal => _itemsTotal - _discountAmount;

  double get _taxAmount => _discountedItemsTotal * _taxPercentage / 100;

  double get _serviceChargeAmount =>
      _discountedItemsTotal * _serviceChargePercentage / 100;

  double get _itemizedTaxAndServiceChargeTotal =>
      _taxAmount + _serviceChargeAmount;

  double get _itemizedCalculatedTotal =>
      _discountedItemsTotal + _itemizedTaxAndServiceChargeTotal;

  double get _customTotal {
    return _customControllers.values.fold(
      0.0,
      (sum, theme) => sum + (double.tryParse(theme.text) ?? 0),
    );
  }

  void _syncAmountFromItems() {
    if (_splitType == SplitType.itemized || _autoSyncAmountFromItems) {
      if (_itemsTotal == 0) return;
      _amountController.text = _itemizedCalculatedTotal.toStringAsFixed(2);
    }
  }

  void _addItemRow() {
    setState(() {
      _itemRows.add(_ItemRow(members: widget.members));
      _syncAmountFromItems();
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
      _syncAmountFromItems();
    });
  }

  Future<void> _showSmartAssignDialog() async {
    if (_itemRows.isEmpty) return;

    final assignCtrl = TextEditingController(text: _lastSmartAssignText);
    final theme = AppDynColors.of(context);
    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.background,
        title: Text('Smart Assign', style: TextStyle(color: theme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Who had what? Let Smart Assign automatically assign items.',
              style: TextStyle(fontSize: 13, color: theme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: assignCtrl,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Jake ate pasta, Alex took burger',
                hintStyle: TextStyle(fontSize: 13, color: theme.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.06),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (shouldAssign == true && assignCtrl.text.trim().isNotEmpty) {
      setState(() {
        _lastSmartAssignText = assignCtrl.text.trim();
        _isOcrLoading = true;
      });

      try {
        final currentItems = _itemRows
            .map(
              (row) => ParsedItem(
                name: row.nameCtrl.text,
                price: double.tryParse(row.priceCtrl.text) ?? 0,
              ),
            )
            .toList();

        final assignedMap = await OcrService.assignItemsWithAI(
          _lastSmartAssignText,
          currentItems,
          widget.members,
        );

        setState(() {
          for (int i = 0; i < _itemRows.length; i++) {
            if (assignedMap.containsKey(i)) {
              _itemRows[i].selectedMemberIds.clear();
              _itemRows[i].selectedMemberIds.addAll(assignedMap[i]!);
            }
          }
        });
      } catch (e) {
        if (mounted) {
          TopBanner.show(context, 'Error assigning items: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isOcrLoading = false);
        }
      }
    }
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    setState(() => _isOcrLoading = true);

    try {
      final receipt = await OcrService.processReceipt(file.path);

      if (mounted) {
        setState(() => _isOcrLoading = false);
      }

      setState(() {
        // Clear empty rows
        _itemRows.removeWhere(
          (row) => row.nameCtrl.text.isEmpty && row.priceCtrl.text.isEmpty,
        );

        // Add parsed items
        for (int i = 0; i < receipt.items.length; i++) {
          final item = receipt.items[i];
          final row = _ItemRow(members: widget.members);
          row.nameCtrl.text = item.name;
          row.priceCtrl.text = item.price.toStringAsFixed(2);

          _itemRows.add(row);
        }

        _taxPercentageController.text = receipt.taxPercentage > 0
            ? receipt.taxPercentage.toStringAsFixed(2)
            : '';
        _serviceChargePercentageController.text =
            receipt.serviceChargePercentage > 0
            ? receipt.serviceChargePercentage.toStringAsFixed(2)
            : '';
        if (receipt.discountPercentage > 0) {
          _isDiscountPercentage = true;
          _discountController.text = receipt.discountPercentage.toStringAsFixed(
            2,
          );
        } else if (receipt.discountAmount > 0) {
          _isDiscountPercentage = false;
          _discountController.text = receipt.discountAmount.toStringAsFixed(2);
        } else {
          _discountController.text = '';
        }
        _autoSyncAmountFromItems = true;

        // Ensure at least one row exists
        if (_itemRows.isEmpty) {
          _itemRows.add(_ItemRow(members: widget.members));
        }

        // Update the main amount field with the overall total
        _syncAmountFromItems();
      });
    } catch (e) {
      if (mounted) {
        TopBanner.show(context, 'Error scanning receipt: $e');
      }
      if (mounted) {
        setState(() => _isOcrLoading = false);
      }
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      TopBanner.show(context, 'Please enter a title for this expense');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final expenseProvider = context.read<ExpenseProvider>();
    final now = widget.existingExpense?.date ?? DateTime.now();
    final idBase = now.millisecondsSinceEpoch.toString();

    ExpenseModel expense;

    if (_splitType == SplitType.equal) {
      final memberIds = widget.members.map((m) => m.id).toList();
      final share = _parsedAmount / memberIds.length;
      expense = ExpenseModel(
        id: widget.existingExpense?.id ?? 'exp_$idBase',
        title: _titleController.text.trim(),
        amount: _parsedAmount,
        payerId: _selectedPayerId,
        groupId: widget.groupId,
        splitType: SplitType.equal,
        items: [],
        splits: memberIds
            .map((id) => SplitDetail(userId: id, amount: share))
            .toList(),
        involvedUserIds: widget.members.map((m) => m.id).toList(),
        date: now,
      );
    } else if (_splitType == SplitType.itemized) {
      final items = _itemRows.map((row) {
        return ExpenseItem(
          name: row.nameCtrl.text.trim(),
          price: double.tryParse(row.priceCtrl.text) ?? 0,
          assignedUserIds: row.selectedMemberIds.isEmpty
              ? widget.members.map((m) => m.id).toList()
              : row.selectedMemberIds.toList(),
        );
      }).toList();
      // Calculate per-person splits from items
      final splitMap = <String, double>{};
      double itemsTotalCost = 0.0;
      for (final item in items) {
        itemsTotalCost += item.price;
        final perUser = item.pricePerUser;
        for (final uid in item.assignedUserIds) {
          splitMap[uid] = (splitMap[uid] ?? 0) + perUser;
        }
      }

      // Proportional Tax & Discount Distribution
      final taxAndFees = _itemizedTaxAndServiceChargeTotal;
      final netAdjustment = taxAndFees - _discountAmount;
      if (netAdjustment != 0 && itemsTotalCost > 0) {
        for (final uid in splitMap.keys.toList()) {
          final ratio = splitMap[uid]! / itemsTotalCost;
          splitMap[uid] = splitMap[uid]! + (netAdjustment * ratio);
        }
      } else if (netAdjustment != 0 && itemsTotalCost == 0) {
        // Fallback: Split net adjustment equally among people in the splitMap if total items cost is 0
        final share = netAdjustment / (splitMap.isEmpty ? 1 : splitMap.length);
        for (final uid in splitMap.keys.toList()) {
          splitMap[uid] = splitMap[uid]! + share;
        }
      }

      expense = ExpenseModel(
        id: widget.existingExpense?.id ?? 'exp_$idBase',
        title: _titleController.text.trim(),
        amount: itemsTotalCost + netAdjustment,
        payerId: _selectedPayerId,
        groupId: widget.groupId,
        splitType: SplitType.itemized,
        items: items,
        splits: splitMap.entries
            .map((e) => SplitDetail(userId: e.key, amount: e.value))
            .toList(),
        involvedUserIds: widget.members.map((m) => m.id).toList(),
        date: now,
      );
    } else {
      // Custom
      final splitMap = <String, double>{};
      for (final m in widget.members) {
        final val = double.tryParse(_customControllers[m.id]?.text ?? '') ?? 0;
        splitMap[m.id] = _usePercentage ? _parsedAmount * val / 100 : val;
      }
      expense = ExpenseModel(
        id: widget.existingExpense?.id ?? 'exp_$idBase',
        title: _titleController.text.trim(),
        amount: _parsedAmount,
        payerId: _selectedPayerId,
        groupId: widget.groupId,
        splitType: SplitType.custom,
        items: [],
        splits: splitMap.entries
            .map((e) => SplitDetail(userId: e.key, amount: e.value))
            .toList(),
        involvedUserIds: widget.members.map((m) => m.id).toList(),
        date: now,
      );
    }

    if (widget.existingExpense != null) {
      expenseProvider.updateExpense(expense);
    } else {
      final groupsProvider = context.read<GroupsProvider>();
      final group = groupsProvider.getGroupById(widget.groupId);
      final payer = widget.members.firstWhere(
        (m) => m.id == _selectedPayerId,
        orElse: () => widget.members.first,
      );

      expenseProvider.addExpense(
        expense,
        payerName: payer.name,
        groupName: group?.name ?? 'Group',
        groupEmoji: group?.emoji ?? '👥',
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            widget.existingExpense != null ? 'Edit Expense' : 'Add Expense',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: theme.background,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'What was this expense?',
                        prefixIcon: Icon(Icons.receipt_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v != null && v.trim().isNotEmpty
                          ? null
                          : 'Enter a title',
                    ),
                    const SizedBox(height: 14),
                    // Scan Receipt
                    _buildScanReceipt(theme),
                    const SizedBox(height: 24),
                    // Split Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SplitType>(
                          value: _splitType,
                          isExpanded: true,
                          dropdownColor: theme.card,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.primary,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: SplitType.equal,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.pie_chart_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Equal Split',
                                    style: GoogleFonts.inter(
                                      color: theme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: SplitType.itemized,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Itemized Split',
                                    style: GoogleFonts.inter(
                                      color: theme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: SplitType.custom,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Custom Split',
                                    style: GoogleFonts.inter(
                                      color: theme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _splitType = val;
                                _syncAmountFromItems();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Amount & Paid By
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          // Amount input
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount',
                                  style: GoogleFonts.inter(
                                    color: theme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'RM ',
                                      style: GoogleFonts.inter(
                                        color: theme.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _amountController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9.]'),
                                          ),
                                        ],
                                        readOnly:
                                            _splitType == SplitType.itemized,
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                          hintText: '0.00',
                                          hintStyle: TextStyle(
                                            color: theme.textSecondary,
                                          ),
                                        ),
                                        validator: (v) {
                                          final val = double.tryParse(v ?? '');
                                          if (_splitType ==
                                              SplitType.itemized) {
                                            return null;
                                          }
                                          return val != null && val > 0
                                              ? null
                                              : 'Enter a valid amount';
                                        },
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: theme.cardBorder,
                          ),
                          // Paid by selector
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Paid by',
                                  style: GoogleFonts.inter(
                                    color: theme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (ctx) => Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: theme.background,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(24),
                                              ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: theme.cardBorder,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'Select Payer',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ...widget.members.map((member) {
                                              final selected =
                                                  member.id == _selectedPayerId;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(
                                                      () => _selectedPayerId =
                                                          member.id,
                                                    );
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: selected
                                                          ? AppColors.primary
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                )
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: selected
                                                            ? AppColors.primary
                                                            : theme.cardBorder,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        MemberAvatar(
                                                          user: member,
                                                          radius: 14,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            member.name,
                                                            style: GoogleFonts.inter(
                                                              color: theme
                                                                  .textPrimary,
                                                              fontWeight:
                                                                  selected
                                                                  ? FontWeight
                                                                        .w700
                                                                  : FontWeight
                                                                        .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        if (selected)
                                                          Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        ...widget.members
                                            .where(
                                              (m) => m.id == _selectedPayerId,
                                            )
                                            .map(
                                              (member) => [
                                                MemberAvatar(
                                                  user: member,
                                                  radius: 12,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    member.firstName,
                                                    style: GoogleFonts.inter(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                            .expand((e) => e),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.expand_more_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tab Content
                    _buildTabContent(theme, currencyFmt),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.contrast,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    widget.existingExpense != null
                        ? 'Update Expense'
                        : 'Save Expense',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AppDynColors theme, NumberFormat currencyFmt) {
    switch (_splitType) {
      case SplitType.equal:
        return _buildEqualTab(theme, currencyFmt);
      case SplitType.itemized:
        return _buildItemizedTab(theme, currencyFmt);
      case SplitType.custom:
        return _buildCustomTab(theme, currencyFmt);
      default:
        return _buildCustomTab(theme, currencyFmt);
    }
  }

  // Equal Split
  Widget _buildEqualTab(AppDynColors theme, NumberFormat currencyFmt) {
    final total = _parsedAmount;
    final perPerson = widget.members.isNotEmpty
        ? total / widget.members.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Split equally among ${widget.members.length} members',
                style: GoogleFonts.inter(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.members.map((member) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  MemberAvatar(user: member, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.name,
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    currencyFmt.format(perPerson),
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPercentageFieldRow({
    required AppDynColors theme,
    required NumberFormat currencyFmt,
    required String label,
    required TextEditingController controller,
    required double amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: TextFormField(
              cursorColor: AppColors.success,
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.right,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.success.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                suffixText: '%',
                suffixStyle: TextStyle(color: theme.textMuted, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.success,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _syncAmountFromItems();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currencyFmt.format(amount),
            style: GoogleFonts.inter(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountFieldRow({
    required AppDynColors theme,
    required NumberFormat currencyFmt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Text(
            'Discount',
            style: GoogleFonts.inter(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDiscountPercentage = !_isDiscountPercentage;
                _syncAmountFromItems();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Text(
                _isDiscountPercentage ? 'Change to RM' : 'Change to %',
                style: GoogleFonts.inter(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: TextFormField(
              cursorColor: AppColors.warning,
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.right,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.warning.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                suffixText: _isDiscountPercentage ? '%' : 'RM',
                suffixStyle: TextStyle(color: theme.textMuted, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.warning,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _syncAmountFromItems();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-${currencyFmt.format(_discountAmount)}',
            style: GoogleFonts.inter(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Itemized Split
  Widget _buildItemizedTab(AppDynColors theme, NumberFormat currencyFmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Smart Assign Header
        if (_itemRows.isNotEmpty &&
            _itemRows.any((r) => r.nameCtrl.text.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showSmartAssignDialog,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Assign',
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lastSmartAssignText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"$_lastSmartAssignText"',
                    style: GoogleFonts.inter(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        // Item rows
        ...List.generate(_itemRows.length, (index) {
          final row = _itemRows[index];
          return _ItemRowWidget(
            key: ValueKey(row),
            row: row,
            index: index,
            members: widget.members,
            onRemove: _itemRows.length > 1 ? () => _removeItemRow(index) : null,
            onChanged: () {
              setState(() {
                _syncAmountFromItems();
              });
            },
            theme: theme,
          );
        }),
        // Add item button
        Center(
          child: TextButton.icon(
            onPressed: _addItemRow,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Add Item'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
        ),
        const SizedBox(height: 12),
        if (_splitType == SplitType.itemized) ...[
          _buildDiscountFieldRow(theme: theme, currencyFmt: currencyFmt),
          _buildPercentageFieldRow(
            theme: theme,
            currencyFmt: currencyFmt,
            label: 'SST',
            controller: _taxPercentageController,
            amount: _taxAmount,
          ),
          _buildPercentageFieldRow(
            theme: theme,
            currencyFmt: currencyFmt,
            label: 'Service Charge',
            controller: _serviceChargePercentageController,
            amount: _serviceChargeAmount,
          ),
        ],
        if (_itemsTotal > 0 || _itemizedTaxAndServiceChargeTotal > 0) ...[
          const SizedBox(height: 12),
          // Footer totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items Subtotal',
                      style: GoogleFonts.inter(
                        color: theme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currencyFmt.format(_itemsTotal),
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '-${currencyFmt.format(_discountAmount)}',
                        style: GoogleFonts.inter(
                          color: AppColors.warning,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_taxAmount > 0 || _taxPercentageController.text.isNotEmpty)
                  const SizedBox(height: 8),
                if (_taxAmount > 0 || _taxPercentageController.text.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_taxPercentageController.text.isEmpty ? '0' : _taxPercentageController.text}% (${currencyFmt.format(_taxAmount)})',
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (_serviceChargeAmount > 0 ||
                    _serviceChargePercentageController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Charge',
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_serviceChargePercentageController.text.isEmpty ? '0' : _serviceChargePercentageController.text}% (${currencyFmt.format(_serviceChargeAmount)})',
                        style: GoogleFonts.inter(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calculated Total',
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFmt.format(_itemizedCalculatedTotal),
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Split distribution
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Split Details',
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...(() {
                  final splitMap = <String, double>{};
                  double itemsTotalCost = 0.0;
                  for (final row in _itemRows) {
                    final price = double.tryParse(row.priceCtrl.text) ?? 0;
                    itemsTotalCost += price;
                    final assignees = row.selectedMemberIds.isEmpty
                        ? widget.members.map((m) => m.id).toList()
                        : row.selectedMemberIds.toList();
                    final perUser = assignees.isEmpty
                        ? 0.0
                        : price / assignees.length;
                    for (final uid in assignees) {
                      splitMap[uid] = (splitMap[uid] ?? 0) + perUser;
                    }
                  }
                  final taxAndFees = _itemizedTaxAndServiceChargeTotal;
                  final netAdjustment = taxAndFees - _discountAmount;
                  if (netAdjustment != 0 && itemsTotalCost > 0) {
                    for (final uid in splitMap.keys.toList()) {
                      final ratio = splitMap[uid]! / itemsTotalCost;
                      splitMap[uid] = splitMap[uid]! + (netAdjustment * ratio);
                    }
                  } else if (netAdjustment != 0 && itemsTotalCost == 0) {
                    final share =
                        netAdjustment /
                        (splitMap.isEmpty ? 1 : splitMap.length);
                    for (final uid in splitMap.keys.toList()) {
                      splitMap[uid] = splitMap[uid]! + share;
                    }
                  }

                  return widget.members.map((m) {
                    final amount = splitMap[m.id] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          MemberAvatar(user: m, radius: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.name,
                              style: GoogleFonts.inter(
                                color: theme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            currencyFmt.format(amount),
                            style: GoogleFonts.inter(
                              color: theme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                })(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Custom Split
  Widget _buildCustomTab(AppDynColors theme, NumberFormat currencyFmt) {
    final total = _parsedAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // % vs amount toggle
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? theme.cardElevated
                : Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _usePercentage = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_usePercentage
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? theme.background
                                : theme.background)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: !_usePercentage
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      'Fixed Amount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: !_usePercentage
                            ? AppColors.success
                            : theme.textSecondary,
                        fontWeight: !_usePercentage
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _usePercentage = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _usePercentage
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? theme.background
                                : theme.background)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: _usePercentage
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      'Percentage',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _usePercentage
                            ? AppColors.success
                            : theme.textSecondary,
                        fontWeight: _usePercentage
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Per-member inputs
        ...widget.members.map((member) {
          final ctrl = _customControllers[member.id]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.cardBorder),
            ),
            child: Row(
              children: [
                MemberAvatar(user: member, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.name,
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: AppColors.success,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.success.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      suffixText: _usePercentage ? '%' : 'RM',
                      suffixStyle: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (!_usePercentage && total > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${((double.tryParse(ctrl.text) ?? 0) / total * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        color: theme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        // Total validation
        Builder(
          builder: (_) {
            final customTotal = _customTotal;
            final expectedTotal = _usePercentage ? 100.0 : total;
            final isValid = (customTotal - expectedTotal).abs() < 0.01;
            return Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    _usePercentage
                        ? 'Total: ${customTotal.toStringAsFixed(1)}%'
                        : 'Total: ${currencyFmt.format(customTotal)}',
                    style: GoogleFonts.inter(
                      color: isValid ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (!isValid)
                    Text(
                      'Must equal ${_usePercentage ? '100%' : currencyFmt.format(total)}',
                      style: GoogleFonts.inter(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  if (isValid)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScanReceipt(AppDynColors theme) {
    return GestureDetector(
      onTap: _isOcrLoading
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.camera_alt_rounded),
                        title: const Text('Take Photo'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _scanReceipt(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _scanReceipt(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isOcrLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _ThreeDotsLoading(),
                  const SizedBox(width: 12),
                  Text(
                    'Extracting receipt...',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Receipt',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Auto-extract items from a photo',
                          style: GoogleFonts.inter(
                            color: theme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accent,
                    size: 14,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ThreeDotsLoading extends StatefulWidget {
  const _ThreeDotsLoading();

  @override
  State<_ThreeDotsLoading> createState() => _ThreeDotsLoadingState();
}

class _ThreeDotsLoadingState extends State<_ThreeDotsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = (index * 0.2);
        final t = (_controller.value + offset) % 1.0;
        final size = 4.0 + (t < 0.5 ? t * 4 : (1 - t) * 4);
        final opacity = 0.3 + (t < 0.5 ? t * 1.4 : (1 - t) * 1.4);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: opacity.clamp(0.0, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_buildDot(0), _buildDot(1), _buildDot(2)],
      ),
    );
  }
}

// _ItemRow data class
class _ItemRow {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final Set<String> selectedMemberIds = {};
  final List<UserModel> members;

  _ItemRow({required this.members});

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

// _ItemRowWidget
class _ItemRowWidget extends StatefulWidget {
  final _ItemRow row;
  final int index;
  final List<UserModel> members;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  final AppDynColors theme;

  const _ItemRowWidget({
    super.key,
    required this.row,
    required this.index,
    required this.members,
    required this.onRemove,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.row.selectedMemberIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final price = double.tryParse(widget.row.priceCtrl.text) ?? 0;
    final isSharedByAll = widget.row.selectedMemberIds.isEmpty;
    final assigneeCount = isSharedByAll
        ? widget.members.length
        : widget.row.selectedMemberIds.length;
    final perPerson = assigneeCount > 0 ? price / assigneeCount : 0.0;
    final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final showSelector = _expanded || !isSharedByAll;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: widget.row.nameCtrl,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Item name',
                      hintStyle: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.success.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: widget.row.priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'RM ',
                      prefixStyle: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.success.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: showSelector ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: theme.textMuted,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          if (isSharedByAll && perPerson > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Shared by all',
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${currencyFmt.format(perPerson)} each',
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (showSelector)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: theme.cardBorder),
                  const SizedBox(height: 10),
                  Text(
                    'Assigned to:',
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.members.map((member) {
                      final selected = widget.row.selectedMemberIds.contains(
                        member.id,
                      );
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              widget.row.selectedMemberIds.remove(member.id);
                            } else {
                              widget.row.selectedMemberIds.add(member.id);
                            }
                            _expanded = widget.row.selectedMemberIds.isNotEmpty;
                          });
                          widget.onChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : theme.cardElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : theme.cardBorder,
                            ),
                          ),
                          child: Text(
                            member.firstName,
                            style: GoogleFonts.inter(
                              color: selected
                                  ? AppColors.primary
                                  : theme.textSecondary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
