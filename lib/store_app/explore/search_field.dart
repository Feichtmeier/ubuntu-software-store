import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/store_app/common/snap_section.dart';
import 'package:software/store_app/explore/explore_model.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SearchField extends StatefulWidget {
  const SearchField({Key? key}) : super(key: key);

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return TextField(
      controller: _controller,
      onEditingComplete: () {
        model.searchQuery = _controller.text;
      },
      textInputAction: TextInputAction.send,
      autofocus: true,
      decoration: InputDecoration(
        suffixText:
            '${context.l10n.searchHint} ${model.selectedSection.localize(context.l10n)} ${context.l10n.apps}',
        suffixIcon: _SectionDropdown(
          value: model.selectedSection,
          onChanged: (v) => model.selectedSection = v!,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 20),
        prefixIcon: model.searchQuery == ''
            ? Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: YaruRoundIconButton(
                  size: 36,
                  onTap: () {
                    model.searchActive = false;
                  },
                  child: const Icon(YaruIcons.go_previous),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: YaruRoundIconButton(
                  size: 36,
                  onTap: () {
                    model.searchQuery = '';
                    _controller.text = '';
                  },
                  child: const Icon(YaruIcons.edit_clear),
                ),
              ),
        isDense: false,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _SectionDropdown extends StatelessWidget {
  const _SectionDropdown({
    // ignore: unused_element
    super.key,
    required this.value,
    this.onChanged,
  });

  final SnapSection value;
  final Function(SnapSection?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SnapSection>(
      tooltip: context.l10n.filterSnaps,
      splashRadius: 20,
      onSelected: onChanged,
      icon: Icon(snapSectionToIcon[value]),
      initialValue: SnapSection.all,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      itemBuilder: (context) {
        return [
          for (final section in SnapSection.values)
            PopupMenuItem(
              value: section,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 5,
                  ),
                  SizedBox(
                    width: 20,
                    child: Icon(
                      snapSectionToIcon[section],
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    section.localize(
                      context.l10n,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            )
        ];
      },
    );
  }
}
