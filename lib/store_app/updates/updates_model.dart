import 'dart:async';
import 'dart:io';

import 'package:packagekit/packagekit.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';

class UpdatesModel extends SafeChangeNotifier {
  final PackageKitClient _client;

  final Map<PackageKitPackageId, bool> updates = {};
  final Map<String, PackageKitPackageId> installedPackages = {};
  bool requireRestart;

  int? _percentage;
  int? get percentage => _percentage;
  set percentage(int? value) {
    if (value == _percentage) return;
    _percentage = value;
    notifyListeners();
  }

  PackageKitPackageId? _processedId;
  PackageKitPackageId? get processedId => _processedId;
  set processedId(PackageKitPackageId? value) {
    if (value == _processedId) return;
    _processedId = value;
    notifyListeners();
  }

  void selectAll() {
    for (final entry in updates.entries) {
      updates[entry.key] = true;
      notifyListeners();
    }
  }

  void deselectAll() {
    for (final entry in updates.entries) {
      updates[entry.key] = false;
      notifyListeners();
    }
  }

  bool get allSelected =>
      updates.entries.where((e) => e.value).length == updates.length;

  void selectUpdate(PackageKitPackageId id, bool value) {
    updates[id] = value;
    notifyListeners();
  }

  String _errorString = '';
  String get errorString => _errorString;
  set errorString(String value) {
    if (value == _errorString) return;
    _errorString = value;
    notifyListeners();
  }

  bool _processing = true;
  bool get processing => _processing;
  set processing(bool value) {
    if (value == _processing) return;
    _processing = value;
    notifyListeners();
  }

  String _manualRepoName = '';
  set manualRepoName(String value) {
    if (value == _manualRepoName) return;
    _manualRepoName = value;
    notifyListeners();
  }

  UpdatesModel(this._client) : requireRestart = false {
    _client.connect();
  }

  void init() async {
    await _getInstalledPackages();
    await _getUpdates();
    await _loadRepoList();
    notifyListeners();
  }

  Future<void> refresh() async {
    processing = true;
    errorString = '';
    final transaction = await _client.createTransaction();
    final completer = Completer();
    transaction.events.listen((event) {
      if (event is PackageKitRepositoryDetailEvent) {
        // print(event.description);
      } else if (event is PackageKitErrorCodeEvent) {
        errorString = '${event.code}: ${event.details}';
      } else if (event is PackageKitFinishedEvent) {
        completer.complete();
      }
    });
    await transaction.refreshCache();
    await completer.future;
    await _getUpdates();
    notifyListeners();
  }

  Future<void> _getUpdates() async {
    processing = true;
    updates.clear();
    errorString = '';
    final transaction = await _client.createTransaction();
    final completer = Completer();
    transaction.events.listen((event) {
      if (event is PackageKitPackageEvent) {
        final id = event.packageId;
        updates.putIfAbsent(id, () => true);
      } else if (event is PackageKitErrorCodeEvent) {
        errorString = '${event.code}: ${event.details}';
      } else if (event is PackageKitFinishedEvent) {
        completer.complete();
        processing = false;
      }
    });
    await transaction.getUpdates();
    await completer.future;
  }

  Future<void> updateAll() async {
    errorString = '';
    final List<PackageKitPackageId> selectedUpdates = updates.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
    if (selectedUpdates.isEmpty) return;
    final updatePackagesTransaction = await _client.createTransaction();
    final updatePackagesCompleter = Completer();
    processing = true;
    updatePackagesTransaction.events.listen((event) {
      requireRestart = event is PackageKitRequireRestartEvent;
      if (event is PackageKitPackageEvent) {
        processedId = event.packageId;
      } else if (event is PackageKitItemProgressEvent) {
        percentage = event.percentage;
      } else if (event is PackageKitErrorCodeEvent) {
        errorString = '${event.code}: ${event.details}';
      } else if (event is PackageKitFinishedEvent) {
        updatePackagesCompleter.complete();
        processing = false;
      }
    });
    await updatePackagesTransaction.updatePackages(selectedUpdates);
    await updatePackagesCompleter.future;
    await _getUpdates();
    notifyListeners();
  }

  final List<PackageKitRepositoryDetailEvent> repos = [];
  Future<void> _loadRepoList() async {
    errorString = '';
    repos.clear();
    final transaction = await _client.createTransaction();
    final completer = Completer();
    transaction.events.listen((event) {
      if (event is PackageKitRepositoryDetailEvent) {
        repos.add(event);
      } else if (event is PackageKitErrorCodeEvent) {
        errorString = '${event.code}: ${event.details}';
      } else if (event is PackageKitFinishedEvent) {
        completer.complete();
      }
    });
    await transaction.getRepositoryList();
    await completer.future;
    notifyListeners();
  }

  Future<void> toggleRepo({required String id, required bool value}) async {
    final transaction = await _client.createTransaction();
    final completer = Completer();
    transaction.events.listen((event) {
      if (event is PackageKitFinishedEvent) {
        completer.complete();
      }
    });
    await transaction.setRepositoryEnabled(id, value);
    await completer.future;
    _loadRepoList();
  }

  // Not implemented in packagekit.dart
  Future<void> addRepo() async {
    if (_manualRepoName.isEmpty) return;
    Process.start(
      'pkexec',
      [
        'apt-add-repository',
        _manualRepoName,
      ],
      mode: ProcessStartMode.detached,
    );
    _loadRepoList();
  }

  // Not implemented in packagekit.dart and too hard for apt-add-repository
  Future<void> removeRepo(String id) async {}

  void reboot() {
    Process.start(
      'reboot',
      [],
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _getInstalledPackages() async {
    errorString = '';
    final transaction = await _client.createTransaction();
    final completer = Completer();
    transaction.events.listen((event) {
      if (event is PackageKitPackageEvent) {
        installedPackages.putIfAbsent(
          event.packageId.name,
          () => event.packageId,
        );
      } else if (event is PackageKitErrorCodeEvent) {
        errorString = '${event.code}: ${event.details}';
      } else if (event is PackageKitFinishedEvent) {
        completer.complete();
      }
    });
    await transaction.getPackages(
      filter: {PackageKitFilter.installed},
    );
    await completer.future;
  }
}
