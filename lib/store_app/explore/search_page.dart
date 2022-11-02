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
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:packagekit/packagekit.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/snapx.dart';
import 'package:software/store_app/common/animated_scroll_view_item.dart';
import 'package:software/store_app/common/app_format.dart';
import 'package:software/store_app/common/app_icon.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/common/packagekit/package_page.dart';
import 'package:software/store_app/common/snap/snap_page.dart';
import 'package:software/store_app/explore/explore_model.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    if (model.appFormats.contains(AppFormat.snap) &&
        model.appFormats.contains(AppFormat.packageKit)) {
      return const _CombinedSearchPage();
    } else if (model.appFormats.contains(AppFormat.snap) &&
        !model.appFormats.contains(AppFormat.packageKit)) {
      return const _SnapSearchPage();
    } else if (model.appFormats.contains(AppFormat.packageKit) &&
        !model.appFormats.contains(AppFormat.snap)) {
      return const _PackageKitSearchPage();
    }

    return const SizedBox();
  }
}

class _SnapSearchPage extends StatelessWidget {
  // ignore: unused_element
  const _SnapSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    return FutureBuilder<List<Snap>>(
      future: model.findSnapsByQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WaitPage(message: '');
        }

        return snapshot.hasData && snapshot.data!.isNotEmpty
            ? GridView.builder(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                gridDelegate: kGridDelegate,
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final snap = snapshot.data![index];
                  return AnimatedScrollViewItem(
                    child: YaruBanner(
                      title: Text(snap.name),
                      subtitle: Text(
                        snap.summary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: AppIcon(
                        iconUrl: snap.iconUrl,
                        fallBackIconData: YaruIcons.snapcraft,
                        size: 50,
                        fallBackIconSize: 30,
                      ),
                      iconPadding: const EdgeInsets.only(left: 10, right: 5),
                      onTap: () => SnapPage.push(context, snap),
                    ),
                  );
                },
              )
            : _NoSearchResultPage(message: context.l10n.noSnapFound);
      },
    );
  }
}

class _PackageKitSearchPage extends StatefulWidget {
  // ignore: unused_element
  const _PackageKitSearchPage({super.key});

  @override
  State<_PackageKitSearchPage> createState() => _PackageKitSearchPageState();
}

class _PackageKitSearchPageState extends State<_PackageKitSearchPage> {
  @override
  void initState() {
    context.read<ExploreModel>().init();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    if (!model.packageKitReady) {
      return _WaitPage(
        message: model.updatesState != null
            ? model.updatesState!.localize(context.l10n)
            : '',
      );
    }

    return FutureBuilder<List<PackageKitPackageId>>(
      future: model.findPackageKitPackageIds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WaitPage(message: '');
        }
        return snapshot.hasData && snapshot.data!.isNotEmpty
            ? GridView.builder(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                gridDelegate: kGridDelegate,
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final id = snapshot.data![index];
                  return YaruBanner(
                    title: Text(id.name),
                    subtitle: Text(id.version),
                    icon: const AppIcon(
                      iconUrl: null,
                      fallBackIconData: YaruIcons.debian,
                    ),
                    iconPadding: const EdgeInsets.only(left: 10, right: 5),
                    onTap: () => PackagePage.push(context, id),
                  );
                },
              )
            : _NoSearchResultPage(message: context.l10n.noPackageFound);
      },
    );
  }
}

class _WaitPage extends StatelessWidget {
  const _WaitPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const YaruCircularProgressIndicator(),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 400,
            child: Text(
              message,
              style:
                  Theme.of(context).textTheme.headline4?.copyWith(fontSize: 25),
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

class _NoSearchResultPage extends StatelessWidget {
  const _NoSearchResultPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
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
              style:
                  Theme.of(context).textTheme.headline4?.copyWith(fontSize: 25),
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

class _CombinedSearchPage extends StatelessWidget {
  // ignore: unused_element
  const _CombinedSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    return FutureBuilder<Map<String, AppFinding>>(
      future: model.search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WaitPage(message: '');
        }

        return snapshot.hasData && snapshot.data!.isNotEmpty
            ? GridView.builder(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                gridDelegate: kGridDelegate,
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final e = snapshot.data!.entries.elementAt(index);
                  return YaruBanner(
                    title: Text(
                      e.key,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      e.value.snap?.summary ?? e.value.packageId?.version ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                    thirdTitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingBar.builder(
                            initialRating: e.value.rating ?? 0,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemPadding: EdgeInsets.zero,
                            itemSize: 20,
                            itemBuilder: (context, _) => Icon(
                              YaruIcons.star_filled,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                            onRatingUpdate: (rating) {},
                            ignoreGestures: true,
                          ),
                          _PackageIndicator(appFinding: e.value),
                        ],
                      ),
                    ),
                    icon: AppIcon(
                      iconUrl: e.value.snap?.iconUrl,
                      fallBackIconData: YaruIcons.view_more,
                    ),
                    iconPadding:
                        const EdgeInsets.only(left: 10, right: 5, bottom: 30),
                    onTap: e.value.snap != null && e.value.packageId != null
                        ? () => showDialog(
                              context: context,
                              builder: (context) => _AppFormatSelectDialog(
                                title: e.value.snap!.title!,
                                onPackageSelect: () => PackagePage.push(
                                  context,
                                  e.value.packageId!,
                                ),
                                onSnapSelect: () =>
                                    SnapPage.push(context, e.value.snap!),
                              ),
                            )
                        : () {
                            if (e.value.snap == null &&
                                e.value.packageId != null) {
                              PackagePage.push(context, e.value.packageId!);
                            }

                            if (e.value.snap != null &&
                                e.value.packageId == null) {
                              SnapPage.push(context, e.value.snap!);
                            }
                          },
                  );
                },
              )
            : _NoSearchResultPage(message: context.l10n.noPackageFound);
      },
    );
  }
}

class _PackageIndicator extends StatelessWidget {
  // ignore: unused_element
  const _PackageIndicator({super.key, required this.appFinding});

  final AppFinding appFinding;

  @override
  Widget build(BuildContext context) {
    final appFormatEmblemColor = Theme.of(context).disabledColor;
    return Row(
      children: [
        if (appFinding.snap != null)
          Icon(
            YaruIcons.snapcraft,
            color: appFormatEmblemColor,
            size: 20,
          ),
        if (appFinding.packageId != null)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Icon(
              YaruIcons.debian,
              color: appFormatEmblemColor,
              size: 20,
            ),
          )
      ],
    );
  }
}

class _AppFormatSelectDialog extends StatelessWidget {
  // ignore: unused_element
  const _AppFormatSelectDialog({
    // ignore: unused_element
    super.key,
    required this.title,
    required this.onSnapSelect,
    required this.onPackageSelect,
  });

  final String title;
  final Function() onSnapSelect;
  final Function() onPackageSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: YaruTitleBar(title: Text(title)),
      titlePadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onPackageSelect,
                child: Text(
                  AppFormat.packageKit.localize(context.l10n),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: onSnapSelect,
                child: Text(
                  AppFormat.snap.localize(context.l10n),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}
