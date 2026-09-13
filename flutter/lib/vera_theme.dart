import 'package:flutter/material.dart';

/// VeraDesk görsel sistemi ("Nexus" yönü). Tokenlar design/next-2026-09-13
/// prototipinden alındı. Koyu tema birincil; açık tema aynı yapının
/// aydınlık karşılığıdır.
class VeraColors {
  final Color bg;
  final Color surface;
  final Color panel;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color error;
  final Color online;

  const VeraColors({
    required this.bg,
    required this.surface,
    required this.panel,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.error,
    required this.online,
  });

  static const dark = VeraColors(
    bg: Color(0xFF0A151D),
    surface: Color(0xFF0E1B23),
    panel: Color(0xFF14232C),
    border: Color(0xFF293A42),
    text: Color(0xFFEAF3F5),
    muted: Color(0xFF92A5AF),
    accent: Color(0xFF8DF0D1),
    onAccent: Color(0xFF092C25),
    error: Color(0xFFFFB0A5),
    online: Color(0xFF8DF0D1),
  );

  static const light = VeraColors(
    bg: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    panel: Color(0xFFEEF2F7),
    border: Color(0xFFDCE3EA),
    text: Color(0xFF101C24),
    muted: Color(0xFF5B6E78),
    accent: Color(0xFF114A55),
    onAccent: Color(0xFFFFFFFF),
    error: Color(0xFFB42318),
    online: Color(0xFF17B26A),
  );
}

class VeraTheme {
  static VeraColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? VeraColors.dark
          : VeraColors.light;

  static const String fontFamily = 'Manrope';
  static const String monoFamily = 'JetBrainsMono';

  static const double radius = 11;
  static const double radiusSmall = 7;
  static const double railWidth = 72;
  static const double panelWidth = 308;

  /// Büyük harfli, geniş aralıklı küçük etiket ("YENİ BAĞLANTI").
  static TextStyle kicker(BuildContext context) => TextStyle(
        fontSize: 10,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
        color: of(context).muted,
      );

  static TextStyle mono(BuildContext context,
          {double size = 20, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.5,
        color: of(context).text,
      );

  static TextStyle heading(BuildContext context, {double size = 27}) =>
      TextStyle(
        fontSize: size,
        height: 1.25,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
        color: of(context).text,
      );

  static BoxDecoration card(BuildContext context, {bool selected = false}) {
    final c = of(context);
    return BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: selected ? c.accent.withOpacity(0.6) : c.border, width: 1),
    );
  }

  /// Sağ bağlantı panelinin arka planı.
  static BoxDecoration panelGradient(BuildContext context) {
    final c = of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF182C36), Color(0xFF10202A)]
            : [c.surface, c.panel],
        stops: const [0, 0.55],
      ),
      border: Border(left: BorderSide(color: c.border)),
    );
  }

  /// Cihaz kartlarında ve önizlemede kullanılan sembolik "ekran" duvar kağıdı.
  static BoxDecoration wallpaper(int seed, {bool offline = false}) {
    const palettes = [
      [Color(0xFF17395C), Color(0xFF2B5C8A), Color(0xFF10263D)],
      [Color(0xFF0F3B3F), Color(0xFF1F6A6E), Color(0xFF0B2628)],
      [Color(0xFF3B2C58), Color(0xFF6A4E8A), Color(0xFF241A38)],
      [Color(0xFF4A3410), Color(0xFF8A6420), Color(0xFF2E2008)],
    ];
    final p = palettes[seed.abs() % palettes.length];
    final colors = offline
        ? p.map((c) => Color.lerp(c, const Color(0xFF3A3F44), 0.75)!).toList()
        : p;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0, 0.55, 1],
      ),
    );
  }
}
