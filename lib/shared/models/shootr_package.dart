enum ShootrPackageType { basic, pro, luxe, drone }

extension ShootrPackageTypeX on ShootrPackageType {
  String get label {
    switch (this) {
      case ShootrPackageType.basic:
        return 'Basic';
      case ShootrPackageType.pro:
        return 'Pro';
      case ShootrPackageType.luxe:
        return 'Luxe';
      case ShootrPackageType.drone:
        return 'Drone Add-on';
    }
  }
}

class ShootrPackage {
  const ShootrPackage({
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    this.isAddon = false,
    this.inclusions = const <String>[],
    this.requiresDrone = false,
  });

  final ShootrPackageType type;
  final String title;
  final String description;
  final double price;
  final bool isAddon;
  final List<String> inclusions;
  final bool requiresDrone;
}
