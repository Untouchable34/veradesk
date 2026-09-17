import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../common.dart';
import '../../models/peer_model.dart';
import '../../vera_theme.dart';

/// Nexus "bağlantı merkezi" görseli: ortada marka sembolü, solda bu cihaz,
/// sağda seçili uzak cihaz ve bir uydu düğüm; kesikli yörünge ve rotalar.
class VeraTopology extends StatelessWidget {
  final List<Peer> peers;
  final String selectedId;
  final double height;
  final void Function(Peer peer)? onSelect;

  const VeraTopology({
    Key? key,
    required this.peers,
    required this.selectedId,
    this.height = 324,
    this.onSelect,
  }) : super(key: key);

  static String _osName() {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  static String _peerName(Peer p) {
    if (p.alias.isNotEmpty) return p.alias;
    if (p.hostname.isNotEmpty) return p.hostname;
    return p.id;
  }

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    final wanted = selectedId.replaceAll(' ', '');
    Peer? remote;
    for (final p in peers) {
      if (p.id == wanted) {
        remote = p;
        break;
      }
    }
    remote ??= peers.isNotEmpty ? peers.first : null;
    Peer? satellite;
    for (final p in peers) {
      if (p != remote) {
        satellite = p;
        break;
      }
    }
    final hostname = veraDeviceName();

    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final compact = w < 900;
        final nodeW = compact ? 133.0 : 153.0;
        final symbol = compact ? 110.0 : 150.0;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TopologyPainter(
                  border: c.border,
                  accent: c.accent,
                  localAnchor: Offset(w * 0.04 + nodeW, h * 0.33 + 40),
                  remoteAnchor: Offset(w - w * 0.03 - nodeW, h * 0.21 + 40),
                  center: Offset(w / 2, h / 2 - 10),
                ),
              ),
            ),
            // merkez sembol
            Positioned(
              left: w / 2 - symbol / 2,
              top: h / 2 - 10 - symbol / 2 - 8,
              child: Column(
                children: [
                  Container(
                    width: symbol,
                    height: symbol,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.accent.withOpacity(0.18),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/symbol-3d.png',
                        width: symbol, height: symbol, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 6),
                  Text('VeraDesk',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.text)),
                  const SizedBox(height: 2),
                  Text(translate('Connection center').toUpperCase(),
                      style: VeraTheme.kicker(context)),
                ],
              ),
            ),
            Positioned(
              left: w * 0.04,
              top: h * 0.22,
              child: Text(
                translate('Connection starts here').toUpperCase(),
                style: VeraTheme.kicker(context).copyWith(fontSize: 8),
              ),
            ),
            // bu cihaz
            Positioned(
              left: w * 0.04,
              top: h * 0.33,
              child: _Node(
                width: nodeW,
                icon: Icons.desktop_windows_outlined,
                iconColor: const Color(0xFFA0C4CB),
                title: hostname,
                subtitle: '${translate('This device')} · ${_osName()}',
                status: translate('Ready'),
                statusColor: c.accent,
                borderColor: const Color(0x50638792),
                gradient: const [Color(0x80243D48), Color(0xE8122632)],
              ),
            ),
            // seçili uzak cihaz
            if (remote != null)
              Positioned(
                right: w * 0.03,
                top: h * 0.21,
                child: InkWell(
                  onTap: onSelect == null ? null : () => onSelect!(remote!),
                  borderRadius: BorderRadius.circular(VeraTheme.radius),
                  child: _Node(
                    width: nodeW,
                    icon: Icons.desktop_windows_outlined,
                    iconColor: c.accent,
                    title: _peerName(remote),
                    subtitle: translate('Selected remote device'),
                    status: remote.online
                        ? translate('Online')
                        : translate('Offline'),
                    statusColor: remote.online ? c.accent : c.muted,
                    borderColor: const Color(0x8072C8B2),
                    gradient: const [Color(0x80243D48), Color(0xE8122632)],
                  ),
                ),
              ),
            // uydu düğüm
            if (satellite != null)
              Positioned(
                right: w * 0.06,
                top: h * 0.68,
                child: InkWell(
                  onTap:
                      onSelect == null ? null : () => onSelect!(satellite!),
                  borderRadius: BorderRadius.circular(VeraTheme.radius),
                  child: Container(
                    width: compact ? 120 : 134,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xD9101F28),
                      borderRadius: BorderRadius.circular(VeraTheme.radius),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.devices_other_outlined,
                            size: 20, color: c.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_peerName(satellite),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: c.text)),
                              Text(translate('Other device'),
                                  style: TextStyle(
                                      fontSize: 8, color: c.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Node extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color borderColor;
  final List<Color> gradient;
  const _Node({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.borderColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient),
        borderRadius: BorderRadius.circular(VeraTheme.radius),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(height: 9),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, color: c.muted)),
            ],
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Row(
              children: [
                Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(status,
                    style: TextStyle(fontSize: 8, color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopologyPainter extends CustomPainter {
  final Color border;
  final Color accent;
  final Offset localAnchor;
  final Offset remoteAnchor;
  final Offset center;
  _TopologyPainter({
    required this.border,
    required this.accent,
    required this.localAnchor,
    required this.remoteAnchor,
    required this.center,
  });

  void _dashed(Canvas canvas, Path path, Paint paint,
      {double dash = 4, double gap = 6}) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next = min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final orbit = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromCenter(
        center: center, width: size.width * 0.62, height: size.height * 0.78);
    _dashed(canvas, Path()..addOval(rect), orbit);
    final inner = Rect.fromCenter(
        center: center, width: size.width * 0.34, height: size.height * 0.46);
    _dashed(canvas, Path()..addOval(inner), orbit, dash: 2, gap: 6);

    final route = Paint()
      ..color = accent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final p1 = Path()
      ..moveTo(localAnchor.dx, localAnchor.dy)
      ..quadraticBezierTo(
          (localAnchor.dx + center.dx) / 2, center.dy + 40, center.dx, center.dy);
    final p2 = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo((center.dx + remoteAnchor.dx) / 2, center.dy - 40,
          remoteAnchor.dx, remoteAnchor.dy);
    _dashed(canvas, p1, route, dash: 5, gap: 5);
    _dashed(canvas, p2, route, dash: 5, gap: 5);

    final dot = Paint()..color = accent;
    for (final path in [p1, p2]) {
      for (final m in path.computeMetrics()) {
        final t = m.getTangentForOffset(m.length * 0.55);
        if (t != null) canvas.drawCircle(t.position, 3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter old) =>
      old.localAnchor != localAnchor ||
      old.remoteAnchor != remoteAnchor ||
      old.center != center ||
      old.accent != accent;
}
