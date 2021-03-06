class Translations {
  final Map<String, dynamic> _translations;
  final Map<String, dynamic> _nestedKeysCache;

  Translations(this._translations) : this._nestedKeysCache = {};
  String get(String key) =>
      (isNestedKey(key) ? getNested(key) : _translations[key]);

  String getNested(String key) {
    if (isNestedCached(key)) return _nestedKeysCache[key];

    List<String> keys = key.split('.');
    String kHead = keys.first;

    var value = _translations[kHead];

    for (var i = 1; i < keys.length; i++)
      if (value is Map<String, dynamic>) value = value[keys[i]];

    cacheNestedKey(key, value);
    return value;
  }

  bool has(String key) => isNestedKey(key)
      ? getNested(key) != null
      : _translations.containsKey(key);

  bool isNestedCached(String key) => _nestedKeysCache.containsKey(key);

  cacheNestedKey(String key, String value) {
    if (!isNestedKey(key))
      throw new Exception("Cannot cache a key that is not nested.");

    _nestedKeysCache[key] = value;
  }

  bool isNestedKey(String key) =>
      !_translations.containsKey(key) && key.indexOf('.') != -1;
}
