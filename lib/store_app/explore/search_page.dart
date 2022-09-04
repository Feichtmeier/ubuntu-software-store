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
import 'package:packagekit/packagekit.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/snapx.dart';
import 'package:software/store_app/common/animated_scroll_view_item.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/common/snap_dialog.dart';
import 'package:software/store_app/explore/explore_model.dart';
import 'package:software/store_app/common/package_dialog.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTabbedPage(
      tabIcons: const [YaruIcons.package_snap, YaruIcons.package_deb],
      tabTitles: [
        context.l10n.snapPackages,
        context.l10n.debianPackages,
      ],
      views: const [
        _SnapSearchPage(),
        _PackageKitSearchPage(),
      ],
    );
  }
}

class _SnapSearchPage extends StatelessWidget {
  // ignore: unused_element
  const _SnapSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FutureBuilder<List<Snap>>(
        future: model.findSnapsByQuery(),
        builder: (context, snapshot) =>
            snapshot.hasData && snapshot.data!.isNotEmpty
                ? GridView.builder(
                    controller: ScrollController(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: kGridDelegate,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final snap = snapshot.data![index];
                      return AnimatedScrollViewItem(
                        child: YaruBanner(
                          name: snap.name,
                          summary: snap.summary,
                          url: snap.iconUrl,
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => SnapDialog.create(
                              context: context,
                              huskSnapName: snap.name,
                            ),
                          ),
                          fallbackIconData: YaruIcons.package_snap,
                        ),
                      );
                    },
                  )
                : const SizedBox(),
      ),
    );
  }
}

class _PackageKitSearchPage extends StatelessWidget {
  // ignore: unused_element
  const _PackageKitSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FutureBuilder<List<PackageKitPackageId>>(
        future: model.findPackageKitPackageIds(
          filter: {PackageKitFilter.newest, PackageKitFilter.notDevelopment},
        ),
        builder: (context, snapshot) =>
            snapshot.hasData && snapshot.data!.isNotEmpty
                ? GridView.builder(
                    controller: ScrollController(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: kGridDelegate,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final id = snapshot.data![index];
                      return YaruBanner(
                        name: id.name,
                        summary: id.version,
                        icon: const Icon(
                          YaruIcons.package_deb,
                          size: 50,
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => PackageDialog.create(
                            context: context,
                            id: id,
                            installedId: id,
                          ),
                        ),
                        fallbackIconData: YaruIcons.package_deb,
                      );
                    },
                  )
                : const SizedBox(),
      ),
    );
  }
}
