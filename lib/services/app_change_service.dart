import 'dart:async';

import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:snapd/snapd.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

class AppChangeService {
  final Map<Snap, SnapdChange> _snapChanges;
  Map<Snap, SnapdChange> get snapChanges => _snapChanges;
  final SnapdClient _snapDClient;
  final NotificationsClient _notificationsClient;

  Future<void> addChange(Snap snap, String id, String doneString) async {
    final newChange = await _snapDClient.getChange(id);
    _snapChanges.putIfAbsent(snap, () => newChange);
    if (!_snapChangesController.isClosed) {
      _snapChangesController.add(true);
    }
    while (true) {
      final newChange = await _snapDClient.getChange(id);
      if (newChange.ready) {
        removeChange(snap);
        _notificationsClient.notify(
          'Software',
          body: '$doneString: ${newChange.summary}',
          appName: snap.name,
          appIcon: 'snap-store',
          hints: [
            NotificationHint.desktopEntry('software'),
            NotificationHint.urgency(NotificationUrgency.normal)
          ],
        );
        break;
      }
      await Future.delayed(
        const Duration(milliseconds: 100),
      );
    }
  }

  void removeChange(Snap snap) {
    _snapChanges.remove(snap);
    if (!_snapChangesController.isClosed) {
      _snapChangesController.add(true);
    }
  }

  SnapdChange? getChange(Snap snap) {
    return _snapChanges[snap];
  }

  final _snapChangesController = StreamController<bool>.broadcast();

  Stream<bool> get snapChangesInserted => _snapChangesController.stream;

  AppChangeService()
      : _snapChanges = {},
        _snapDClient = getService<SnapdClient>(),
        _notificationsClient = getService<NotificationsClient>();
}
