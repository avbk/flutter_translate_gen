import 'package:flutter/foundation.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_translate_annotations/flutter_translate_annotations.dart';

part 'i18n.g.dart';

@FlutterTranslate(
  path: 'assets/i18n.v2',
  missingTranslations: ErrorLevel.warning,
)
const i18n = _$I18n();

@FlutterTranslate(
  path: 'assets/i18n',
  missingTranslations: ErrorLevel.warning,
  keysStyle: KeysStyle.keysOnly,
  nestingStyle: NestingStyle.flat,
  caseStyle: CaseStyle.titleCase,
)
const Keys = _$Keys();
