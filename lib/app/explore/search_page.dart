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
import 'package:software/app/common/app_banner.dart';
import 'package:software/app/common/app_finding.dart';
import 'package:software/app/common/app_format.dart';
import 'package:software/app/common/constants.dart';
import 'package:software/app/common/loading_banner_grid.dart';
import 'package:software/app/explore/explore_header.dart';
import 'package:software/app/explore/explore_model.dart';
import 'package:software/l10n/l10n.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final search = context.select((ExploreModel m) => m.search);
    final showSnap = context.select(
      (ExploreModel m) => m.selectedAppFormats.contains(AppFormat.snap),
    );
    final showPackageKit = context.select(
      (ExploreModel m) => m.selectedAppFormats.contains(AppFormat.packageKit),
    );
    final selectedAppFormats =
        context.select((ExploreModel m) => m.selectedAppFormats);
    final enabledAppFormats =
        context.select((ExploreModel m) => m.enabledAppFormats);
    final selectedSection =
        context.select((ExploreModel m) => m.selectedSection);
    final setSelectedSection =
        context.select((ExploreModel m) => m.setSelectedSection);
    final handleAppFormat =
        context.select((ExploreModel m) => m.handleAppFormat);

    context.select((ExploreModel m) => m.selectedSection);
    context.select((ExploreModel m) => m.searchQuery);

    return FutureBuilder<Map<String, AppFinding>>(
      future: search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              LoadingExploreHeader(),
              Expanded(child: LoadingBannerGrid()),
            ],
          );
        }

        return Column(
          children: [
            ExploreHeader(
              selectedSection: selectedSection,
              enabledAppFormats: enabledAppFormats,
              selectedAppFormats: selectedAppFormats,
              handleAppFormat: handleAppFormat,
              setSelectedSection: setSelectedSection,
            ),
            snapshot.hasData && snapshot.data!.isNotEmpty
                ? Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 15,
                        right: 15,
                        left: 15,
                      ),
                      gridDelegate: kGridDelegate,
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final appFinding =
                            snapshot.data!.entries.elementAt(index);
                        return AppBanner(
                          appFinding: appFinding,
                          showSnap: showSnap,
                          showPackageKit: showPackageKit,
                        );
                      },
                    ),
                  )
                : _NoSearchResultPage(message: context.l10n.noPackageFound),
          ],
        );
      },
    );
  }
}

class _NoSearchResultPage extends StatelessWidget {
  const _NoSearchResultPage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐣❓',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 400,
            child: Text(
              message,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 25),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 200,
          ),
        ],
      ),
    );
  }
}
