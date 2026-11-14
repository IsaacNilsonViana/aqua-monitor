import 'package:aqua_monitor/services/sensor_payload_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = SensorPayloadParser();

  test('interpreta pacote JSON', () {
    final reading = parser.parseLine(
      '{"ph":7.12,"turbidity":2.4,"tds":238,"oxygen":6.35}',
    );
    expect(reading, isNotNull);
    expect(reading!.ph, 7.12);
    expect(reading.turbidity, 2.4);
    expect(reading.tds, 238);
    expect(reading.dissolvedOxygen, 6.35);
  });

  test('interpreta pacote CSV', () {
    final reading = parser.parseLine('6.9,4.1,300,5.8');
    expect(reading, isNotNull);
    expect(reading!.ph, 6.9);
    expect(reading.turbidity, 4.1);
    expect(reading.tds, 300);
    expect(reading.dissolvedOxygen, 5.8);
  });

  test('mantem compatibilidade com pacote sem oxigenio', () {
    final reading = parser.parseLine('7.0,2.0,200');
    expect(reading, isNotNull);
    expect(reading!.dissolvedOxygen, isNull);
  });

  test('rejeita pacote incompleto ou fora da faixa fisica', () {
    expect(parser.parseLine('7.0,3.0'), isNull);
    expect(parser.parseLine('{"ph":17,"turbidity":2,"tds":200}'), isNull);
  });
}
