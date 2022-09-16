/*
 * Copyright (C) 2022 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/app_change_service.dart';
import 'package:software/store_app/common/app_content.dart';
import 'package:software/store_app/common/app_header.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/common/snap_channel_expandable.dart';
import 'package:software/store_app/common/snap_connections_settings.dart';
import 'package:software/store_app/common/snap_installation_controls.dart';
import 'package:software/store_app/common/snap_model.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SnapDialog extends StatefulWidget {
  const SnapDialog({
    Key? key,
  }) : super(key: key);

  static Widget create({
    required BuildContext context,
    required String huskSnapName,
  }) =>
      ChangeNotifierProvider<SnapModel>(
        create: (_) => SnapModel(
          doneString: context.l10n.done,
          getService<SnapdClient>(),
          getService<AppChangeService>(),
          huskSnapName: huskSnapName,
        ),
        child: const SnapDialog(),
      );

  @override
  State<SnapDialog> createState() => _SnapDialogState();
}

class _SnapDialogState extends State<SnapDialog> {
  @override
  void initState() {
    context.read<SnapModel>().init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SnapModel>();
    if (model.name != null) {
      return AlertDialog(
        scrollable: false,
        actionsAlignment: MainAxisAlignment.spaceBetween,
        contentPadding: const EdgeInsets.only(
          left: 25,
          right: 25,
        ),
        titlePadding: EdgeInsets.zero,
        title: SizedBox(
          width: dialogWidth,
          child: YaruDialogTitle(
            mainAxisAlignment: MainAxisAlignment.center,
            closeIconData: YaruIcons.window_close,
            titleWidget: AppHeader(
              confinementName:
                  model.confinement != null ? model.confinement!.name : '',
              icon: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: model.installDate.isNotEmpty ? model.open : null,
                child: YaruSafeImage(
                  url: model.iconUrl,
                  fallBackIconData: YaruIcons.package_snap,
                ),
              ),
              installDate: model.installDate,
              installDateIsoNorm: model.installDateIsoNorm,
              license: model.license ?? '',
              strict: model.strict,
              verified: model.verified,
              publisherName: model.publisher?.displayName ?? '',
              website: model.storeUrl ?? '',
              summary: model.summary ?? '',
              title: model.title ?? '',
              version: model.version,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: dialogWidth,
            child: AppContent(
              contact: model.contact ?? '',
              description: model.description ?? '',
              publisherName: model.publisher?.displayName ?? '',
              website: model.website ?? '',
              media: model.screenshotUrls ?? [],
              lastChild: model.strict && model.connections.isNotEmpty
                  ? SnapConnectionsSettings(connections: model.connections)
                  : null,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            child: SizedBox(
              child: SnapChannelExpandable(
                onChanged: model.appChangeInProgress
                    ? null
                    : (v) => model.channelToBeInstalled = v!,
                channelToBeInstalled: model.channelToBeInstalled,
                onInit: () => model.init(),
                releasedAt: model.releasedAt,
                releaseAtIsoNorm: model.releaseAtIsoNorm,
                selectableChannelsIsEmpty: model.selectableChannels.isEmpty,
                selectedChannelVersion: model.selectedChannelVersion ?? '',
                selectableChannels:
                    model.selectableChannels.entries.map((e) => e.key).toList(),
              ),
            ),
          ),
          if (model.appChangeInProgress)
            const SizedBox(
              height: 25,
              child: YaruCircularProgressIndicator(
                strokeWidth: 3,
              ),
            )
          else
            SnapInstallationControls(
              appChangeInProgress: model.appChangeInProgress,
              appIsInstalled: model.snapIsInstalled,
              install: model.installSnap,
              refresh: model.refreshSnapApp,
              remove: model.removeSnap,
              open: model.isSnapEnv ? null : model.open,
            )
        ],
      );
    } else {
      return const AlertDialog(
        content: SizedBox(
          height: 200,
          child: Center(child: YaruCircularProgressIndicator()),
        ),
      );
    }
  }
}
