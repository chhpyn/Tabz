import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class GroupsProvider with ChangeNotifier {
  String _currentUserId = '';
  List<GroupModel> _activeGroupsList = [];
  List<GroupModel> _pendingGroupsList = [];
  final Map<String, UserModel> _userCache = {};
  bool _isLoading = false;

  StreamSubscription? _activeGroupsSub;
  StreamSubscription? _pendingGroupsSub;
  final Map<String, StreamSubscription> _userSubs = {};

  List<GroupModel> get _groups {
    final all = [..._activeGroupsList, ..._pendingGroupsList];
    final map = <String, GroupModel>{};
    for (var g in all) map[g.id] = g;
    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<GroupModel> get activeGroups => 
      _groups.where((g) => g.memberIds.contains(_currentUserId)).toList();
  
  List<GroupModel> get pendingInvitations => 
      _groups.where((g) => g.pendingMemberIds.contains(_currentUserId)).toList();

  List<GroupModel> get groups => activeGroups; // For backwards compatibility

  bool get isLoading => _isLoading;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _listenToGroups();
    }
  }

  void _listenToGroups() {
    _cancelAllSubs();
    
    if (_currentUserId.isEmpty) {
      clearData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _activeGroupsSub = FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      _activeGroupsList = snapshot.docs.map((e) => GroupModel.fromMap(e.data(), e.id)).toList();
      _updateUserSubscriptions();
      _isLoading = false;
      notifyListeners();
    });

    _pendingGroupsSub = FirebaseFirestore.instance
        .collection('groups')
        .where('pendingMemberIds', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      _pendingGroupsList = snapshot.docs.map((e) => GroupModel.fromMap(e.data(), e.id)).toList();
      _updateUserSubscriptions();
      notifyListeners();
    });
  }

  void _updateUserSubscriptions() {
    final uniqueMemberIds = <String>{};
    for (final group in _groups) {
      uniqueMemberIds.addAll(group.memberIds);
      uniqueMemberIds.addAll(group.pendingMemberIds);
    }

    // Remove subscriptions for users no longer in any group
    final removedIds = _userSubs.keys.where((id) => !uniqueMemberIds.contains(id)).toList();
    for (final id in removedIds) {
      _userSubs[id]?.cancel();
      _userSubs.remove(id);
      _userCache.remove(id);
    }

    // Add subscriptions for new users
    final newIds = uniqueMemberIds.where((id) => !_userSubs.containsKey(id)).toList();
    for (final id in newIds) {
      _userSubs[id] = FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists && userDoc.data() != null) {
          _userCache[id] = UserModel.fromMap(userDoc.data()!);
          notifyListeners();
        }
      });
    }
  }

  void _cancelAllSubs() {
    _activeGroupsSub?.cancel();
    _activeGroupsSub = null;
    _pendingGroupsSub?.cancel();
    _pendingGroupsSub = null;
    for (final sub in _userSubs.values) {
      sub.cancel();
    }
    _userSubs.clear();
  }

  void clearData() {
    _currentUserId = '';
    _activeGroupsList = [];
    _pendingGroupsList = [];
    _userCache.clear();
    _isLoading = false;
    _cancelAllSubs();
    notifyListeners();
  }

  // Backwards compatibility for explicit refreshes
  Future<void> loadGroups() async {
    if (_currentUserId.isNotEmpty && _activeGroupsSub == null) {
      _listenToGroups();
    }
  }

  GroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<UserModel> getMembersOfGroup(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return [];
    
    return group.memberIds
        .map((id) => _userCache[id])
        .whereType<UserModel>()
        .toList();
  }

  List<UserModel> getPendingMembersOfGroup(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return [];
    
    return group.pendingMemberIds
        .map((id) => _userCache[id])
        .whereType<UserModel>()
        .toList();
  }

  UserModel? getUserById(String userId) {
    return _userCache[userId];
  }

  UserModel? getUserByUsername(String username) {
    final normalized = username.replaceAll('@', '').toLowerCase().trim();
    try {
      return _userCache.values.firstWhere(
        (u) => u.username.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> createGroup({
    required String name,
    required String emoji,
    required String description,
    required List<String> memberIds,
  }) async {
    if (_currentUserId.isEmpty) return;

    final newGroupRef = FirebaseFirestore.instance.collection('groups').doc();
    
    final newGroup = GroupModel(
      id: newGroupRef.id,
      name: name,
      emoji: emoji,
      description: description,
      memberIds: [_currentUserId],
      pendingMemberIds: memberIds.where((id) => id != _currentUserId).toList(),
      createdAt: DateTime.now(),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(newGroupRef, newGroup.toMap());

      // Send group request notifications to pending members
      if (newGroup.pendingMemberIds.isNotEmpty) {
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

        for (final pendingId in newGroup.pendingMemberIds) {
          final notifId = 'notif_group_${newGroupRef.id}';
          final notifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(pendingId)
              .collection('notifications')
              .doc(notifId);
              
          batch.set(notifRef, {
            'type': 'groupRequest',
            'title': '$emoji Group Invitation',
            'body': '$myName invited you to join "$name".',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'groupId': newGroupRef.id,
            'groupEmoji': emoji,
            'isRead': false,
          });
        }
      }

      await batch.commit();
      // Listeners will automatically update _groups
    } catch (e) {
      debugPrint('Error creating group: $e');
    }
  }

  Future<void> acceptInvitation(String groupId) async {
    if (_currentUserId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'pendingMemberIds': FieldValue.arrayRemove([_currentUserId]),
        'memberIds': FieldValue.arrayUnion([_currentUserId]),
      });
    } catch (e) {
      debugPrint('Error accepting invite: $e');
    }
  }

  Future<void> declineInvitation(String groupId) async {
    if (_currentUserId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'pendingMemberIds': FieldValue.arrayRemove([_currentUserId]),
      });
    } catch (e) {
      debugPrint('Error declining invite: $e');
    }
  }

  Future<void> updateGroup(String groupId, {
    required String name,
    required String emoji,
    required String description,
    required List<String> memberIds,
    required List<String> pendingMemberIds,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'name': name,
        'emoji': emoji,
        'description': description,
        'memberIds': memberIds,
        'pendingMemberIds': pendingMemberIds,
      });
    } catch (e) {
      debugPrint('Error updating group: $e');
    }
  }

  @override
  void dispose() {
    _cancelAllSubs();
    super.dispose();
  }
}
