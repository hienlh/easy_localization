import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'asset_loader.dart';
import 'translations.dart';

class Localization {
  Translations _translations;
  Translations _fallbackTranslations;
  Locale _locale;

  String path;
  bool useOnlyLangCode;
  final RegExp _replaceArgRegex = RegExp(r'{}');

  Localization();

  static Localization _instance;
  static Localization get instance => _instance ?? (_instance = Localization());
  static Localization of(BuildContext context) =>
      Localizations.of<Localization>(context, Localization);

  static Future<bool> load(
    Locale locale,
    Locale fallbackLocale, {
    String path,
    bool useOnlyLangCode,
    AssetLoader assetLoader,
  }) async {
    assert(locale != null &&
        path != null &&
        useOnlyLangCode != null &&
        assetLoader != null);
    instance._locale = locale;
    instance.path = path;
    instance.useOnlyLangCode = useOnlyLangCode;

    String localePath = instance.getLocalePath();
    if (await assetLoader.localeExists(localePath) == true) {
      Map<String, dynamic> data = await assetLoader.load(localePath);
      instance._translations = Translations(data);
      _loadFallBack(fallbackLocale,
          assetLoader: assetLoader,
          path: path,
          useOnlyLangCode: useOnlyLangCode);
      return true;
    } else {
      Map<String, dynamic> data = await assetLoader
          .load(_getLocalePath(fallbackLocale, path, useOnlyLangCode));
      instance._translations = Translations(data);

      _loadFallBack(fallbackLocale,
          assetLoader: assetLoader,
          path: path,
          useOnlyLangCode: useOnlyLangCode);
      return false;
    }
  }

  static void _loadFallBack(
    Locale fallbackLocale, {
    String path,
    bool useOnlyLangCode,
    AssetLoader assetLoader,
  }) async {
    Map<String, dynamic> fallbackData = await assetLoader
        .load(_getLocalePath(fallbackLocale, path, useOnlyLangCode));
    instance._fallbackTranslations = Translations(fallbackData);
  }

  String getLocalePath() => _getLocalePath(_locale, path, useOnlyLangCode);

  static String _getLocalePath(
      Locale locale, String path, bool useOnlyLangCode) {
    final String _codeLang = locale.languageCode;
    final String _codeCoun = locale.countryCode;
    final String localePath = '$path/$_codeLang';

    return useOnlyLangCode ? '$localePath.json' : '$localePath-$_codeCoun.json';
  }

  String tr(String key, {List<String> args, String gender}) {
    if (gender != null) return trGender(key, gender, args: args);
    return this._replaceArgs(this._resolve(key), args);
  }

  String trGender(
    String key,
    String gender, {
    List<String> args,
  }) =>
      this._replaceArgs(
        this._gender(key, gender: gender),
        args,
      );

  String _replaceArgs(String res, List<String> args) {
    if (args == null || args.isEmpty) return res;
    args.forEach((String str) => res = res.replaceFirst(_replaceArgRegex, str));
    return res;
  }

  String plural(String key, dynamic value, {NumberFormat format}) {
    final res = Intl.pluralLogic(value,
        zero: this._resolve(key + '.zero'),
        one: this._resolve(key + '.one'),
        two: this._resolve(key + '.two'),
        few: this._resolve(key + '.few'),
        many: this._resolve(key + '.many'),
        other: this._resolve(key + '.other') ?? key,
        locale: _locale.languageCode);
    return this._replaceArgs(res, [
      format == null ? '$value' : format.format(value),
    ]);
  }

  String _gender(String key, {String gender}) => Intl.genderLogic(
        gender,
        female: this._resolve(key + '.female'),
        male: this._resolve(key + '.male'),
        other: this._resolve(key + '.male'),
        locale: _locale.languageCode,
      );

  String _resolve(String key) {
    final String resource = this._translations.get(key);
    if (resource == null) {
      print(
          '[easy_localization] Missing message: "$key" for locale: "${this._locale.languageCode}", using fallback.');

      return this._fallbackTranslations.get(key) ?? key;
    }

    return resource;
  }
}
