// main window right pane

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:veradesk/consts.dart';
import 'package:veradesk/desktop/widgets/popup_menu.dart';
import 'package:veradesk/models/state_model.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';
import 'package:veradesk/models/peer_model.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../common/widgets/peer_tab_page.dart';
import '../../common/widgets/autocomplete.dart';
import '../../vera_theme.dart';
import '../widgets/vera_connection_panel.dart';
import '../widgets/vera_topology.dart';
import '../../models/peer_tab_model.dart';
import 'package:provider/provider.dart';
import '../../models/platform_model.dart';
import '../../desktop/widgets/material_mod_popup_menu.dart' as mod_menu;

class OnlineStatusWidget extends StatefulWidget {
  const OnlineStatusWidget({Key? key, this.onSvcStatusChanged})
      : super(key: key);

  final VoidCallback? onSvcStatusChanged;

  @override
  State<OnlineStatusWidget> createState() => _OnlineStatusWidgetState();
}

/// State for the connection page.
class _OnlineStatusWidgetState extends State<OnlineStatusWidget> {
  final _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  final _svcIsUsingPublicServer = true.obs;
  Timer? _updateTimer;

  double get em => 14.0;
  double? get height => bind.isIncomingOnly() ? null : em * 3;

  void onUsePublicServerGuide() {
    const url = "https://veranilsoft.com/pricing";
    canLaunchUrlString(url).then((can) {
      if (can) {
        launchUrlString(url);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(Duration(seconds: 1), () async {
      updateStatus();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncomingOnly = bind.isIncomingOnly();
    startServiceWidget() => Offstage(
          offstage: !_svcStopped.value,
          child: InkWell(
                  onTap: () async {
                    await start_service(true);
                  },
                  child: Text(translate("Start service"),
                      style: TextStyle(
                          decoration: TextDecoration.underline, fontSize: em)))
              .marginOnly(left: em),
        );

    setupServerWidget() => Flexible(
          child: Offstage(
            offstage: !(!_svcStopped.value &&
                stateGlobal.svcStatus.value == SvcStatus.ready &&
                _svcIsUsingPublicServer.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(', ', style: TextStyle(fontSize: em)),
                Flexible(
                  child: InkWell(
                    onTap: onUsePublicServerGuide,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            translate('setup_server_tip'),
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: em),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );

    basicWidget() => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _svcStopped.value ||
                        stateGlobal.svcStatus.value == SvcStatus.connecting
                    ? kColorWarn
                    : (stateGlobal.svcStatus.value == SvcStatus.ready
                        ? Color.fromARGB(255, 50, 190, 166)
                        : Color.fromARGB(255, 224, 79, 95)),
              ),
            ).marginSymmetric(horizontal: em),
            Container(
              width: isIncomingOnly ? 226 : null,
              child: _buildConnStatusMsg(),
            ),
            // stop
            if (!isIncomingOnly) startServiceWidget(),
            // ready && public
            // No need to show the guide if is custom client.
            if (!isIncomingOnly) setupServerWidget(),
          ],
        );

    return Container(
      height: height,
      child: Obx(() => isIncomingOnly
          ? Column(
              children: [
                basicWidget(),
                Align(
                        child: startServiceWidget(),
                        alignment: Alignment.centerLeft)
                    .marginOnly(top: 2.0, left: 22.0),
              ],
            )
          : basicWidget()),
    ).paddingOnly(right: isIncomingOnly ? 8 : 0);
  }

  _buildConnStatusMsg() {
    widget.onSvcStatusChanged?.call();
    return Text(
      _svcStopped.value
          ? translate("Service is not running")
          : stateGlobal.svcStatus.value == SvcStatus.connecting
              ? translate("connecting_status")
              : stateGlobal.svcStatus.value == SvcStatus.notReady
                  ? translate("not_ready_status")
                  : translate('Ready'),
      style: TextStyle(fontSize: em),
    );
  }

  updateStatus() async {
    final status =
        jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final statusNum = status['status_num'] as int;
    if (statusNum == 0) {
      stateGlobal.svcStatus.value = SvcStatus.connecting;
    } else if (statusNum == -1) {
      stateGlobal.svcStatus.value = SvcStatus.notReady;
    } else if (statusNum == 1) {
      stateGlobal.svcStatus.value = SvcStatus.ready;
    } else {
      stateGlobal.svcStatus.value = SvcStatus.notReady;
    }
    _svcIsUsingPublicServer.value = await bind.mainIsUsingPublicServer();
    try {
      stateGlobal.videoConnCount.value = status['video_conn_count'] as int;
    } catch (_) {}
  }
}

/// Connection page for connecting to a remote peer.
class ConnectionPage extends StatefulWidget {
  /// Sağ panelin altına eklenen içerik (bu cihazın kimliği, yardım kartları).
  final Widget? trailing;
  const ConnectionPage({Key? key, this.trailing}) : super(key: key);

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

/// State for the connection page.
class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin, WindowListener {
  /// Controller for the id input bar.
  final _idController = IDTextEditingController();
  // VeraDesk: şifre ID ile aynı adımda girilir; boş bırakılırsa kayıtlı şifre kullanılır.
  final _pwdController = TextEditingController();
  final _pwdFocusNode = FocusNode();
  final _pwdVisible = false.obs;

  final RxBool _idInputFocused = false.obs;
  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();

  String selectedConnectionType = 'Connect';

  bool isWindowMinimized = false;

  final AllPeersLoader _allPeersLoader = AllPeersLoader();

  // https://github.com/flutter/flutter/issues/157244
  Iterable<Peer> _autocompleteOpts = [];

  final _menuOpen = false.obs;
  // Nexus: "Uzak masaüstü" / "Dosya aktarımı" modu.
  final _fileMode = false.obs;
  final RxBool _pwdFocused = false.obs;

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
    _idFocusNode.addListener(onFocusChanged);
    _pwdFocusNode.addListener(() => _pwdFocused.value = _pwdFocusNode.hasFocus);
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (lastRemoteId != _idController.id) {
          setState(() {
            _idController.id = lastRemoteId;
          });
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
    Get.put<IDTextEditingController>(_idController);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwdController.dispose();
    _pwdFocusNode.dispose();
    windowManager.removeListener(this);
    _allPeersLoader.clear();
    _idFocusNode.removeListener(onFocusChanged);
    _idFocusNode.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == 'minimize') {
      isWindowMinimized = true;
    } else if (eventName == 'maximize' || eventName == 'restore') {
      if (isWindowMinimized && isWindows) {
        // windows can't update when minimized.
        Get.forceAppUpdate();
      }
      isWindowMinimized = false;
    }
  }

  @override
  void onWindowEnterFullScreen() {
    // Remove edge border by setting the value to zero.
    stateGlobal.resizeEdgeSize.value = 0;
  }

  @override
  void onWindowLeaveFullScreen() {
    // Restore edge border to default edge size.
    stateGlobal.resizeEdgeSize.value = stateGlobal.isMaximized.isTrue
        ? kMaximizeEdgeSize
        : windowResizeEdgeSize;
  }

  @override
  void onWindowClose() {
    super.onWindowClose();
    bind.mainOnMainWindowClose();
  }

  void onFocusChanged() {
    _idInputFocused.value = _idFocusNode.hasFocus;
    if (_idFocusNode.hasFocus) {
      if (_allPeersLoader.needLoad) {
        _allPeersLoader.getAllPeers();
      }

      final textLength = _idEditingController.value.text.length;
      // Select all to facilitate removing text, just following the behavior of address input of chrome.
      _idEditingController.selection =
          TextSelection(baseOffset: 0, extentOffset: textLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoingOnly = bind.isOutgoingOnly();
    final c = VeraTheme.of(context);
    final glow = Theme.of(context).brightness == Brightness.dark
        ? const Color(0x70123340)
        : c.accent.withOpacity(0.06);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.9,
                colors: [glow, Colors.transparent],
                stops: const [0, 0.67],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMain(context)),
                if (!isOutgoingOnly) Divider(height: 1, color: c.border),
                if (!isOutgoingOnly) OnlineStatusWidget(),
              ],
            ),
          ),
        ),
        _buildPanel(context),
      ],
    );
  }

  Peer? _selectedPeer() {
    final wanted = _idController.id.replaceAll(' ', '');
    final all = <Peer>[
      ...gFFI.recentPeersModel.peers,
      ..._allPeersLoader.peers,
    ];
    for (final p in all) {
      if (p.id == wanted) return p;
    }
    return null;
  }

  Widget _buildMain(BuildContext context) {
    final c = VeraTheme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final topologyHeight = h >= 760 ? 324.0 : (h >= 600 ? 240.0 : 0.0);
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 27, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translate('Your personal workspace').toUpperCase(),
                          style: VeraTheme.kicker(context)),
                      const SizedBox(height: 5),
                      Text(translate('Close the distance.'),
                          style: VeraTheme.heading(context)),
                      const SizedBox(height: 5),
                      Text(translate('Pick a device. Connect. Carry on.'),
                          style: TextStyle(fontSize: 11, color: c.muted)),
                    ],
                  ),
                ),
                ChangeNotifierProvider.value(
                  value: gFFI.recentPeersModel,
                  child: Consumer<Peers>(builder: (context, model, _) {
                    final online = model.peers.where((p) => p.online).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hub_outlined, size: 13, color: c.muted),
                          const SizedBox(width: 6),
                          Text(
                            '$online ${translate('devices online')}',
                            style: TextStyle(fontSize: 10, color: c.muted),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            if (topologyHeight > 0)
              Padding(
                padding: const EdgeInsets.only(top: 9, bottom: 14),
                child: ChangeNotifierProvider.value(
                  value: gFFI.recentPeersModel,
                  child: Consumer<Peers>(
                    builder: (context, model, _) => VeraTopology(
                      peers: model.peers.take(3).toList(),
                      selectedId: _idController.id,
                      height: topologyHeight,
                      onSelect: (peer) {
                        setState(() {
                          _idController.id = peer.id;
                        });
                      },
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: topologyHeight > 0 ? 0 : 18),
              child: Row(
                children: [
                  ChangeNotifierProvider.value(
                    value: gFFI.recentPeersModel,
                    child: Consumer<Peers>(
                      builder: (context, model, _) => RichText(
                        text: TextSpan(
                          text: translate('Your devices'),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: c.text),
                          children: [
                            TextSpan(
                              text:
                                  '  / ${model.peers.length.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      final m = gFFI.peerTabModel;
                      if (m.visibleEnabledOrderedIndexs
                          .contains(PeerTabIndex.ab.index)) {
                        m.setCurrentTab(PeerTabIndex.ab.index);
                      }
                    },
                    child: Row(
                      children: [
                        Text(translate('View all'),
                            style: TextStyle(fontSize: 11, color: c.accent)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12, color: c.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: PeerTabPage()),
          ],
        ),
      );
    });
  }

  Widget _buildPanel(BuildContext context) {
    final c = VeraTheme.of(context);
    final peer = _selectedPeer();
    final title = peer == null
        ? translate('Remote device')
        : (peer.alias.isNotEmpty
            ? peer.alias
            : (peer.hostname.isNotEmpty ? peer.hostname : peer.id));
    final seed = _idController.id.replaceAll(' ', '').hashCode;
    return VeraConnectionPanel(
      children: [
        Text(translate('New connection').toUpperCase(),
            style: VeraTheme.kicker(context)),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: c.text)),
              ),
              Icon(Icons.link, size: 18, color: c.accent),
            ],
          ),
        ),
        VeraScreenFrame(seed: seed, offline: peer != null && !peer.online),
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 2),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(VeraTheme.radiusSmall),
          ),
          child: Obx(() => Row(
                children: [
                  _modeTab(context, Icons.desktop_windows_outlined,
                      translate('Remote desktop'), !_fileMode.value,
                      () => _fileMode.value = false),
                  const SizedBox(width: 3),
                  _modeTab(context, Icons.folder_open_outlined,
                      translate('Transfer file'), _fileMode.value,
                      () => _fileMode.value = true),
                ],
              )),
        ),
        VeraLabel(translate('Remote device ID')),
        _buildRemoteIDTextField(context),
        VeraLabel(translate('Password'),
            hint: translate('leave empty if remembered')),
        VeraInputWrap(
          icon: Icons.lock_outline,
          focused: _pwdFocused,
          trailing: Obx(() => InkWell(
                onTap: () => _pwdVisible.value = !_pwdVisible.value,
                child: Icon(
                    _pwdVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: c.muted),
              )),
          child: Obx(() => TextField(
                focusNode: _pwdFocusNode,
                controller: _pwdController,
                obscureText: !_pwdVisible.value,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: c.text),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  hintText: translate('Device password'),
                  hintStyle: TextStyle(fontSize: 13, color: c.muted),
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onConnect(isFileTransfer: _fileMode.value),
              ).workaroundFreezeLinuxMint()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 12),
          child: Text(
            translate('ID and password in one step. Press Enter to continue.'),
            style: TextStyle(fontSize: 10, color: c.muted, height: 1.4),
          ),
        ),
        Obx(() => VeraPrimaryButton(
              text: _fileMode.value
                  ? translate('Transfer file')
                  : translate('Connect'),
              onTap: () => onConnect(isFileTransfer: _fileMode.value),
            )),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildMoreMenu(context),
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  Widget _modeTab(BuildContext context, IconData icon, String label,
      bool active, VoidCallback onTap) {
    final c = VeraTheme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          decoration: BoxDecoration(
            color: active ? c.panel : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: active ? c.text : c.muted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: active ? c.text : c.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diğer bağlantı türleri (kamera, terminal, TCP tünel).
  Widget _buildMoreMenu(BuildContext context) {
    final c = VeraTheme.of(context);
    return StatefulBuilder(
      builder: (context, setState) {
        var offset = Offset(0, 0);
        return Obx(() => InkWell(
              onTapDown: (e) {
                offset = e.globalPosition;
              },
              onTap: () async {
                _menuOpen.value = true;
                final x = offset.dx;
                final y = offset.dy;
                await mod_menu
                    .showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(x, y, x, y),
                  items: [
                    ('View camera', () => onConnect(isViewCamera: true)),
                    (
                      '${translate('Terminal')} (beta)',
                      () => onConnect(isTerminal: true)
                    ),
                    // `connect` routes this through the desktop path only;
                    // the peer card gates it the same way.
                    if (isDesktop)
                      ('TCP tunneling', () => onConnect(isTcpTunneling: true)),
                  ]
                      .map((e) => MenuEntryButton<String>(
                            childBuilder: (TextStyle? style) => Text(
                              translate(e.$1),
                              style: style,
                            ),
                            proc: () => e.$2(),
                            padding: EdgeInsets.symmetric(
                                horizontal: kDesktopMenuPadding.left),
                            dismissOnClicked: true,
                          ))
                      .map((e) => e.build(
                          context,
                          const MenuConfig(
                              commonColor: CustomPopupMenuTheme.commonColor,
                              height: CustomPopupMenuTheme.height,
                              dividerHeight:
                                  CustomPopupMenuTheme.dividerHeight)))
                      .expand((i) => i)
                      .toList(),
                  elevation: 8,
                )
                    .then((_) {
                  _menuOpen.value = false;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translate('Other connection types'),
                      style: TextStyle(fontSize: 10, color: c.muted)),
                  const SizedBox(width: 4),
                  Transform.rotate(
                    angle: _menuOpen.value ? pi : 0,
                    child: Icon(IconFont.more, size: 12, color: c.muted),
                  ),
                ],
              ),
            ));
      },
    );
  }

  /// Callback for the connect button.
  /// Connects to the selected peer.
  void onConnect(
      {bool isFileTransfer = false,
      bool isViewCamera = false,
      bool isTerminal = false,
      bool isTcpTunneling = false}) {
    var id = _idController.id;
    final pwd = _pwdController.text;
    connect(context, id,
        isFileTransfer: isFileTransfer,
        isViewCamera: isViewCamera,
        isTerminal: isTerminal,
        isTcpTunneling: isTcpTunneling,
        password: pwd.isEmpty ? null : pwd);
    if (pwd.isNotEmpty) _pwdController.clear();
  }

  /// UI for the remote ID TextField.
  /// Search for a peer.
  Widget _buildRemoteIDTextField(BuildContext context) {
    final c = VeraTheme.of(context);
    return VeraInputWrap(
      icon: Icons.desktop_windows_outlined,
      focused: _idInputFocused,
      child: RawAutocomplete<Peer>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            _autocompleteOpts = const Iterable<Peer>.empty();
          } else if (_allPeersLoader.peers.isEmpty &&
              !_allPeersLoader.isPeersLoaded) {
            Peer emptyPeer = Peer(
              id: '',
              username: '',
              hostname: '',
              alias: '',
              platform: '',
              tags: [],
              hash: '',
              password: '',
              forceAlwaysRelay: false,
              rdpPort: '',
              rdpUsername: '',
              loginName: '',
              device_group_name: '',
              note: '',
            );
            _autocompleteOpts = [emptyPeer];
          } else {
            String textWithoutSpaces =
                textEditingValue.text.replaceAll(" ", "");
            if (int.tryParse(textWithoutSpaces) != null) {
              textEditingValue = TextEditingValue(
                text: textWithoutSpaces,
                selection: textEditingValue.selection,
              );
            }
            String textToFind = textEditingValue.text.toLowerCase();
            _autocompleteOpts = _allPeersLoader.peers
                .where((peer) =>
                    peer.id.toLowerCase().contains(textToFind) ||
                    peer.username.toLowerCase().contains(textToFind) ||
                    peer.hostname.toLowerCase().contains(textToFind) ||
                    peer.alias.toLowerCase().contains(textToFind))
                .toList();
            _allPeersLoader.queryOnlines(_autocompleteOpts);
          }
          return _autocompleteOpts;
        },
        focusNode: _idFocusNode,
        textEditingController: _idEditingController,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          updateTextAndPreserveSelection(
              fieldTextEditingController, _idController.text);
          return TextField(
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            focusNode: fieldFocusNode,
            style: TextStyle(
              fontFamily: VeraTheme.monoFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: c.text,
            ),
            maxLines: 1,
            cursorColor: c.accent,
            decoration: InputDecoration(
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                hintText: '000 000 000',
                hintStyle: TextStyle(
                    fontFamily: VeraTheme.monoFamily,
                    fontSize: 14,
                    color: c.muted),
                contentPadding: EdgeInsets.zero),
            controller: fieldTextEditingController,
            inputFormatters: [IDTextInputFormatter()],
            onChanged: (v) {
              _idController.id = v;
              // seçili cihaz başlığı ve topoloji güncellensin
              setState(() {});
            },
            onSubmitted: (_) {
              onConnect(isFileTransfer: _fileMode.value);
            },
          ).workaroundFreezeLinuxMint();
        },
        onSelected: (option) {
          setState(() {
            _idController.id = option.id;
            FocusScope.of(context).unfocus();
          });
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<Peer> onSelected, Iterable<Peer> options) {
          options = _autocompleteOpts;
          double maxHeight = options.length * 50;
          if (options.length == 1) {
            maxHeight = 52;
          } else if (options.length == 3) {
            maxHeight = 146;
          } else if (options.length == 4) {
            maxHeight = 193;
          }
          maxHeight = maxHeight.clamp(0, 200);

          return Align(
            alignment: Alignment.topLeft,
            child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxHeight,
                          maxWidth: VeraTheme.panelWidth - 46,
                        ),
                        child: _allPeersLoader.peers.isEmpty &&
                                !_allPeersLoader.isPeersLoaded
                            ? Container(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ))
                            : Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: ListView(
                                  children: options
                                      .map((peer) => AutocompletePeerTile(
                                          onSelect: () => onSelected(peer),
                                          peer: peer))
                                      .toList(),
                                ),
                              ),
                      ),
                    ))),
          );
        },
      ),
    );
  }
}
