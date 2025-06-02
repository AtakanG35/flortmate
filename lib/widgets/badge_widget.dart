import 'package:flutter/material.dart' as flutter;
import '../models/badge.dart';

class BadgeWidget extends flutter.StatelessWidget {
  final Badge badge;
  final bool earned;

  const BadgeWidget({
    flutter.Key? key,
    required this.badge,
    this.earned = false,
  }) : super(key: key);

  @override
  flutter.Widget build(flutter.BuildContext context) {
    final flutter.Color badgeColor = earned ? flutter.Colors.amber : flutter.Colors.grey;
    final double opacity = earned ? 1.0 : 0.3;

    return flutter.Opacity(
      opacity: opacity,
      child: flutter.Card(
        elevation: 4,
        shape: flutter.RoundedRectangleBorder(borderRadius: flutter.BorderRadius.circular(12)),
        child: flutter.Container(
          width: 120,
          padding: const flutter.EdgeInsets.all(12),
          child: flutter.Column(
            mainAxisSize: flutter.MainAxisSize.min,
            children: [
              // Rozet ikonu
              flutter.Image.asset(
                badge.iconPath,
                width: 60,
                height: 60,
                color: badgeColor,
                colorBlendMode: flutter.BlendMode.modulate,
                errorBuilder: (context, error, stackTrace) {
                  return flutter.Icon(
                    flutter.Icons.emoji_events,
                    size: 60,
                    color: badgeColor,
                  );
                },
              ),
              const flutter.SizedBox(height: 8),
              // Başlık
              flutter.Text(
                badge.title,
                style: flutter.TextStyle(
                  fontWeight: flutter.FontWeight.bold,
                  fontSize: 14,
                  color: badgeColor,
                ),
                textAlign: flutter.TextAlign.center,
              ),
              const flutter.SizedBox(height: 4),
              // Açıklama
              flutter.Text(
                badge.description,
                style: flutter.TextStyle(
                  fontSize: 12,
                  color: badgeColor.withOpacity(0.8),
                ),
                textAlign: flutter.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
