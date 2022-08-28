import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:provider/provider.dart';
import 'package:software/package_installer/package_installer_model.dart';
import 'package:software/package_installer/wizard_page.dart';
import 'package:software/package_state.dart';
import 'package:yaru/yaru.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class PackageInstallerApp extends StatelessWidget {
  const PackageInstallerApp({Key? key, required this.path}) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          theme: yaru.variant?.theme ?? yaruLight,
          darkTheme: yaru.variant?.darkTheme ?? yaruDark,
          debugShowCheckedModeBanner: false,
          // supportedLocales: AppLocalizations.supportedLocales,
          // onGenerateTitle: (context) => context.l10n.appTitle,
          routes: {
            Navigator.defaultRouteName: (context) =>
                _PackageInstallerPage.create(path)
          },
        );
      },
    );
  }
}

class _PackageInstallerPage extends StatefulWidget {
  // ignore: unused_element
  const _PackageInstallerPage({super.key});

  static Widget create(String path) {
    return ChangeNotifierProvider(
      create: (context) => PackageInstallerModel(path: path),
      child: const _PackageInstallerPage(),
    );
  }

  @override
  State<_PackageInstallerPage> createState() => _PackageInstallerPageState();
}

class _PackageInstallerPageState extends State<_PackageInstallerPage> {
  @override
  void initState() {
    super.initState();
    context.read<PackageInstallerModel>().init();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PackageInstallerModel>();

    return WizardPage(
      title: const Text('Package installer'),
      actions: [
        model.isInstalled
            ? ElevatedButton(
                onPressed: model.id == null ||
                        model.id!.name.isEmpty ||
                        model.packageState == PackageState.processing
                    ? null
                    : () => model.remove(packageId: model.id!),
                child: const Text('Remove'),
              )
            : ElevatedButton(
                onPressed: model.id == null ||
                        model.id!.name.isEmpty ||
                        model.packageState != PackageState.ready
                    ? null
                    : () => model.installLocalFile(),
                child: const Text('Install'),
              ),
      ],
      content: Center(
        child: SingleChildScrollView(
          child: Row(
            children: [
              const SizedBox(
                width: 8,
              ),
              YaruSection(
                width: MediaQuery.of(context).size.width / 2,
                children: [
                  YaruSingleInfoRow(
                    infoLabel: 'Name',
                    infoValue: model.id == null ? '' : model.id!.name,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'Version',
                    infoValue: model.id == null ? '' : model.id!.version,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'Arch',
                    infoValue: model.id == null ? '' : model.id!.arch,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'Data',
                    infoValue: model.id == null ? '' : model.id!.data,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'License',
                    infoValue: model.license,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'Size',
                    infoValue: model.size.toString(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  YaruSingleInfoRow(
                    infoLabel: 'Description',
                    infoValue: model.description.toString(),
                  ),
                ],
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 145,
                      height: 185,
                      child: LiquidLinearProgressIndicator(
                        value: model.percentage == null
                            ? 0
                            : model.percentage! / 100,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor,
                        ),
                        direction: Axis.vertical,
                        borderRadius: 20,
                      ),
                    ),
                    Icon(
                      YaruIcons.debian,
                      size: 120,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
