import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapd/snapd.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

import '/snapd.dart';
import 'logger.dart';

final updatesModelProvider = ChangeNotifierProvider(
  (ref) => UpdatesModel(getService<SnapdService>())..refresh(),
);

class UpdatesModel extends ChangeNotifier {
  UpdatesModel(this.snapd) : _state = const AsyncValue.loading();
  final SnapdService snapd;
  Iterable<String> get refreshableSnapNames =>
      _refreshableSnaps?.map((snap) => snap.name) ?? const Iterable.empty();

  Iterable<Snap>? _refreshableSnaps;

  String? get activeChangeId => _activeChangeId;
  String? _activeChangeId;

  AsyncValue<void> get state => _state;
  AsyncValue<void> _state;

  Stream<SnapdException> get errorStream => _errorStreamController.stream;
  final StreamController<SnapdException> _errorStreamController =
      StreamController.broadcast();

  void _handleError(SnapdException e) {
    _errorStreamController.add(e);
    log.error(
        'Caught exception when handling updates for $refreshableSnapNames', e);
  }

  Future<void> refresh() async {
    _state = const AsyncValue.loading();
    notifyListeners();
    _state = await AsyncValue.guard(() async {
      try {
        _refreshableSnaps = await snapd.find(filter: SnapFindFilter.refresh);
        notifyListeners();
      } on SnapdException catch (e) {
        _handleError(e);
      }
    });
  }

  bool hasUpdate(String snapName) => refreshableSnapNames.contains(snapName);

  Future<void> updateAll() async {
    if (_refreshableSnaps == null) return;
    try {
      final changeId = await snapd.refreshMany(refreshableSnapNames.toList());
      _activeChangeId = changeId;
      notifyListeners();
      await snapd.waitChange(changeId);
    } on SnapdException catch (e) {
      _handleError(e);
    }
    _activeChangeId = null;
    await refresh();
  }
}
