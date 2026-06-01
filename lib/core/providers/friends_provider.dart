import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AddFriendResult {
  success,
  alreadyFriend,
  notFound,
  cannotAddSelf,
  error,
}

class FriendsProvider with ChangeNotifier {
  String _currentUserId = '';
  List<UserModel> _friends = [];
  List<UserModel> _receivedRequests = [];
  bool _isLoading = false;

  StreamSubscription? _currentUserSub;
  StreamSubscription? _requestsSub;
  final Map<String, StreamSubscription> _friendSubs = {};

  List<UserModel> get friends => List.unmodifiable(_friends);
  List<UserModel> get receivedRequests => List.unmodifiable(_receivedRequests);
  bool get isLoading => _isLoading;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _listenToFriends();
    }
  }

  void _listenToFriends() {
    _cancelAllSubs();
    
    if (_currentUserId.isEmpty) {
      clearData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // 1. Listen to the current user's document to get their friendIds
    _currentUserSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawFriendIds = data['friendIds'];
        final friendIds = <String>{};
        if (rawFriendIds is List) {
          for (var id in rawFriendIds) {
            if (id != null && id.toString().isNotEmpty) {
              friendIds.add(id.toString());
            }
          }
        }
        
        // Remove subscriptions for friends that were removed
        final removedIds = _friendSubs.keys.where((id) => !friendIds.contains(id)).toList();
        for (final id in removedIds) {
          _friendSubs[id]?.cancel();
          _friendSubs.remove(id);
          _friends.removeWhere((f) => f.id == id);
        }

        // Add subscriptions for new friends
        final newIds = friendIds.where((id) => !_friendSubs.containsKey(id)).toList();
        for (final id in newIds) {
          _friendSubs[id] = FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .snapshots()
              .listen((friendDoc) {
            if (friendDoc.exists && friendDoc.data() != null) {
              final friendUser = UserModel.fromMap(friendDoc.data()!);
              final index = _friends.indexWhere((f) => f.id == id);
              if (index != -1) {
                _friends[index] = friendUser;
              } else {
                _friends.add(friendUser);
              }
              // Received request cleanup just in case
              _receivedRequests.removeWhere((r) => r.id == id);
              notifyListeners();
            }
          });
        }
        
        _isLoading = false;
        notifyListeners();
      }
    });

    // 2. Listen to received requests (users who have currentUserId in their friendIds but aren't in current user's friendIds)
    _requestsSub = FirebaseFirestore.instance
        .collection('users')
        .where('friendIds', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      final incoming = snapshot.docs.map((d) => UserModel.fromMap(d.data())).toList();
      
      // Filter out those who are already our friends
      _receivedRequests = incoming.where((u) => !_friendSubs.containsKey(u.id)).toList();
      notifyListeners();
    });
  }

  void _cancelAllSubs() {
    _currentUserSub?.cancel();
    _currentUserSub = null;
    _requestsSub?.cancel();
    _requestsSub = null;
    for (final sub in _friendSubs.values) {
      sub.cancel();
    }
    _friendSubs.clear();
  }

  void clearData() {
    _currentUserId = '';
    _friends = [];
    _receivedRequests = [];
    _isLoading = false;
    _cancelAllSubs();
    notifyListeners();
  }

  // Backwards compatibility for UI that might call loadFriends manually
  Future<void> loadFriends() async {
    if (_currentUserId.isNotEmpty && _currentUserSub == null) {
      _listenToFriends();
    }
  }

  // Search users by username prefix
  Future<List<UserModel>> searchUsers(String query) async {
    if (_currentUserId.isEmpty || query.isEmpty) return [];

    final normalized = query.replaceAll('@', '').toLowerCase().trim();
    if (normalized.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: normalized)
          .where('username', isLessThanOrEqualTo: '$normalized\\uf8ff')
          .limit(10)
          .get();

      final results = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((u) => u.id != _currentUserId && !isFriend(u.id))
          .toList();

      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Add a friend directly by UserModel
  Future<AddFriendResult> addFriend(UserModel user) async {
    if (_currentUserId.isEmpty) return AddFriendResult.error;

    if (user.id == _currentUserId) return AddFriendResult.cannotAddSelf;
    if (_friends.any((f) => f.id == user.id)) {
      return AddFriendResult.alreadyFriend;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).set({
        'friendIds': FieldValue.arrayUnion([user.id])
      }, SetOptions(merge: true));
      
      // Fetch current user name
      String myName = 'Someone';
      final meDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      if (meDoc.exists && meDoc.data() != null) {
        final data = meDoc.data()!;
        final first = (data['firstName'] as String?)?.trim() ?? '';
        final last = (data['lastName'] as String?)?.trim() ?? '';
        if (first.isNotEmpty || last.isNotEmpty) {
          myName = [first, last].where((s) => s.isNotEmpty).join(' ');
        } else {
          myName = (data['displayName'] as String?)?.trim() ??
              (data['username'] as String?)?.trim() ?? 'Someone';
        }
      }

      // Send friend request notification to the other user
      final notifId = 'notif_friend_$_currentUserId';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(notifId)
          .set({
        'type': 'friendRequest',
        'title': 'New Friend',
        'body': '$myName added you as a friend.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      });

      // No need to manually add to _friends since the stream listener will do it automatically
      return AddFriendResult.success;
    } catch (e) {
      debugPrint('Error adding friend: $e');
      return AddFriendResult.error;
    }
  }

  // Remove friend from Firestore and local state
  Future<void> removeFriend(String userId) async {
    if (_currentUserId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).set({
        'friendIds': FieldValue.arrayRemove([userId])
      }, SetOptions(merge: true));

      // Stream listener will automatically remove from local state
    } catch (e) {
      debugPrint('Error removing friend: $e');
    }
  }

  bool isFriend(String userId) => _friends.any((f) => f.id == userId);

  @override
  void dispose() {
    _cancelAllSubs();
    super.dispose();
  }
}
