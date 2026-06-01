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

  List<UserModel> get friends => List.unmodifiable(_friends);
  List<UserModel> get receivedRequests => List.unmodifiable(_receivedRequests);
  bool get isLoading => _isLoading;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      notifyListeners();
    }
  }

  void clearData() {
    _currentUserId = '';
    _friends = [];
    _receivedRequests = [];
    _isLoading = false;
    notifyListeners();
  }

  // Fetch all friends from Firestore
  Future<void> loadFriends() async {
    if (_currentUserId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawFriendIds = data['friendIds'];
        final friendIds = <String>[];
        if (rawFriendIds is List) {
          for (var id in rawFriendIds) {
            if (id != null && id.toString().isNotEmpty) {
              friendIds.add(id.toString());
            }
          }
        }
        
        if (friendIds.isEmpty) {
          _friends = [];
        } else {
          // Fetch each friend's user document safely
          final futures = friendIds.map((id) {
            return FirebaseFirestore.instance
                .collection('users')
                .doc(id)
                .get()
                .catchError((e) {
              debugPrint('Error fetching friend $id: $e');
              throw e;
            });
          });
          
          try {
            final snapshots = await Future.wait(futures);
            _friends = snapshots
                .where((s) => s.exists && s.data() != null)
                .map((s) => UserModel.fromMap(s.data()!))
                .toList();
          } catch (e) {
            debugPrint('Error in Future.wait: $e');
            // If one fails, we might just have an empty list or we could load them sequentially, but let's leave it empty for now or rely on the cached _friends
          }
        }
      } else {
        _friends = [];
      }

      // Fetch received requests
      final reqSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('friendIds', arrayContains: _currentUserId)
          .get();

      _receivedRequests = reqSnapshot.docs
          .map((d) => UserModel.fromMap(d.data()))
          .where((u) => !_friends.any((f) => f.id == u.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      
      // Fetch current user name (prefer first + last, fallback to display/username)
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

      _friends.add(user);
      _receivedRequests.removeWhere((r) => r.id == user.id);
      notifyListeners();
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

      _friends.removeWhere((f) => f.id == userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing friend: $e');
    }
  }

  bool isFriend(String userId) => _friends.any((f) => f.id == userId);
}
