import 'dart:math';

import 'package:creavers_delivery_mobile/core/models/address_suggestion.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class AddressSuggestionService {
  Future<List<AddressSuggestion>> search(String query);

  Future<AddressSuggestion> resolve(AddressSuggestion suggestion);

  Future<AddressSuggestion?> geocode(String address);

  Future<String?> reverseGeocode(double latitude, double longitude);
}

final class LocalAddressSuggestionService implements AddressSuggestionService {
  const LocalAddressSuggestionService();

  static const _places = <AddressSuggestion>[
    AddressSuggestion(
      title: 'Saris Abo',
      subtitle: 'Nifas Silk-Lafto, Addis Ababa',
      fullAddress: 'Saris Abo, Nifas Silk-Lafto, Addis Ababa',
      latitude: 8.9576,
      longitude: 38.7468,
    ),
    AddressSuggestion(
      title: 'Saris Addisu Sefer',
      subtitle: 'Near Saris, Addis Ababa',
      fullAddress: 'Saris Addisu Sefer, Addis Ababa',
      latitude: 8.9638,
      longitude: 38.7596,
    ),
    AddressSuggestion(
      title: 'Saris Commercial Center',
      subtitle: 'Debre Zeit Road, Addis Ababa',
      fullAddress: 'Saris Commercial Center, Debre Zeit Road, Addis Ababa',
      latitude: 8.9649,
      longitude: 38.7674,
    ),
    AddressSuggestion(
      title: 'Bole Atlas',
      subtitle: 'Bole, Addis Ababa',
      fullAddress: 'Bole Atlas, Bole, Addis Ababa',
      latitude: 8.9981,
      longitude: 38.7877,
    ),
    AddressSuggestion(
      title: 'Bole Medhanialem',
      subtitle: 'Cameroon Street, Addis Ababa',
      fullAddress: 'Bole Medhanialem, Cameroon Street, Addis Ababa',
      latitude: 8.9959,
      longitude: 38.7894,
    ),
    AddressSuggestion(
      title: 'Megenagna',
      subtitle: 'Yeka, Addis Ababa',
      fullAddress: 'Megenagna, Yeka, Addis Ababa',
      latitude: 9.0207,
      longitude: 38.8024,
    ),
    AddressSuggestion(
      title: 'CMC',
      subtitle: 'Yeka, Addis Ababa',
      fullAddress: 'CMC, Yeka, Addis Ababa',
      latitude: 9.0294,
      longitude: 38.8517,
    ),
    AddressSuggestion(
      title: 'Gurd Shola',
      subtitle: 'Yeka, Addis Ababa',
      fullAddress: 'Gurd Shola, Yeka, Addis Ababa',
      latitude: 9.0278,
      longitude: 38.8177,
    ),
    AddressSuggestion(
      title: 'Gerji',
      subtitle: 'Bole, Addis Ababa',
      fullAddress: 'Gerji, Bole, Addis Ababa',
      latitude: 9.0037,
      longitude: 38.8245,
    ),
    AddressSuggestion(
      title: 'Ayat',
      subtitle: 'Bole, Addis Ababa',
      fullAddress: 'Ayat, Bole, Addis Ababa',
      latitude: 9.0357,
      longitude: 38.8904,
    ),
    AddressSuggestion(
      title: 'Summit',
      subtitle: 'Bole, Addis Ababa',
      fullAddress: 'Summit, Bole, Addis Ababa',
      latitude: 9.0297,
      longitude: 38.8684,
    ),
    AddressSuggestion(
      title: 'Kazanchis',
      subtitle: 'Kirkos, Addis Ababa',
      fullAddress: 'Kazanchis, Kirkos, Addis Ababa',
      latitude: 9.0182,
      longitude: 38.7663,
    ),
    AddressSuggestion(
      title: 'Mexico Square',
      subtitle: 'Kirkos, Addis Ababa',
      fullAddress: 'Mexico Square, Kirkos, Addis Ababa',
      latitude: 9.0101,
      longitude: 38.7460,
    ),
    AddressSuggestion(
      title: 'Piazza',
      subtitle: 'Arada, Addis Ababa',
      fullAddress: 'Piazza, Arada, Addis Ababa',
      latitude: 9.0364,
      longitude: 38.7523,
    ),
    AddressSuggestion(
      title: 'Merkato',
      subtitle: 'Addis Ketema, Addis Ababa',
      fullAddress: 'Merkato, Addis Ketema, Addis Ababa',
      latitude: 9.0301,
      longitude: 38.7387,
    ),
    AddressSuggestion(
      title: 'Lebu',
      subtitle: 'Nifas Silk-Lafto, Addis Ababa',
      fullAddress: 'Lebu, Nifas Silk-Lafto, Addis Ababa',
      latitude: 8.9404,
      longitude: 38.7268,
    ),
    AddressSuggestion(
      title: 'Jemo',
      subtitle: 'Nifas Silk-Lafto, Addis Ababa',
      fullAddress: 'Jemo, Nifas Silk-Lafto, Addis Ababa',
      latitude: 8.9470,
      longitude: 38.6904,
    ),
    AddressSuggestion(
      title: 'Old Airport',
      subtitle: 'Lideta, Addis Ababa',
      fullAddress: 'Old Airport, Lideta, Addis Ababa',
      latitude: 9.0084,
      longitude: 38.7188,
    ),
    AddressSuggestion(
      title: 'Tor Hailoch',
      subtitle: 'Kolfe Keranio, Addis Ababa',
      fullAddress: 'Tor Hailoch, Kolfe Keranio, Addis Ababa',
      latitude: 9.0055,
      longitude: 38.7045,
    ),
    AddressSuggestion(
      title: '4 Kilo',
      subtitle: 'Arada, Addis Ababa',
      fullAddress: '4 Kilo, Arada, Addis Ababa',
      latitude: 9.0347,
      longitude: 38.7627,
    ),
    AddressSuggestion(
      title: '6 Kilo',
      subtitle: 'Arada, Addis Ababa',
      fullAddress: '6 Kilo, Arada, Addis Ababa',
      latitude: 9.0437,
      longitude: 38.7599,
    ),
  ];

