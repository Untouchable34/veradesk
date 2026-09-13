import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../vera_theme.dart';

/// Nexus sağ bağlantı paneli kabuğu ve ortak küçük bileşenler.
class VeraConnectionPanel extends StatelessWidget {
  final List<Widget> children;
  final double width;
  const VeraConnectionPanel(
      {Key? key, required this.children, this.width = VeraTheme.panelWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: VeraTheme.panelGradient(context),
      padding: const EdgeInsets.fromLTRB(23, 25, 23, 21),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// `.input-wrap`: 43px, koyu zemin, ince kenarlık, odakta accent halka.
class VeraInputWrap extends StatelessWidget {
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final RxBool? focused;
  const VeraInputWrap(
      {Key? key, required this.child, this.icon, this.trailing, this.focused})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    Widget box(bool f) => Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(VeraTheme.radiusSmall),
            border: Border.all(color: f ? c.accent : c.border),
            boxShadow: f
                ? [
                    BoxShadow(
                        color: c.accent.withOpacity(0.08), spreadRadius: 3)
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: c.muted),
              if (icon != null) const SizedBox(width: 10),
              Expanded(child: child),
              if (trailing != null) trailing!,
            ],
          ),
        );
    if (focused == null) return box(false);
    return Obx(() => box(focused!.value));
  }
}

/// Küçük etiket (`.label`).
class VeraLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const VeraLabel(this.text, {Key? key, this.hint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: c.text),
          children: [
            if (hint != null)
              TextSpan(
                  text: ' · $hint',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// Birincil (accent) buton, 44px.
class VeraPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  const VeraPrimaryButton(
      {Key? key,
      required this.text,
      required this.onTap,
      this.icon = Icons.arrow_forward})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VeraTheme.radiusSmall),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(VeraTheme.radiusSmall),
            boxShadow: [
              BoxShadow(
                  color: c.accent.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.onAccent)),
              const SizedBox(width: 14),
              Icon(icon, size: 16, color: c.onAccent),
            ],
          ),
        ),
      ),
    );
  }
}

/// 29×17 anahtar.
class VeraSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const VeraSwitch({Key? key, required this.value, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 29,
        height: 17,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? c.accent : c.border,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
              color: value ? c.onAccent : c.bg, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Sembolik ekran çerçevesi (`.screen-frame`).
class VeraScreenFrame extends StatelessWidget {
  final int seed;
  final bool offline;
  final double height;
  const VeraScreenFrame(
      {Key? key, required this.seed, this.offline = false, this.height = 113})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF05090E),
        border: Border.all(color: const Color(0xFF53616B)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x55000000), blurRadius: 35, offset: Offset(0, 15))
        ],
      ),
      child: Container(
        decoration: VeraTheme.wallpaper(seed, offline: offline),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFF5DA9E9),
                      const Color(0xFFF2F4F7),
                      const Color(0xFF4CC9A0),
                      const Color(0xFFF2A65A),
                      const Color(0xFF7C8CF8),
                    ][i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
