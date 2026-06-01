import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, itemized, custom, payment }

extension SplitTypeLabel on SplitType {
  String get label {
    switch (this) {
      case SplitType.equal:
        return 'Equal';
      case SplitType.itemized:
        return 'Itemized';
      case SplitType.custom:
        return 'Custom';
      case SplitType.payment:
        return 'Payment';
    }
  }

  String get icon {
    switch (this) {
      case SplitType.equal:
        return '⚖️';
      case SplitType.itemized:
        return '🧾';
      case SplitType.custom:
        return '✏️';
      case SplitType.payment:
        return '💸';
    }
  }
}

class ExpenseItem {
  final String name;
  final double price;
  final List<String> assignedUserIds;

  ExpenseItem({
    required this.name,
    required this.price,
    required this.assignedUserIds,
  });

  double get pricePerUser =>
      assignedUserIds.isEmpty ? 0 : price / assignedUserIds.length;

  ExpenseItem copyWith({
    String? name,
    double? price,
    List<String>? assignedUserIds,
  }) {
    return ExpenseItem(
      name: name ?? this.name,
      price: price ?? this.price,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    );
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      assignedUserIds: List<String>.from(map['assignedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'assignedUserIds': assignedUserIds,
    };
  }
}

class SplitDetail {
  final String userId;
  final double amount;

  const SplitDetail({
    required this.userId,
    required this.amount,
  });

  factory SplitDetail.fromMap(Map<String, dynamic> map) {
    return SplitDetail(
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
    };
  }
}

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String payerId;
  final String groupId;
  final SplitType splitType;
  final List<ExpenseItem> items;
  final List<SplitDetail> splits;
  final List<String> involvedUserIds;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.groupId,
    required this.splitType,
    required this.items,
    required this.splits,
    required this.involvedUserIds,
    required this.date,
  });

  double getUserShare(String userId) {
    try {
      return splits.firstWhere((s) => s.userId == userId).amount;
    } catch (_) {
      return 0;
    }
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      payerId: map['payerId'] ?? '',
      groupId: map['groupId'] ?? '',
      splitType: SplitType.values.firstWhere(
        (e) => e.name == (map['splitType'] ?? 'equal'),
        orElse: () => SplitType.equal,
      ),
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => ExpenseItem.fromMap(e))
              .toList() ??
          [],
      splits: (map['splits'] as List<dynamic>?)
              ?.map((e) => SplitDetail.fromMap(e))
              .toList() ??
          [],
      involvedUserIds: List<String>.from(map['involvedUserIds'] ?? []),
      date: map['date'] != null 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'payerId': payerId,
      'groupId': groupId,
      'splitType': splitType.name,
      'items': items.map((e) => e.toMap()).toList(),
      'splits': splits.map((e) => e.toMap()).toList(),
      'involvedUserIds': involvedUserIds,
      'date': Timestamp.fromDate(date),
    };
  }
}
