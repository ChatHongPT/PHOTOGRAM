import 'dart:typed_data';

enum FilterType { none, chrome, mono, sepia }

class Shot {
  final int index;
  final Uint8List? original;
  final Uint8List? edited;
  final FilterType filter;

  Shot({
    required this.index,
    this.original,
    this.edited,
    this.filter = FilterType.none,
  });

  Shot copyWith({Uint8List? original, Uint8List? edited, FilterType? filter}) {
    return Shot(
      index: index,
      original: original ?? this.original,
      edited: edited ?? this.edited,
      filter: filter ?? this.filter,
    );
  }
}
