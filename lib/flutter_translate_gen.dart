﻿import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:dart_utils/dart_utils.dart';
import 'package:flutter_translate_annotations/flutter_translate_annotations.dart';
import 'package:flutter_translate_gen/annotation_generator.dart';
import 'package:flutter_translate_gen/assets_reader.dart';
import 'package:flutter_translate_gen/json_parser.dart';
import 'package:flutter_translate_gen/translation_class_generator.dart';
import 'package:flutter_translate_gen/validator.dart';
import 'package:source_gen/source_gen.dart';

class FlutterTranslateGen extends AnnotationGenerator<FlutterTranslate> {
  const FlutterTranslateGen();

  @override
  Future<Library> generateLibraryForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (!element.isConstRootVariable) {
      throw InvalidGenerationSourceError(
        "The annotated element is not a root const variable! "
        "@FlutterTranslate should be used on expressions "
        "like const i18n = _\$I18N();",
        element: element,
      );
    }

    final className = "_\$${Casing.titleCase(element.name, separator: "")}";
    final options = _fromAnnotation(annotation);
    final files = await _getFiles(buildStep, options);
    final translations = const JsonParser().parse(files);

    final validationResult = const Validator().validate(
      options,
      translations,
      files.keys,
    );

    if (validationResult.isValid) {
      if (validationResult.warnings.isNotEmpty) {
        printList(validationResult.warnings);
      }

      final generatedClasses = TranslationClassGenerator(
        options,
      ).generate(
        translations,
        className,
      );
      return Library((lib) => lib.body.addAll(generatedClasses));
    } else {
      printList(validationResult.errors + validationResult.warnings);
      throw InvalidGenerationSourceError("Validation failed");
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getFiles(
    BuildStep step,
    FlutterTranslate options,
  ) async {
    try {
      return await const AssetsReader().read(step, options);
    } catch (e) {
      throw InvalidGenerationSourceError("Ths JSON format is invalid: $e");
    }
  }

  FlutterTranslate _fromAnnotation(ConstantReader annotation) {
    return FlutterTranslate(
        path: annotation.asString("path"),
        missingTranslations: annotation.asEnum(
          "missingTranslations",
          ErrorLevel.values,
        ),
        missingArguments: annotation.asEnum(
          "missingArguments",
          ErrorLevel.values,
        ),
        keysStyle: annotation.asEnum("keysStyle", KeysStyle.values) ??
            KeysStyle.withTranslate,
        nestingStyle: annotation.asEnum("nestingStyle", NestingStyle.values) ??
            NestingStyle.nested,
        caseStyle: annotation.asEnum(
              "caseStyle",
              CaseStyle.values,
            ) ??
            CaseStyle.camelCase,
        separator: annotation.asString("separator") ?? "_");
  }
}

extension on Element {
  bool get isConstRootVariable =>
      this is VariableElement &&
      (this as VariableElement).isConst &&
      enclosingElement is CompilationUnitElement;
}

extension on ConstantReader {
  String asString(String key) => peek(key)?.stringValue;

  T asEnum<T>(String key, List<T> values) => enumFromString(
        values,
        peek(key)?.revive()?.accessor,
      );
}
