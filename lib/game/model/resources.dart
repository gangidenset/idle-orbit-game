/// Core resource types of IDLE ORBIT.
enum ResourceType {
  ore('ore', '鉱石'),
  energy('energy', 'エネルギー'),
  alloy('alloy', '合金'),
  research('research', '研究ポイント');

  const ResourceType(this.key, this.label);

  final String key;
  final String label;

  static ResourceType? tryParse(String key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// Immutable-ish bag of resource amounts. Used for costs, rewards and stock.
class ResourceBag {
  ResourceBag([Map<ResourceType, double>? values])
      : _v = {for (final r in ResourceType.values) r: values?[r] ?? 0.0};

  final Map<ResourceType, double> _v;

  static ResourceBag zero() => ResourceBag();

  /// Parses `{"ore": 10, "alloy": 2}`. Unknown keys are rejected so that
  /// typos in balance data surface immediately.
  factory ResourceBag.fromJson(Map<String, dynamic>? json) {
    final bag = ResourceBag();
    json?.forEach((k, v) {
      final r = ResourceType.tryParse(k);
      if (r == null) {
        throw FormatException('Unknown resource key "$k"');
      }
      bag._v[r] = (v as num).toDouble();
    });
    return bag;
  }

  Map<String, dynamic> toJson() => {
        for (final e in _v.entries)
          if (e.value != 0) e.key.key: e.value,
      };

  double operator [](ResourceType r) => _v[r]!;
  void operator []=(ResourceType r, double v) => _v[r] = v;

  Iterable<MapEntry<ResourceType, double>> get entries => _v.entries;
  Iterable<MapEntry<ResourceType, double>> get nonZero =>
      _v.entries.where((e) => e.value != 0);

  bool get isEmpty => _v.values.every((v) => v == 0);

  ResourceBag copy() => ResourceBag(Map.of(_v));

  ResourceBag scaled(double f) =>
      ResourceBag({for (final e in _v.entries) e.key: e.value * f});

  ResourceBag operator +(ResourceBag o) =>
      ResourceBag({for (final r in ResourceType.values) r: this[r] + o[r]});

  ResourceBag operator -(ResourceBag o) =>
      ResourceBag({for (final r in ResourceType.values) r: this[r] - o[r]});

  void addAll(ResourceBag o) {
    for (final r in ResourceType.values) {
      _v[r] = _v[r]! + o[r];
    }
  }

  /// True when every amount in [cost] is covered.
  bool covers(ResourceBag cost) =>
      ResourceType.values.every((r) => this[r] + 1e-9 >= cost[r]);

  @override
  String toString() => 'ResourceBag(${toJson()})';
}
