import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common.dart';
import '../../models/peer_tab_model.dart';
import '../../models/platform_model.dart';
import '../../vera_theme.dart';
import '../pages/desktop_tab_page.dart';

/// Nexus sol ikon rayı (72px). Üstte gezinme, altta yardım / ayarlar / avatar.
class VeraRail extends StatelessWidget {
  const VeraRail({Key? key}) : super(key: key);

  static void _switchTab(PeerTabIndex index) {
    final model = gFFI.peerTabModel;
    if (model.visibleEnabledOrderedIndexs.contains(index.index)) {
      model.setCurrentTab(index.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    return Container(
      width: VeraTheme.railWidth,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.only(top: 23, bottom: 18),
      child: Column(
        children: [
          _RailButton(
            icon: Icons.hub_outlined,
            tooltip: translate('Connection center'),
            active: true,
            onTap: () => _switchTab(PeerTabIndex.recent),
          ),
          const SizedBox(height: 16),
          _RailButton(
            icon: Icons.grid_view_outlined,
            tooltip: translate('Address book'),
            onTap: () => _switchTab(PeerTabIndex.ab),
          ),
          const SizedBox(height: 16),
          _RailButton(
            icon: Icons.folder_open_outlined,
            tooltip: translate('Transfer file'),
            onTap: () {
              _switchTab(PeerTabIndex.recent);
              showToast(translate('Select a device, then choose Transfer file.'));
            },
          ),
          const SizedBox(height: 16),
          _RailButton(
            icon: Icons.history,
            tooltip: translate('Recent sessions'),
            onTap: () => _switchTab(PeerTabIndex.recent),
          ),
          const Spacer(),
          _RailButton(
            icon: Icons.help_outline,
            tooltip: translate('Help'),
            onTap: () => launchUrl(Uri.parse('https://veranilsoft.com/veradesk')),
          ),
          const SizedBox(height: 16),
          if (!bind.isDisableSettings())
            _RailButton(
              icon: Icons.settings_outlined,
              tooltip: translate('Settings'),
              onTap: DesktopTabPage.onAddSetting,
            ),
          const SizedBox(height: 16),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Text(
              'V',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;
  const _RailButton(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = VeraTheme.of(context);
    final hover = false.obs;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Obx(() {
        final isHover = hover.value;
        return InkWell(
          onTap: onTap,
          onHover: (v) => hover.value = v,
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: active
                      ? c.accent.withOpacity(0.12)
                      : (isHover ? c.panel : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: active
                        ? c.accent
                        : (isHover ? c.text : c.muted)),
              ),
              if (active)
                Positioned(
                  left: -15,
                  top: 11,
                  child: Container(width: 2, height: 20, color: c.accent),
                ),
            ],
          ),
        );
      }),
    );
  }
}
