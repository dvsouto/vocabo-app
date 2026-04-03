import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

final showWordDetailModalProvider = StateProvider<bool>((ref) => false);
final selectedWordProvider = StateProvider<UserVocabulary?>((ref) => null);
