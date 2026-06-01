import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';

class ExpenseProvider with ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String _currentUserId = '';
  StreamSubscription? _expenseSubscription;

  // Cached settlements per group
  final Map<String, List<SettlementModel>> _settlements = {};

  bool get isLoading => _isLoading;
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _listenToExpenses();
    }
  }

  void _listenToExpenses() {
    _expenseSubscription?.cancel();
    
    if (_currentUserId.isEmpty) {
      clearData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _expenseSubscription = FirebaseFirestore.instance
        .collection('expenses')
        .where('involvedUserIds', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      _expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Clear cached settlements so they recompute with new data
      _settlements.clear();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to expenses: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void clearData() {
    _currentUserId = '';
    _expenses = [];
    _settlements.clear();
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    notifyListeners();
  }

  List<ExpenseModel> getExpensesForGroup(String groupId) {
    return _expenses
        .where((e) => e.groupId == groupId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalSpentForGroup(String groupId) {
    // Only count actual expenses, not payments
    return getExpensesForGroup(groupId)
        .where((e) => e.splitType != SplitType.payment)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Positive = user is owed this amount. Negative = user owes this amount.
  Map<String, double> calculateNetBalances(
    String groupId,
    List<String> memberIds,
  ) {
    final balances = <String, double>{};
    for (final id in memberIds) {
      balances[id] = 0;
    }

    for (final expense in getExpensesForGroup(groupId)) {
      // Payer receives full amount (credit)
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0) + expense.amount;
          
      // Each member is debited their share
      for (final split in expense.splits) {
        balances[split.userId] =
            (balances[split.userId] ?? 0) - split.amount;
      }
    }
    return balances;
  }

  /// Bilateral settlements: calculates exactly who owes whom between pairs.
  List<SettlementModel> calculateSettlements(
    String groupId,
    List<String> memberIds,
  ) {
    if (_settlements.containsKey(groupId)) {
      return _settlements[groupId]!;
    }
    
    final pairBalances = <String, double>{};
    
    for (final expense in getExpensesForGroup(groupId)) {
      final payerId = expense.payerId;
      for (final split in expense.splits) {
        final debtorId = split.userId;
        if (payerId == debtorId) continue;
        
        final pairKey = [payerId, debtorId]..sort();
        final key = '${pairKey[0]}:${pairKey[1]}';
        
        // Define value as: pairKey[0] owes pairKey[1]
        double amount = split.amount;
        if (payerId == pairKey[0]) {
          // pairKey[0] paid, so pairKey[1] owes pairKey[0] (negative debt for pairKey[0])
          pairBalances[key] = (pairBalances[key] ?? 0) - amount;
        } else {
          // pairKey[1] paid, so pairKey[0] owes pairKey[1] (positive debt for pairKey[0])
          pairBalances[key] = (pairBalances[key] ?? 0) + amount;
        }
      }
    }
    
    final settlements = <SettlementModel>[];
    for (final entry in pairBalances.entries) {
      if (entry.value.abs() < 0.01) continue;
      
      final users = entry.key.split(':');
      final user0 = users[0];
      final user1 = users[1];
      
      if (entry.value > 0) {
        // user0 owes user1
        settlements.add(
          SettlementModel(
            id: 'settle_${groupId}_${user0}_$user1',
            fromUserId: user0,
            toUserId: user1,
            amount: double.parse(entry.value.toStringAsFixed(2)),
          ),
        );
      } else {
        // user1 owes user0
        settlements.add(
          SettlementModel(
            id: 'settle_${groupId}_${user0}_$user1',
            fromUserId: user1,
            toUserId: user0,
            amount: double.parse((-entry.value).toStringAsFixed(2)),
          ),
        );
      }
    }
    
    _settlements[groupId] = settlements;
    return settlements;
  }

  Future<void> addExpense(
    ExpenseModel expense, {
    required String payerName,
    required String groupName,
    required String groupEmoji,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final docRef = FirebaseFirestore.instance.collection('expenses').doc();
      final newExpense = ExpenseModel(
        id: docRef.id,
        title: expense.title,
        amount: expense.amount,
        payerId: expense.payerId,
        groupId: expense.groupId,
        splitType: expense.splitType,
        items: expense.items,
        splits: expense.splits,
        involvedUserIds: expense.involvedUserIds,
        date: expense.date,
      );
      
      batch.set(docRef, newExpense.toMap());

      // Create notifications for all involved users except the payer
      final currencyFmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
      
      for (final split in expense.splits) {
        if (split.userId == expense.payerId) continue;
        if (split.amount <= 0) continue;

        final notifId = 'notif_exp_${newExpense.id}';
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(split.userId)
            .collection('notifications')
            .doc(notifId);

        batch.set(notifRef, {
          'type': 'newExpense',
          'title': '$groupEmoji New expense in $groupName',
          'body': '$payerName added "${expense.title}" — your share is ${currencyFmt.format(split.amount)}.',
          'timestamp': expense.date.millisecondsSinceEpoch,
          'groupId': expense.groupId,
          'groupEmoji': groupEmoji,
          'isRead': false,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error adding expense: $e');
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    // Optimistic local update for instant UI feedback
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _settlements.clear();
      notifyListeners();
    }

    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      debugPrint('Error updating expense: $e');
    }
  }

  Future<void> recordPayment({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('expenses').doc();
      final paymentExpense = ExpenseModel(
        id: docRef.id,
        title: 'Payment',
        amount: amount,
        payerId: fromUserId, // The person who owed the money pays it
        groupId: groupId,
        splitType: SplitType.payment,
        items: [],
        splits: [
          SplitDetail(userId: toUserId, amount: amount), // The person who is owed gets the split
        ],
        involvedUserIds: [fromUserId, toUserId],
        date: DateTime.now(),
      );
      
      await docRef.set(paymentExpense.toMap());
    } catch (e) {
      debugPrint('Error recording payment: $e');
    }
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
