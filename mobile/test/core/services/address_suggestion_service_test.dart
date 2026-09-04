import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LocalAddressSuggestionService();

  test(
    'returns relevant Addis Ababa suggestions after two characters',
    () async {
      final results = await service.search('Saris');

      expect(results, isNotEmpty);
      expect(results.first.title, 'Saris Abo');
      expect(
        results.every((result) => result.fullAddress.contains('Addis Ababa')),
        isTrue,
      );
    },
  );

  test('does not suggest places for a one-character query', () async {
    expect(await service.search('S'), isEmpty);
  });
}
