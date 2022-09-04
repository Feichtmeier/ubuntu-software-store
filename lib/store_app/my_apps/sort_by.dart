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

import 'package:software/l10n/l10n.dart';

enum SortBy {
  name,
  installDate,
  size,
  confinement,
  updateAvailable;

  String localize(AppLocalizations l10n) {
    switch (this) {
      case SortBy.name:
        return l10n.name;
      case SortBy.confinement:
        return l10n.confinement;
      case SortBy.installDate:
        return l10n.installDate;
      case SortBy.size:
        return l10n.size;
      case SortBy.updateAvailable:
        return l10n.updateAvailable;
    }
  }
}
