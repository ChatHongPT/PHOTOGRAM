import 'dart:typed_data';

enum FilterType { none, mono, sepia, chrome }

class Shot {
  final int index; // 0‥3
  final Uint8List? original; // 촬영 원본
  final Uint8List? edited; // 필터 적용본
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
