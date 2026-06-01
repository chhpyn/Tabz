import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groups_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/member_avatar.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;

  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedEmoji;
  final Set<String> _selectedMemberIds = {};

  static const _emojis = [
    '🏝️', '🏠', '🍽️', '🎉', '✈️', '🚗', '🎮', '🛒', '🎓', '💼', '🏋️', '🎸',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final group = context.read<GroupsProvider>().getGroupById(widget.groupId);
    _nameController = TextEditingController(text: group?.name ?? '');
    _descController = TextEditingController(text: group?.description ?? '');
    _selectedEmoji = group?.emoji ?? '🎉';
    
    if (group != null) {
      _selectedMemberIds.addAll(group.memberIds);
      _selectedMemberIds.addAll(group.pendingMemberIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final groupsProvider = context.read<GroupsProvider>();
      final group = groupsProvider.getGroupById(widget.groupId);
      if (group == null) return;

      // Current user is always in memberIds if they are editing
      final newMemberIds = <String>[];
      final newPendingIds = <String>[];

      for (final id in _selectedMemberIds) {
        if (group.memberIds.contains(id)) {
          newMemberIds.add(id);
        } else {
          newPendingIds.add(id);
        }
      }

      await groupsProvider.updateGroup(
        widget.groupId,
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        description: _descController.text.trim(),
        memberIds: newMemberIds,
        pendingMemberIds: newPendingIds,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final friends = context.watch<FriendsProvider>().friends;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Group',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Emoji',
                style: GoogleFonts.inter(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis.map((e) {
                  final selected = e == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : theme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : theme.cardBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Group name',
                  labelStyle: TextStyle(color: theme.textMuted),
                  prefixIcon: Icon(Icons.group_outlined, color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (v) => v != null && v.trim().length >= 2
                    ? null
                    : 'Enter a group name',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: theme.textMuted),
                  prefixIcon: Icon(Icons.notes_rounded, color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Members & Invitations',
                style: GoogleFonts.inter(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              if (friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add friends first to invite them.',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...friends.map((user) {
                  final selected = _selectedMemberIds.contains(user.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedMemberIds.add(user.id);
                      } else {
                        _selectedMemberIds.remove(user.id);
                      }
                    }),
                    title: Text(
                      user.name,
                      style: GoogleFonts.inter(
                        color: theme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      user.displayUsername,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    secondary: MemberAvatar(user: user, radius: 18),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.contrast,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
