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

import 'package:badges/badges.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/package_service.dart';
import 'package:software/services/snap_service.dart';
import 'package:software/store_app/common/animated_warning_icon.dart';
import 'package:software/store_app/common/dangerous_delayed_button.dart';
import 'package:software/store_app/explore/explore_page.dart';
import 'package:software/store_app/my_apps/my_apps_page.dart';
import 'package:software/store_app/settings/settings_page.dart';
import 'package:software/store_app/store_model.dart';
import 'package:software/store_app/updates/updates_page.dart';
import 'package:software/updates_state.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru/yaru.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  static Widget create() => ChangeNotifierProvider(
        create: (context) => StoreModel(
          getService<Connectivity>(),
          getService<SnapService>(),
          getService<PackageService>(),
        ),
        child: const StoreApp(),
      );

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          debugShowCheckedModeBanner: false,
          title: 'Ubuntu Software App',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedLocales,
          onGenerateTitle: (context) => context.l10n.appTitle,
          routes: {
            Navigator.defaultRouteName: (context) {
              return const Scaffold(
                body: _App(),
              );
            },
          },
        );
      },
    );
  }
}

class PageItem {
  const PageItem({
    required this.titleBuilder,
    required this.builder,
    required this.iconBuilder,
  });

  final WidgetBuilder titleBuilder;
  final WidgetBuilder builder;
  final Widget Function(BuildContext context, bool selected) iconBuilder;
}

class _App extends StatefulWidget {
  // ignore: unused_element
  const _App({super.key});

  @override
  State<_App> createState() => __AppState();
}

class __AppState extends State<_App> {
  int _myAppsIndex = 0;

  @override
  void initState() {
    super.initState();

    final model = context.read<StoreModel>();
    var closeConfirmDialogOpen = false;

    model.init(
      onAskForQuit: () {
        if (closeConfirmDialogOpen) {
          return;
        }

        closeConfirmDialogOpen = true;
        showDialog(
          context: context,
          builder: (c) {
            return _CloseWindowConfirmDialog(
              onConfirm: () {
                model.quit();
              },
            );
          },
        ).then((value) => closeConfirmDialogOpen = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<StoreModel>();
    model.setupNotifications(updatesAvailable: context.l10n.updateAvailable);
    final width = MediaQuery.of(context).size.width;

    final pageItems = [
      PageItem(
        titleBuilder: ExplorePage.createTitle,
        builder: (context) => ExplorePage.create(context, model.appIsOnline),
        iconBuilder: (context, selected) => selected
            ? const Icon(YaruIcons.compass_filled)
            : const Icon(YaruIcons.compass),
      ),
      PageItem(
        titleBuilder: MyAppsPage.createTitle,
        builder: (context) => MyAppsPage.create(
          context,
          (index) => _myAppsIndex = index,
          _myAppsIndex,
        ),
        iconBuilder: (context, selected) {
          if (model.snapChanges.isNotEmpty) {
            return _MyAppsIcon(count: model.snapChanges.length);
          }
          return selected
              ? const Icon(YaruIcons.ok_filled)
              : const Icon(YaruIcons.ok);
        },
      ),
      PageItem(
        titleBuilder: UpdatesPage.createTitle,
        builder: UpdatesPage.create,
        iconBuilder: (context, selected) {
          return _UpdatesIcon(
            count: model.updateAmount,
            updatesState: model.updatesState ?? UpdatesState.checkingForUpdates,
          );
        },
      ),
      PageItem(
        titleBuilder: SettingsPage.createTitle,
        builder: SettingsPage.create,
        iconBuilder: (context, selected) => selected
            ? const Icon(YaruIcons.settings_filled)
            : const Icon(YaruIcons.settings),
      ),
    ];

    return YaruCompactLayout(
      length: pageItems.length,
      itemBuilder: (context, index, selected) => YaruNavigationRailItem(
        icon: pageItems[index].iconBuilder(context, selected),
        label: pageItems[index].titleBuilder(context),
        // tooltip: pageItems[index].tooltipMessage,
        style: width > 800 && width < 1200
            ? YaruNavigationRailStyle.labelled
            : width > 1200
                ? YaruNavigationRailStyle.labelledExtended
                : YaruNavigationRailStyle.compact,
      ),
      pageBuilder: (context, index) => pageItems[index].builder(context),
    );
  }
}

class _MyAppsIcon extends StatelessWidget {
  // ignore: unused_element
  const _MyAppsIcon({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      badgeColor: Theme.of(context).primaryColor,
      badgeContent: Text(
        count.toString(),
        style: badgeTextStyle,
      ),
      child: const SizedBox(
        height: 20,
        child: YaruCircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _UpdatesIcon extends StatelessWidget {
  const _UpdatesIcon({
    // ignore: unused_element
    super.key,
    required this.count,
    required this.updatesState,
  });

  final int count;
  final UpdatesState updatesState;

  @override
  Widget build(BuildContext context) {
    if (updatesState == UpdatesState.checkingForUpdates) {
      return Badge(
        position: BadgePosition.topEnd(),
        badgeColor:
            count > 0 ? Theme.of(context).primaryColor : Colors.transparent,
        badgeContent: count > 0
            ? Text(
                count.toString(),
                style: badgeTextStyle,
              )
            : null,
        child: const SizedBox(
          height: 24,
          width: 23,
          child: YaruCircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    } else if (updatesState == UpdatesState.updating) {
      return const SizedBox(
        height: 20,
        child: YaruCircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    } else if (updatesState == UpdatesState.readyToUpdate) {
      return Badge(
        badgeColor: Theme.of(context).primaryColor,
        badgeContent: Text(
          count.toString(),
          style: badgeTextStyle,
        ),
        child: const Icon(YaruIcons.synchronizing),
      );
    }
    return const Icon(YaruIcons.synchronizing);
  }
}

const badgeTextStyle = TextStyle(color: Colors.white, fontSize: 10);

class _CloseWindowConfirmDialog extends StatelessWidget {
  const _CloseWindowConfirmDialog({
    Key? key,
    this.onConfirm,
  }) : super(key: key);

  final Function()? onConfirm;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const YaruCloseButton(
        alignement: Alignment.centerRight,
      ),
      titlePadding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
      contentPadding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            width: 500,
            child: Column(
              children: [
                const AnimatedWarningIcon(),
                Text(
                  context.l10n.attention,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 24.0),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    context.l10n.quitDanger,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DangerousDelayedButton(
                  duration: const Duration(seconds: 3),
                  onPressed: onConfirm,
                  child: Text(
                    context.l10n.quit,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n.cancel,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