  @override
  Future<List<AddressSuggestion>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const <AddressSuggestion>[];

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final matches = _places.where((place) {
      final searchable = '${place.title} ${place.subtitle}'.toLowerCase();
      return tokens.every(searchable.contains);
    }).toList();

    matches.sort((left, right) {
      final leftStarts = left.title.toLowerCase().startsWith(normalized);
      final rightStarts = right.title.toLowerCase().startsWith(normalized);
      if (leftStarts != rightStarts) return leftStarts ? -1 : 1;
      return left.title.compareTo(right.title);
    });
    return matches.take(5).toList(growable: false);
  }

  @override
  Future<AddressSuggestion> resolve(AddressSuggestion suggestion) async {
    if (!suggestion.hasCoordinates) {
      throw const ApiException(
        message: 'Select the exact delivery point on the map.',
      );
    }
    return suggestion;
  }

  @override
  Future<AddressSuggestion?> geocode(String address) async {
    final results = await search(address);
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    AddressSuggestion? nearest;
    var nearestDistance = double.infinity;
    for (final place in _places) {
      final latitudeDelta = place.latitude! - latitude;
      final longitudeDelta = place.longitude! - longitude;
      final distance =
          latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = place;
      }
    }
    return nearestDistance <= 0.0004 ? nearest?.fullAddress : null;
  }
}

/// Keeps Google Web Service credentials on the API server. The mobile client
/// receives only predictions and coordinates that the signed-in user may use.
final class ApiAddressSuggestionService implements AddressSuggestionService {
  ApiAddressSuggestionService(this._client, this._fallback)
    : _sessionToken = _newSessionToken();

  final ApiClient _client;
  final AddressSuggestionService _fallback;
  String _sessionToken;

  @override
  Future<List<AddressSuggestion>> search(String query) async {
    if (query.trim().length < 2) return const <AddressSuggestion>[];
    try {
      final parameters = Uri(
        queryParameters: <String, String>{
          'query': query.trim(),
          'sessionToken': _sessionToken,
        },
      ).query;
      final response = await _client.get(
        'maps/places/autocomplete?$parameters',
      );
      if (response is! List<Object?>) return const <AddressSuggestion>[];
      return response
          .whereType<Map<String, Object?>>()
          .map(
            (item) => AddressSuggestion(
              placeId: item['placeId']?.toString(),
              title: item['mainText']?.toString() ?? '',
              subtitle: item['secondaryText']?.toString() ?? '',
              fullAddress: item['fullText']?.toString() ?? '',
              sessionToken: _sessionToken,
            ),
          )
          .where((item) => item.placeId?.isNotEmpty == true)
          .toList(growable: false);
    } on ApiException catch (error) {
      if (error.statusCode != 503) rethrow;
      return _fallback.search(query);
    }
  }

  @override
  Future<AddressSuggestion> resolve(AddressSuggestion suggestion) async {
    if (suggestion.hasCoordinates) return suggestion;
    final placeId = suggestion.placeId;
    if (placeId == null || placeId.isEmpty) {
      return _fallback.resolve(suggestion);
    }

    try {
      final token = suggestion.sessionToken ?? _sessionToken;
      final parameters = Uri(
        queryParameters: <String, String>{'sessionToken': token},
      ).query;
      final response = await _client.get(
        'maps/places/${Uri.encodeComponent(placeId)}?$parameters',
      );
      if (response is! Map<String, Object?>) {
        throw const ApiException(
          message: 'This address could not be located. Choose it on the map.',
        );
      }
      _sessionToken = _newSessionToken();
      return _locationFromJson(response);
    } on ApiException catch (error) {
      if (error.statusCode != 503) rethrow;
      return _fallback.resolve(suggestion);
    }
  }

  @override
  Future<AddressSuggestion?> geocode(String address) async {
    try {
      final parameters = Uri(
        queryParameters: <String, String>{'address': address.trim()},
      ).query;
      final response = await _client.get('maps/geocode?$parameters');
      return response is Map<String, Object?>
          ? _locationFromJson(response)
          : null;
    } on ApiException catch (error) {
      if (error.statusCode != 503) rethrow;
      return _fallback.geocode(address);
    }
  }

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final parameters = Uri(
        queryParameters: <String, String>{
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      ).query;
      final response = await _client.get('maps/reverse-geocode?$parameters');
      return response is Map<String, Object?>
          ? response['formattedAddress']?.toString()
          : null;
    } on ApiException catch (error) {
      if (error.statusCode != 503) rethrow;
      return _fallback.reverseGeocode(latitude, longitude);
    }
  }

  AddressSuggestion _locationFromJson(Map<String, Object?> json) =>
      AddressSuggestion(
        placeId: json['placeId']?.toString(),
        title: json['formattedAddress']?.toString() ?? 'Delivery location',
        subtitle: 'Verified map location',
        fullAddress: json['formattedAddress']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  static String _newSessionToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }
}
