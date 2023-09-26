import 'package:appstream/appstream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapd/snapd.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '/appstream.dart';
import '/snapd.dart';
import '/widgets.dart';
import 'search_provider.dart';

sealed class AutoCompleteOption {
  String get title => switch (this) {
        AutoCompleteSnapOption(snap: final snap) => snap.titleOrName,
        AutoCompleteDebOption(deb: final deb) => deb.getLocalizedName(),
        AutoCompleteSearchOption(query: final query) => query,
      };
}

class AutoCompleteSnapOption extends AutoCompleteOption {
  final Snap snap;
  AutoCompleteSnapOption(this.snap);
}

class AutoCompleteDebOption extends AutoCompleteOption {
  final AppstreamComponent deb;
  AutoCompleteDebOption(this.deb);
}

class AutoCompleteSearchOption extends AutoCompleteOption {
  final String query;
  AutoCompleteSearchOption(this.query);
}

class SearchField extends ConsumerStatefulWidget {
  const SearchField({
    super.key,
    required this.onSearch,
    required this.onSnapSelected,
    required this.onDebSelected,
  });

  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSnapSelected;
  final ValueChanged<String> onDebSelected;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  double? _optionsWidth;
  bool _optionsAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = (context.findRenderObject() as RenderBox?)?.size.width;
      if (_optionsWidth != width) {
        setState(() => _optionsWidth = width);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RawAutocomplete<AutoCompleteOption>(
      optionsBuilder: (query) async {
        ref.read(queryProvider.notifier).state = query.text;
        final options = await ref.watch(autoCompleteProvider.future);
        if (options.snaps.isEmpty && options.debs.isEmpty) return [];
        _optionsAvailable = true;
        final snapOptions = options.snaps
            .take(3)
            .map<AutoCompleteOption>(AutoCompleteSnapOption.new)
            .toList();
        final debOptions = options.debs
            .take(3)
            .map<AutoCompleteOption>(AutoCompleteDebOption.new)
            .toList();
        return <AutoCompleteOption>[
          AutoCompleteSearchOption(query.text),
          ...snapOptions,
          ...debOptions,
        ];
      },
      displayStringForOption: (option) => option.title,
      optionsViewBuilder: (context, onSelected, options) {
        final snapOptions = options.whereType<AutoCompleteSnapOption>();
        final debOptions = options.whereType<AutoCompleteDebOption>();
        final searchOption =
            options.whereType<AutoCompleteSearchOption>().single;
        final highlightedOption =
            options.elementAt(AutocompleteHighlightedOption.of(context));

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: _optionsWidth,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  if (snapOptions.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        l10n.searchFieldSnapSection,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ...snapOptions.map((e) => _AutoCompleteTile(
                          option: e,
                          onTap: () => onSelected(e),
                          selected: e == highlightedOption,
                        )),
                    const Divider(),
                  ],
                  if (debOptions.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        l10n.searchFieldDebSection,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ...debOptions.map((e) => _AutoCompleteTile(
                          option: e,
                          onTap: () => onSelected(e),
                          selected: e == highlightedOption,
                        )),
                    const Divider(),
                  ],
                  _AutoCompleteTile(
                    option: searchOption,
                    onTap: () => onSelected(searchOption),
                    selected: searchOption == highlightedOption,
                  )
                ],
              ),
            ),
          ),
        );
      },
      onSelected: (option) => switch (option) {
        AutoCompleteSnapOption(snap: final snap) =>
          widget.onSnapSelected(snap.name),
        AutoCompleteDebOption(deb: final deb) => widget.onDebSelected(deb.id),
        AutoCompleteSearchOption(query: final query) => widget.onSearch(query),
      },
      fieldViewBuilder: (context, controller, node, onFieldSubmitted) {
        return Consumer(builder: (context, ref, child) {
          ref.listen(queryProvider, (prev, next) {
            if (!node.hasPrimaryFocus) controller.text = next ?? '';
          });
          const iconConstraints = BoxConstraints(
            minWidth: 32,
            minHeight: 32,
            maxWidth: 32,
            maxHeight: 32,
          );
          return TextField(
            focusNode: node,
            controller: controller,
            onChanged: (_) => _optionsAvailable = false,
            onSubmitted: (query) =>
                _optionsAvailable ? onFieldSubmitted() : widget.onSearch(query),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              fillColor: Theme.of(context).dividerColor,
              prefixIcon: const Icon(YaruIcons.search, size: 16),
              prefixIconConstraints: iconConstraints,
              hintText: l10n.searchFieldSearchHint,
              suffixIcon: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return YaruIconButton(
                    icon: const Icon(YaruIcons.edit_clear, size: 16),
                    onPressed:
                        controller.text.isEmpty ? null : controller.clear,
                  );
                },
              ),
              suffixIconConstraints: iconConstraints,
            ),
          );
        });
      },
    );
  }
}

class _AutoCompleteTile extends StatelessWidget {
  const _AutoCompleteTile({
    required this.option,
    required this.onTap,
    required this.selected,
  });

  static const _iconSize = 32.0;

  final AutoCompleteOption option;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (option) {
      AutoCompleteSnapOption(snap: final snap) => ListTile(
          selected: selected,
          title: Text(snap.titleOrName),
          leading: AppIcon(
            size: _iconSize,
            iconUrl: snap.iconUrl,
          ),
          onTap: onTap,
        ),
      AutoCompleteDebOption(deb: final deb) => ListTile(
          selected: selected,
          title: Text(deb.getLocalizedName()),
          leading: AppIcon(
            size: _iconSize,
            iconUrl:
                deb.icons.whereType<AppstreamRemoteIcon>().firstOrNull?.url,
          ),
          onTap: onTap,
        ),
      AutoCompleteSearchOption(query: final query) => ListTile(
          selected: selected,
          title: Text(
            l10n.searchFieldSearchForLabel(query),
          ),
          onTap: onTap,
        ),
    };
  }
}
