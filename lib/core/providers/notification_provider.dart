import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  String _currentUserId = '';
  StreamSubscription? _subscription;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    _subscription?.cancel();
    if (_currentUserId.isEmpty) {
      _notifications.clear();
      notifyListeners();
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to notifications: $e');
    });
  }

  Future<void> sendReminder({
    required String toUserId,
    required String fromUserName,
    required double amount,
    required String groupName,
    required String groupId,
    required String groupEmoji,
    required String settlementId,
  }) async {
    try {
      final notif = AppNotification(
        id: 'reminder_$settlementId',
        type: NotificationType.settlementReminder,
        title: '💸 Payment reminder',
        body: 'You owe $fromUserName RM ${amount.toStringAsFixed(2)} for $groupName. Tap to settle up.',
        timestamp: DateTime.now(),
        groupId: groupId,
        groupEmoji: groupEmoji,
        isRead: false,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .doc(notif.id)
          .set(notif.toMap());
    } catch (e) {
      debugPrint('Error sending reminder: $e');
    }
  }

  Future<void> markAllRead() async {
    if (_currentUserId.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in _notifications) {
        if (!n.isRead) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .collection('notifications')
              .doc(n.id);
          batch.update(ref, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  Future<void> markRead(String id) async {
    if (_currentUserId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  Future<void> clearAll() async {
    if (_currentUserId.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in _notifications) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(n.id);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Future<void> removeNotification(String id) async {
    if (_currentUserId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
