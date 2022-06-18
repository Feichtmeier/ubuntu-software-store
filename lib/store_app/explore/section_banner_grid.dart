import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software/snapx.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/common/snap_dialog.dart';
import 'package:software/store_app/common/snap_section.dart';
import 'package:software/store_app/explore/explore_model.dart';
import 'package:software/store_app/common/app_banner.dart';

class SectionBannerGrid extends StatefulWidget {
  const SectionBannerGrid({
    Key? key,
    required this.snapSection,
    this.amount = 20,
  }) : super(key: key);

  final SnapSection snapSection;
  final int amount;

  @override
  State<SectionBannerGrid> createState() => _SectionBannerGridState();
}

class _SectionBannerGridState extends State<SectionBannerGrid> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ExploreModel>().loadSection(widget.snapSection.title);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    final sections = model.sectionNameToSnapsMap[widget.snapSection.title];

    return GridView(
      controller: _controller,
      shrinkWrap: true,
      gridDelegate: kGridDelegate,
      children: sections != null && sections.isNotEmpty
          ? sections.take(widget.amount).map((snap) {
              return AppBanner(
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
              );
            }).toList()
          : [],
    );
  }
}
