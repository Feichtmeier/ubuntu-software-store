import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/pages/common/apps_model.dart';
import 'package:software/pages/common/snap_model.dart';
import 'package:software/pages/common/snap_tile.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SnapUpdatesPage extends StatefulWidget {
  const SnapUpdatesPage({Key? key}) : super(key: key);

  @override
  State<SnapUpdatesPage> createState() => _SnapUpdatesPageState();

  static Widget create(BuildContext context) {
    final client = getService<SnapdClient>();
    final connectivity = getService<Connectivity>();
    return ChangeNotifierProvider(
      create: (_) => AppsModel(client, connectivity),
      child: const SnapUpdatesPage(),
    );
  }

  static Widget createTitle(BuildContext context) =>
      Text(context.l10n.updatesPageTitle);
}

class _SnapUpdatesPageState extends State<SnapUpdatesPage> {
  @override
  void initState() {
    super.initState();
    final appsModel = context.read<AppsModel>();
    appsModel.initConnectivity();
    appsModel.checkUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final appsModel = context.watch<AppsModel>();

    if (!appsModel.appIsOnline) {
      return const Center(
        child: YaruCircularProgressIndicator(),
      );
    } else {
      return Center(
        child: appsModel.updatesMap.isEmpty
            ? const YaruCircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: appsModel.updatesMap.length,
                  itemBuilder: (context, index) {
                    final huskSnapName = appsModel.updatesMap.entries
                        .elementAt(index)
                        .value
                        .name;
                    return ChangeNotifierProvider(
                      create: (context) => SnapModel(
                        client: getService<SnapdClient>(),
                        huskSnapName: huskSnapName,
                      ),
                      child: SnapTile(
                        appIsOnline: appsModel.appIsOnline,
                        snapApp:
                            appsModel.updatesMap.entries.elementAt(index).key,
                      ),
                    );
                  },
                ),
              ),
      );
    }
  }
}
