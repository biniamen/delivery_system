final class AddressSuggestion {
  const AddressSuggestion({
    required this.title,
    required this.subtitle,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String subtitle;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
}
