
enum DefaultTravelMode {
  fastest('Fastest'),
  cheapest('Cheapest');

  const DefaultTravelMode(this.displayName);

  final String displayName;
}

enum FuelType {
  ron95('RON95'),
  ron97('RON97'),
  diesel('Diesel');

  const FuelType(this.displayName);

  final String displayName;
}
