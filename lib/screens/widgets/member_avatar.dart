import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';

class MemberAvatar extends StatefulWidget {
  final UserModel user;
  final double radius;
  final bool showBorder;
  final bool showTooltip;

  const MemberAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.showBorder = false,
    this.showTooltip = false,
  });

  static Color getConsistentAvatarColor(String userId) {
    final hash = userId.hashCode.abs();
    final colorIndex = hash % AppColors.avatarColors.length;
    return AppColors.avatarColors[colorIndex];
  }

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final hasImage =
        widget.user.profileImageUrl != null && !_imageLoadFailed;
    final avatarColor = MemberAvatar.getConsistentAvatarColor(widget.user.id);

    final avatar = Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: hasImage ? null : avatarColor,
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(color: theme.background, width: 2)
            : null,
        image: hasImage
            ? DecorationImage(
                image: widget.user.profileImageUrl!.startsWith('http')
                    ? NetworkImage(widget.user.profileImageUrl!)
                        as ImageProvider
                    : FileImage(File(widget.user.profileImageUrl!)),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  setState(() => _imageLoadFailed = true);
                },
              )
            : null,
      ),
      child: !hasImage
          ? Center(
              child: Text(
                widget.user.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.radius * 0.58,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
    if (widget.showTooltip) {
      return Tooltip(message: widget.user.name, child: avatar);
    }
    return avatar;
  }
}

// A row of overlapping member avatars (up to [maxShown], then "+N" badge).
class MemberAvatarStack extends StatelessWidget {
  final List<UserModel> members;
  final double radius;
  final int maxShown;

  const MemberAvatarStack({
    super.key,
    required this.members,
    this.radius = 16,
    this.maxShown = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final shown = members.take(maxShown).toList();
    final extra = members.length - maxShown;
    const overlap = 8.0;

    return SizedBox(
      height: radius * 2,
      width: shown.length * (radius * 2 - overlap) +
          overlap +
          (extra > 0 ? radius * 2 : 0),
      child: Stack(
        children: [
          ...shown.asMap().entries.map((entry) {
            final idx = entry.key;
            return Positioned(
              left: idx * (radius * 2 - overlap),
              child: MemberAvatar(
                user: entry.value,
                radius: radius,
                showBorder: true,
                showTooltip: true,
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: shown.length * (radius * 2 - overlap),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: theme.cardElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.background, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: radius * 0.52,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
