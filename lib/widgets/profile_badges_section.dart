import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../widgets/badge.dart';

class ProfileBadgesSection extends StatelessWidget {
  final List<String> earnedBadgeIds; // Kullanıcının kazandığı rozet ID’leri
  final bool isEditing; // Düzenleme modunda mı?

  const ProfileBadgesSection({
    super.key,
    required this.earnedBadgeIds,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<BadgeModel> earnedBadges = allBadges
        .where((badge) => earnedBadgeIds.contains(badge.id))
        .toList();

    final List<BadgeModel> unearnedBadges = allBadges
        .where((badge) => !earnedBadgeIds.contains(badge.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Rozetlerim',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...earnedBadges.map((badge) => BadgeWidget(
              badge: badge,
              earned: true,
            )),
            if (isEditing)
              ...unearnedBadges.map((badge) => BadgeWidget(
                badge: badge,
                earned: false,
              )),
          ],
        ),
      ],
    );
  }
}
