import 'package:creavers_delivery_mobile/core/models/address_suggestion.dart';

abstract interface class AddressSuggestionService {
  Future<List<AddressSuggestion>> search(String query);
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
}
