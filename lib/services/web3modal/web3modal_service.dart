import 'package:flutter/material.dart';
import 'package:w_common/disposable.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3modal_flutter/services/explorer/explorer_service.dart';
import 'package:web3modal_flutter/services/explorer/i_explorer_service.dart';
import 'package:web3modal_flutter/services/web3modal/i_web3modal_service.dart';
import 'package:web3modal_flutter/utils/logger_util.dart';
import 'package:web3modal_flutter/utils/namespaces.dart';
import 'package:web3modal_flutter/utils/util.dart';
import 'package:web3modal_flutter/widgets/web3modal.dart';

class Web3ModalService extends ChangeNotifier
    with Disposable
    implements IWeb3ModalService {
  bool _isInitialized = false;
  @override
  bool get isInitialized => _isInitialized;

  String _projectId = '';
  @override
  String get projectId => _projectId;

  IWeb3App? _web3App;
  @override
  IWeb3App? get web3App => _web3App;

  bool _isOpen = false;
  @override
  bool get isOpen => _isOpen;

  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  SessionData? _session;
  @override
  SessionData? get session => _session;

  String? _address;
  @override
  String? get address => _address;

  @override
  late IExplorerService explorerService;

  Map<String, RequiredNamespace> _requiredNamespaces =
      NamespaceConstants.ethereum;
  @override
  Map<String, RequiredNamespace> get requiredNamespaces => _requiredNamespaces;

  BuildContext? context;

  /// Creates a new instance of [Web3ModalService].
  Web3ModalService({
    required IWeb3App web3App,
    IExplorerService? explorerService,
    Map<String, RequiredNamespace>? requiredNamespaces,
  }) {
    _web3App = web3App;
    _projectId = projectId;

    _registerListeners();

    if (requiredNamespaces != null) {
      _requiredNamespaces = requiredNamespaces;
    }

    if (explorerService != null) {
      this.explorerService = explorerService;
    } else {
      this.explorerService = ExplorerService(projectId: _projectId);
    }

    if (_web3App!.sessions.getAll().isNotEmpty) {
      _isConnected = true;
      _session = _web3App!.sessions.getAll().first;
      _address = NamespaceUtils.getAccount(
        _session!.namespaces.values.first.accounts.first,
      );
    }

    _isInitialized = true;

    notifyListeners();
  }

  @override
  // ignore: prefer_void_to_null
  Future<Null> onDispose() async {
    if (_isInitialized) {
      _unregisterListeners();
    }
  }

  @override
  void open({
    required BuildContext context,
    Web3ModalState? startState,
  }) {
    _checkInitialized();

    this.context = context;

    final bool bottomSheet = Util.isMobileWidth(context);

    _isOpen = true;

    if (bottomSheet) {
      showModalBottomSheet(
        // enableDrag: false,
        isDismissible: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Web3Modal(
            service: this,
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return Web3Modal(
            service: this,
          );
        },
      );
    }

    notifyListeners();
  }

  @override
  void close() {
    _isOpen = false;

    if (context != null) {
      Navigator.pop(context!);
    }

    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    _checkInitialized();

    await web3App!.disconnectSession(
      topic: session!.topic,
      reason: WalletConnectError(
        code: 0,
        message: 'User disconnected',
      ),
    );
    await web3App!.disconnectSession(
      topic: session!.pairingTopic,
      reason: WalletConnectError(
        code: 0,
        message: 'User disconnected',
      ),
    );
  }

  @override
  void setDefaultChain(String chainId) {
    _checkInitialized();

    notifyListeners();
  }

  @override
  void setRequiredNamespaces(Map<String, RequiredNamespace> namespaces) {
    _checkInitialized();
    LoggerUtil.logger.i('Setting Required namespaces: $namespaces');

    _requiredNamespaces = namespaces;

    notifyListeners();
  }

  @override
  void setRecommendedWallets(List<String> walletIds) {}

  @override
  void setExcludedWallets(List<String> walletIds) {}

  ////// Private methods //////

  void _registerListeners() {
    web3App!.onSessionConnect.subscribe(
      _onSessionConnect,
    );
    web3App!.onSessionDelete.subscribe(
      _onSessionDelete,
    );
  }

  void _unregisterListeners() {
    web3App!.onSessionConnect.unsubscribe(
      _onSessionConnect,
    );
    web3App!.onSessionDelete.unsubscribe(
      _onSessionDelete,
    );
  }

  void _onSessionConnect(SessionConnect? args) {
    LoggerUtil.logger.i('Session connected: $args');
    _isConnected = true;
    _session = args!.session;
    _address = NamespaceUtils.getAccount(
      _session!.namespaces.values.first.accounts.first,
    );

    if (_isOpen) {
      close();
    } else {
      notifyListeners();
    }
  }

  void _onSessionDelete(SessionDelete? args) {
    _isConnected = false;
    _address = '';

    notifyListeners();
  }

  void _checkInitialized() {
    if (!isInitialized) {
      throw Exception(
        'Web3ModalService must be initialized before calling this method.',
      );
    }
  }
}