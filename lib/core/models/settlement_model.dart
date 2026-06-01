class SettlementModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  bool isPaid;

  SettlementModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.isPaid = false,
  });
}
