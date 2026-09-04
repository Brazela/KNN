




class ParkingSpot {
  
  const ParkingSpot({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    required this.distanceFromDestinationMeters,
    required this.estimatedPricePerHour,
    this.photoUrls = const [],
    this.openNow,
    this.weekdayDescriptions,
  });

  final String placeId;

  final String name;

  final String? vicinity;

  final double rating;

  final int userRatingsTotal;

  final double latitude;

  final double longitude;

  
  final int distanceFromDestinationMeters;


  final double estimatedPricePerHour;

  final List<String> photoUrls;

  final bool? openNow;

  
  final List<String>? weekdayDescriptions;

  
  bool get isFree => estimatedPricePerHour == 0.0;

  String? get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  
  ParkingSpot copyWith({
    String? placeId,
    String? name,
    String? vicinity,
    double? rating,
    int? userRatingsTotal,
    double? latitude,
    double? longitude,
    int? distanceFromDestinationMeters,
    double? estimatedPricePerHour,
    List<String>? photoUrls,
    bool? openNow,
    List<String>? weekdayDescriptions,
    bool clearPhotoUrls = false,
    bool clearOpenNow = false,
    bool clearWeekdayDescriptions = false,
  }) {
    return ParkingSpot(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      vicinity: vicinity ?? this.vicinity,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromDestinationMeters:
          distanceFromDestinationMeters ?? this.distanceFromDestinationMeters,
      estimatedPricePerHour:
          estimatedPricePerHour ?? this.estimatedPricePerHour,
      photoUrls: clearPhotoUrls ? const [] : (photoUrls ?? this.photoUrls),
      openNow: clearOpenNow ? null : (openNow ?? this.openNow),
      weekdayDescriptions: clearWeekdayDescriptions
          ? null
          : (weekdayDescriptions ?? this.weekdayDescriptions),
    );
  }

  
  String get formattedDistance {
    if (distanceFromDestinationMeters < 1000) {
      return '${distanceFromDestinationMeters}m';
    }
    return '${(distanceFromDestinationMeters / 1000).toStringAsFixed(1)}km';
  }

  
  String get formattedPrice {
    if (estimatedPricePerHour == 0.0) return 'Free';
    return 'RM ${estimatedPricePerHour.toStringAsFixed(2)}/hr';
  }

  
  String get displayName {
    if (name.length <= 32) return name;
    return '${name.substring(0, 29)}…';
  }


  String? get hoursSummary {
    if (openNow == true) return 'Open now';
    if (openNow == false) return 'Closed now';
    if (weekdayDescriptions != null && weekdayDescriptions!.isNotEmpty) {
      return weekdayDescriptions!.first;
    }
    return null;
  }
}
