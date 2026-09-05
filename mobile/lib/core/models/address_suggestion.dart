final class AddressSuggestion {
  const AddressSuggestion({
    required this.title,
    required this.subtitle,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.placeId,
    this.sessionToken,
  });

  final String title;
  final String subtitle;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? sessionToken;

  bool get hasCoordinates => latitude != null && longitude != null;
}
