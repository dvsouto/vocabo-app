import 'package:equatable/equatable.dart';

class UsageExamples extends Equatable {
  final Map<String, List<String>> _data;

  const UsageExamples._(this._data);

  factory UsageExamples.fromJson(Map<String, dynamic> json) {
    final data = <String, List<String>>{};
    for (final entry in json.entries) {
      if (entry.value is List) {
        data[entry.key] = (entry.value as List)
            .map((e) => e.toString())
            .toList(growable: false);
      }
    }
    return UsageExamples._(data);
  }

  Map<String, dynamic> toJson() {
    return _data.map((key, value) => MapEntry(key, value));
  }

  List<String> get sourceLang {
    if (_data.isEmpty) return const [];
    return _data.values.first;
  }

  List<String> get targetLang {
    if (_data.length < 2) return const [];
    return _data.values.elementAt(1);
  }

  List<String> operator [](String key) => _data[key] ?? const [];

  Map<String, List<String>> get entries => _data;

  @override
  List<Object?> get props => [_data];
}
