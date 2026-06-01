import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';
import '../widgets/member_avatar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _usernameController = TextEditingController();
  bool _isSearching = false;
  List<UserModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _searchFriends() async {
    final raw = _usernameController.text.trim();
    if (raw.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    if (!mounted) return;
    final friendsProvider = context.read<FriendsProvider>();
    final results = await friendsProvider.searchUsers(raw);

    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    }
  }

  Future<void> _addSpecificFriend(UserModel user) async {
    final friendsProvider = context.read<FriendsProvider>();
    final result = await friendsProvider.addFriend(user);

    String message;
    Color bgColor;

    switch (result) {
      case AddFriendResult.success:
        message = 'Friend added!';
        bgColor = AppColors.success;
        setState(() {
          _searchResults.removeWhere((u) => u.id == user.id);
        });
        break;
      case AddFriendResult.alreadyFriend:
        message = 'Already in your friends list.';
        bgColor = AppColors.warning;
        break;
      case AddFriendResult.cannotAddSelf:
        message = "That's you! You can't add yourself.";
        bgColor = AppColors.warning;
        break;
      case AddFriendResult.notFound:
        message = 'No user found with that username.';
        bgColor = AppColors.accent;
        break;
      case AddFriendResult.error:
        message = 'An error occurred. Please try again.';
        bgColor = AppColors.accent;
        break;
    }

    if (mounted) {
      if (result == AddFriendResult.success) {
        TopBanner.show(context, message, backgroundColor: bgColor);
      } else {
        TopBanner.show(context, message, backgroundColor: bgColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final friendsProvider = context.watch<FriendsProvider>();
    final friends = friendsProvider.friends;
    final receivedRequests = friendsProvider.receivedRequests;

    return Scaffold(
      backgroundColor: theme.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.background,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Friends',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: false,
                  elevation: 0,
                ),
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add friends to split expenses together.',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add Friend Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.contrast,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add a Friend',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _usernameController,
                                  style: TextStyle(color: theme.textPrimary),
                                  textInputAction: TextInputAction.search,
                                  onFieldSubmitted: (_) => _searchFriends(),
                                  onChanged: (val) {
                                    if (val.isEmpty) {
                                      setState(() => _searchResults = []);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'username',
                                    hintStyle: GoogleFonts.inter(
                                      color: theme.textMuted,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '@',
                                        style: GoogleFonts.inter(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: theme.card,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 50,
                                child: _isSearching
                                    ? Container(
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _searchFriends,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                          ),
                                        ),
                                        child: Text(
                                          'Search',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Results
                if (_searchResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Results',
                            style: GoogleFonts.inter(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._searchResults.map(
                            (user) => _SearchResultTile(
                              user: user,
                              theme: theme,
                              onAdd: () => _addSpecificFriend(user),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Added You
                if (receivedRequests.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Added You',
                            style: GoogleFonts.inter(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...receivedRequests.map(
                            (user) => _SearchResultTile(
                              user: user,
                              theme: theme,
                              buttonText: 'Add Back',
                              onAdd: () => _addSpecificFriend(user),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Friends Count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                    child: Row(
                      children: [
                        Text(
                          'My Friends',
                          style: GoogleFonts.inter(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${friends.length}',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty State
                if (friends.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 52,
                              color: theme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends yet',
                              style: GoogleFonts.inter(
                                color: theme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Search by @username to add friends',
                              style: GoogleFonts.inter(
                                color: theme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Friends List
                if (friends.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) => _FriendTile(
                          friend: friends[index],
                          theme: theme,
                          onRemove: () {
                            context.read<FriendsProvider>().removeFriend(
                              friends[index].id,
                            );
                          },
                        ),
                        childCount: friends.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Friend Tile
class _FriendTile extends StatelessWidget {
  final UserModel friend;
  final AppDynColors theme;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friend,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          MemberAvatar(user: friend, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: GoogleFonts.inter(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  friend.displayUsername,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmRemove(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.accent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final theme = AppDynColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Remove Friend',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Remove ${friend.name} from your friends list?',
          style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Search Result Tile
class _SearchResultTile extends StatelessWidget {
  final UserModel user;
  final AppDynColors theme;
  final VoidCallback onAdd;
  final String buttonText;

  const _SearchResultTile({
    required this.user,
    required this.theme,
    required this.onAdd,
    this.buttonText = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          MemberAvatar(user: user, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  user.displayUsername,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              buttonText,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
