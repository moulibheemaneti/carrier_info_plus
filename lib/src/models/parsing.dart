/// Helpers for decoding the loosely-typed maps that come back over the
/// platform channel.
///
/// Android hands Dart a `Map<Object?, Object?>`, so every nested map has to be
/// re-keyed before it can be read. These helpers centralise that, and make a
/// malformed or partial payload degrade to a default rather than throw.
library;

/// Re-keys a platform map into a `Map<String, Object?>`.
Map<String, Object?> asMap(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }
  return const <String, Object?>{};
}

/// Reads a list of nested maps, skipping anything that is not a map.
List<Map<String, Object?>> asMapList(Object? value) {
  if (value is! List) return const <Map<String, Object?>>[];
  return <Map<String, Object?>>[
    for (final element in value)
      if (element is Map) asMap(element),
  ];
}

/// Reads a list of strings, skipping nulls.
List<String> asStringList(Object? value) {
  if (value is! List) return const <String>[];
  return <String>[
    for (final element in value)
      if (element != null) element.toString(),
  ];
}

/// Reads a non-empty string, mapping `null` and `''` alike to `null`.
///
/// The telephony APIs return empty strings for "not available" about as often
/// as they return null, and callers should not have to distinguish the two.
String? asString(Object? value) {
  if (value == null) return null;
  final string = value.toString();
  return string.isEmpty ? null : string;
}

/// Reads an int, tolerating a platform that sends it as a string or double.
int? asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

/// Reads a bool, defaulting to [orElse] when absent or malformed.
bool asBool(Object? value, {bool orElse = false}) =>
    value is bool ? value : orElse;
