import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class GroupsProvider with ChangeNotifier {
  String _currentUserId = '';
  List<GroupModel> _groups = [];
  final Map<String, UserModel> _userCache = {};
  bool _isLoading = false;
  int _loadVersion = 0;

  List<GroupModel> get activeGroups => 
      _groups.where((g) => g.memberIds.contains(_currentUserId)).toList();
  
  List<GroupModel> get pendingInvitations => 
      _groups.where((g) => g.pendingMemberIds.contains(_currentUserId)).toList();

  List<GroupModel> get groups => activeGroups; // For backwards compatibility

  bool get isLoading => _isLoading;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      notifyListeners();
    }
  }

  void clearData() {
    _currentUserId = '';
    _groups = [];
    _userCache.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadGroups() async {
    if (_currentUserId.isEmpty) return;

    final loadVersion = ++_loadVersion;
    _isLoading = true;
    notifyListeners();

    try {
      final activeSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: _currentUserId)
          .get();

      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('pendingMemberIds', arrayContains: _currentUserId)
          .get();

      final allDocs = <String, Map<String, dynamic>>{};
      for (final doc in activeSnapshot.docs) allDocs[doc.id] = doc.data();
      for (final doc in pendingSnapshot.docs) allDocs[doc.id] = doc.data();

      final loadedGroups = allDocs.entries
          .map((e) => GroupModel.fromMap(e.value, e.key))
          .toList();
      loadedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Collect all unique member IDs across all groups
      final uniqueMemberIds = <String>{};
      for (final group in loadedGroups) {
        uniqueMemberIds.addAll(group.memberIds);
        uniqueMemberIds.addAll(group.pendingMemberIds);
      }

      // Fetch users that are not already in the cache
      final idsToFetch = uniqueMemberIds.where((id) => !_userCache.containsKey(id)).toList();

      if (idsToFetch.isNotEmpty) {
        final futures = idsToFetch.map((id) {
          return FirebaseFirestore.instance.collection('users').doc(id).get().catchError((e) {
            debugPrint('Error fetching user $id: $e');
            throw e;
          });
        });

        try {
          final userSnapshots = await Future.wait(futures);
          for (final userSnap in userSnapshots) {
            if (userSnap.exists && userSnap.data() != null) {
              final user = UserModel.fromMap(userSnap.data()!);
              _userCache[user.id] = user;
            }
          }
        } catch (e) {
          debugPrint('Error in Future.wait for users: $e');
        }
      }

      if (loadVersion != _loadVersion) return;

      _groups = loadedGroups;
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      if (loadVersion == _loadVersion) {
        _isLoading = false;
        notifyListeners();
      }
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
      _groups = [newGroup, ..._groups];
      notifyListeners();
      await loadGroups();
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
      await loadGroups();
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
      await loadGroups();
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
      await loadGroups();
    } catch (e) {
      debugPrint('Error updating group: $e');
    }
  }
}
