// lib/models/badge.dart

class Badge {
  final String id;
  final String title;
  final String description;
  final String iconPath; // Asset ya da network URL olabilir

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
  });
}

/// Örnek rozet listesi
const List<Badge> allBadges = [
  Badge(
    id: 'first_like',
    title: 'İlk Beğeni',
    description: 'İlk kez birisini beğendin!',
    iconPath: 'assets/badges/first_like.png',
  ),
  Badge(
    id: 'top_chat',
    title: 'Sohbet Ustası',
    description: '100+ mesajla aktif bir sohbetçi oldun!',
    iconPath: 'assets/badges/top_chat.png',
  ),
  Badge(
    id: 'profile_complete',
    title: 'Profil Tamamlandı',
    description: 'Profil bilgilerini tam doldurdun.',
    iconPath: 'assets/badges/profile_complete.png',
  ),
  Badge(
    id: 'daily_login',
    title: 'Günlük Giriş',
    description: '7 gün üst üste giriş yaptın!',
    iconPath: 'assets/badges/daily_login.png',
  ),
  // Buraya istediğin kadar rozet ekleyebilirsin
];
