import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helper: creates an isolated Field<String> outside any form context.
  // ---------------------------------------------------------------------------
  Field<String> makeField(void Function(Field<String> f) setup) {
    FormTracker.pauseTracking = true;
    final field = Field<String>('f');
    FormTracker.pauseTracking = false;
    setup(field);
    return field;
  }

  // ---------------------------------------------------------------------------
  // maskCPFOrCNPJ
  // ---------------------------------------------------------------------------
  group('maskCPFOrCNPJ', () {
    test('formats partial CPF progressively', () {
      final f = makeField((f) => f.maskCPFOrCNPJ());
      f.value = '123';
      expect(f.value, '123');
      f.value = '12345678';
      expect(f.value, '123.456.78');
      f.value = '12345678909';
      expect(f.value, '123.456.789-09');
    });

    test('formats full CNPJ', () {
      final f = makeField((f) => f.maskCPFOrCNPJ());
      f.value = '12345678000195';
      expect(f.value, '12.345.678/0001-95');
    });

    test('strips mask on json by default', () {
      final f = makeField((f) => f.maskCPFOrCNPJ());
      f.value = '12345678909';
      expect(f.jsonValue, '12345678909');
    });

    test('keeps mask on json when removeMaskOnJson is false', () {
      final f = makeField((f) => f.maskCPFOrCNPJ(removeMaskOnJson: false));
      f.value = '12345678909';
      expect(f.jsonValue, '123.456.789-09');
    });
  });

  // ---------------------------------------------------------------------------
  // maskAltura
  // ---------------------------------------------------------------------------
  group('maskAltura', () {
    test('single digit stays as-is', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '1';
      expect(f.value, '1');
    });

    test('two digits formats as d,d', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '18';
      expect(f.value, '1,8');
    });

    test('three digits formats as d,dd', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '182';
      expect(f.value, '1,82');
    });

    test('excess digits are truncated to 3', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '1825';
      expect(f.value, '1,82');
    });

    test('non-digit chars are stripped', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '1a8b2';
      expect(f.value, '1,82');
    });

    test('json value uses dot as decimal separator', () {
      final f = makeField((f) => f.maskAltura());
      f.value = '182';
      expect(f.jsonValue, '1.82');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCartaoCredito
  // ---------------------------------------------------------------------------
  group('maskCartaoCredito', () {
    test('formats groups of 4 digits with spaces', () {
      final f = makeField((f) => f.maskCartaoCredito());
      f.value = '1234567890123456';
      expect(f.value, '1234 5678 9012 3456');
    });

    test('partial input stops at last complete group', () {
      final f = makeField((f) => f.maskCartaoCredito());
      f.value = '12345';
      expect(f.value, '1234 5');
    });

    test('caps at 16 digits', () {
      final f = makeField((f) => f.maskCartaoCredito());
      f.value = '12345678901234567';
      expect(f.value, '1234 5678 9012 3456');
    });

    test('json strips spaces', () {
      final f = makeField((f) => f.maskCartaoCredito());
      f.value = '1234567890123456';
      expect(f.jsonValue, '1234567890123456');
    });
  });

  // ---------------------------------------------------------------------------
  // maskDecimal
  // ---------------------------------------------------------------------------
  group('maskDecimal', () {
    test('single digit pads to 0,0d', () {
      final f = makeField((f) => f.maskDecimal());
      f.value = '1';
      expect(f.value, '0,01');
    });

    test('3 digits gives d,dd', () {
      final f = makeField((f) => f.maskDecimal());
      f.value = '123';
      expect(f.value, '1,23');
    });

    test('7 digits applies thousands separator', () {
      final f = makeField((f) => f.maskDecimal());
      f.value = '1234567';
      expect(f.value, '12.345,67');
    });

    test('casasDecimais=3 uses 3 decimal places', () {
      final f = makeField((f) => f.maskDecimal(casasDecimais: 3));
      f.value = '1234567';
      expect(f.value, '1.234,567');
    });

    test('casasDecimais=0 formats as integer with thousands separator', () {
      final f = makeField((f) => f.maskDecimal(casasDecimais: 0));
      f.value = '1234567';
      expect(f.value, '1.234.567');
    });

    test('json converts to standard decimal (dot)', () {
      final f = makeField((f) => f.maskDecimal());
      f.value = '1234567';
      expect(f.jsonValue, '12345.67');
    });

    test('empty input clears value', () {
      final f = makeField((f) => f.maskDecimal());
      f.value = '123';
      f.value = '';
      expect(f.value, '');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCEP
  // ---------------------------------------------------------------------------
  group('maskCEP', () {
    test('formats with ponto by default: XX.XXX-XXX', () {
      final f = makeField((f) => f.maskCEP());
      f.value = '12345678';
      expect(f.value, '12.345-678');
    });

    test('formats without ponto: XXXXX-XXX', () {
      final f = makeField((f) => f.maskCEP(ponto: false));
      f.value = '12345678';
      expect(f.value, '12345-678');
    });

    test('partial input stops after dash', () {
      final f = makeField((f) => f.maskCEP());
      f.value = '123456';
      expect(f.value, '12.345-6');
    });

    test('caps at 8 digits', () {
      final f = makeField((f) => f.maskCEP());
      f.value = '123456789';
      expect(f.value, '12.345-678');
    });

    test('json strips all non-digits', () {
      final f = makeField((f) => f.maskCEP());
      f.value = '12345678';
      expect(f.jsonValue, '12345678');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCertidaoNascimento
  // ---------------------------------------------------------------------------
  group('maskCertidaoNascimento', () {
    test('formats 32 digits into XXXXXX XX XX XXXX X XXXXX XXX XXXXXXX XX', () {
      final f = makeField((f) => f.maskCertidaoNascimento());
      f.value = '12345678901234567890123456789012';
      expect(f.value, '123456 78 90 1234 5 67890 123 4567890 12');
    });

    test('partial input is formatted up to current length', () {
      final f = makeField((f) => f.maskCertidaoNascimento());
      f.value = '123456';
      expect(f.value, '123456');
      f.value = '1234567';
      expect(f.value, '123456 7');
      f.value = '12345678';
      expect(f.value, '123456 78');
    });

    test('json strips spaces', () {
      final f = makeField((f) => f.maskCertidaoNascimento());
      f.value = '12345678901234567890123456789012';
      expect(f.jsonValue, '12345678901234567890123456789012');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCEST
  // ---------------------------------------------------------------------------
  group('maskCEST', () {
    test('formats 7 digits as XX.XXX.XX', () {
      final f = makeField((f) => f.maskCEST());
      f.value = '1234567';
      expect(f.value, '12.345.67');
    });

    test('partial formats correctly', () {
      final f = makeField((f) => f.maskCEST());
      f.value = '12';
      expect(f.value, '12');
      f.value = '123';
      expect(f.value, '12.3');
    });

    test('caps at 7 digits', () {
      final f = makeField((f) => f.maskCEST());
      f.value = '12345678';
      expect(f.value, '12.345.67');
    });

    test('json strips dots', () {
      final f = makeField((f) => f.maskCEST());
      f.value = '1234567';
      expect(f.jsonValue, '1234567');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCNPJAlfanumerico
  // ---------------------------------------------------------------------------
  group('maskCNPJAlfanumerico', () {
    test('formats 14 alphanumeric chars as XX.XXX.XXX/XXXX-XX', () {
      final f = makeField((f) => f.maskCNPJAlfanumerico());
      f.value = 'AB1CD2EF3GH4IJ';
      expect(f.value, 'AB.1CD.2EF/3GH4-IJ');
    });

    test('converts to uppercase', () {
      final f = makeField((f) => f.maskCNPJAlfanumerico());
      f.value = 'ab1cd2ef3gh4ij';
      expect(f.value, 'AB.1CD.2EF/3GH4-IJ');
    });

    test('strips non-alphanumeric chars', () {
      final f = makeField((f) => f.maskCNPJAlfanumerico());
      f.value = 'AB.1CD.2EF/3GH4-IJ';
      expect(f.value, 'AB.1CD.2EF/3GH4-IJ');
    });

    test('caps at 14 alphanumeric chars', () {
      final f = makeField((f) => f.maskCNPJAlfanumerico());
      f.value = 'AB1CD2EF3GH4IJKL';
      expect(f.value, 'AB.1CD.2EF/3GH4-IJ');
    });

    test('json strips mask and uppercases', () {
      final f = makeField((f) => f.maskCNPJAlfanumerico());
      f.value = 'ab1cd2ef3gh4ij';
      expect(f.jsonValue, 'AB1CD2EF3GH4IJ');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCNPJ
  // ---------------------------------------------------------------------------
  group('maskCNPJ', () {
    test('formats 14 digits as 99.999.999/9999-99', () {
      final f = makeField((f) => f.maskCNPJ());
      f.value = '12345678000195';
      expect(f.value, '12.345.678/0001-95');
    });

    test('partial input', () {
      final f = makeField((f) => f.maskCNPJ());
      f.value = '12345';
      expect(f.value, '12.345');
    });

    test('strips non-digits', () {
      final f = makeField((f) => f.maskCNPJ());
      f.value = '12.345.678/0001-95';
      expect(f.value, '12.345.678/0001-95');
    });

    test('json strips all separators', () {
      final f = makeField((f) => f.maskCNPJ());
      f.value = '12345678000195';
      expect(f.jsonValue, '12345678000195');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCartaoTelefone
  // ---------------------------------------------------------------------------
  group('maskCartaoTelefone', () {
    test('formats 15 digits as 000 1111 2222 3333', () {
      final f = makeField((f) => f.maskCartaoTelefone());
      f.value = '123456789012345';
      expect(f.value, '123 4567 8901 2345');
    });

    test('partial formatting', () {
      final f = makeField((f) => f.maskCartaoTelefone());
      f.value = '1234';
      expect(f.value, '123 4');
    });

    test('caps at 15 digits', () {
      final f = makeField((f) => f.maskCartaoTelefone());
      f.value = '1234567890123456';
      expect(f.value, '123 4567 8901 2345');
    });

    test('json strips spaces', () {
      final f = makeField((f) => f.maskCartaoTelefone());
      f.value = '123456789012345';
      expect(f.jsonValue, '123456789012345');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCPF
  // ---------------------------------------------------------------------------
  group('maskCPF', () {
    test('formats 11 digits as XXX.XXX.XXX-XX', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '12345678909';
      expect(f.value, '123.456.789-09');
    });

    test('partial: 3 digits no separator', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '123';
      expect(f.value, '123');
    });

    test('partial: 4 digits adds first dot', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '1234';
      expect(f.value, '123.4');
    });

    test('caps at 11 digits', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '123456789099';
      expect(f.value, '123.456.789-09');
    });

    test('strips non-digits from input', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '123.456.789-09';
      expect(f.value, '123.456.789-09');
    });

    test('json strips all separators', () {
      final f = makeField((f) => f.maskCPF());
      f.value = '12345678909';
      expect(f.jsonValue, '12345678909');
    });
  });

  // ---------------------------------------------------------------------------
  // maskData
  // ---------------------------------------------------------------------------
  group('maskData', () {
    test('formats 8 digits as DD/MM/YYYY', () {
      final f = makeField((f) => f.maskData());
      f.value = '01011900';
      expect(f.value, '01/01/1900');
    });

    test('partial: 2 digits no separator', () {
      final f = makeField((f) => f.maskData());
      f.value = '01';
      expect(f.value, '01');
    });

    test('partial: 3 digits adds first slash', () {
      final f = makeField((f) => f.maskData());
      f.value = '011';
      expect(f.value, '01/1');
    });

    test('caps at 8 digits', () {
      final f = makeField((f) => f.maskData());
      f.value = '010119001';
      expect(f.value, '01/01/1900');
    });

    test('json strips slashes', () {
      final f = makeField((f) => f.maskData());
      f.value = '01011900';
      expect(f.jsonValue, '01011900');
    });
  });

  // ---------------------------------------------------------------------------
  // maskHora
  // ---------------------------------------------------------------------------
  group('maskHora', () {
    test('formats 4 digits as HH:mm', () {
      final f = makeField((f) => f.maskHora());
      f.value = '1430';
      expect(f.value, '14:30');
    });

    test('partial: 2 digits is hour only', () {
      final f = makeField((f) => f.maskHora());
      f.value = '14';
      expect(f.value, '14');
    });

    test('partial: 3 digits adds colon', () {
      final f = makeField((f) => f.maskHora());
      f.value = '143';
      expect(f.value, '14:3');
    });

    test('hour clamped to 23', () {
      final f = makeField((f) => f.maskHora());
      f.value = '2530';
      expect(f.value, '23:30');
    });

    test('minute clamped to 59', () {
      final f = makeField((f) => f.maskHora());
      f.value = '1460';
      expect(f.value, '14:59');
    });

    test('valid boundary 23:59', () {
      final f = makeField((f) => f.maskHora());
      f.value = '2359';
      expect(f.value, '23:59');
    });

    test('valid boundary 00:00', () {
      final f = makeField((f) => f.maskHora());
      f.value = '0000';
      expect(f.value, '00:00');
    });

    test('json strips colon', () {
      final f = makeField((f) => f.maskHora());
      f.value = '1430';
      expect(f.jsonValue, '1430');
    });
  });

  // ---------------------------------------------------------------------------
  // maskIOF
  // ---------------------------------------------------------------------------
  group('maskIOF', () {
    test('single digit stays as-is', () {
      final f = makeField((f) => f.maskIOF());
      f.value = '1';
      expect(f.value, '1');
    });

    test('7 digits: first + comma + 6', () {
      final f = makeField((f) => f.maskIOF());
      f.value = '1234567';
      expect(f.value, '1,234567');
    });

    test('caps at 7 digits', () {
      final f = makeField((f) => f.maskIOF());
      f.value = '12345678';
      expect(f.value, '1,234567');
    });

    test('partial: 3 digits', () {
      final f = makeField((f) => f.maskIOF());
      f.value = '123';
      expect(f.value, '1,23');
    });

    test('json converts comma to dot', () {
      final f = makeField((f) => f.maskIOF());
      f.value = '1234567';
      expect(f.jsonValue, '1.234567');
    });
  });

  // ---------------------------------------------------------------------------
  // maskKm
  // ---------------------------------------------------------------------------
  group('maskKm', () {
    test('formats 6 digits as 000.000', () {
      final f = makeField((f) => f.maskKm());
      f.value = '123456';
      expect(f.value, '123.456');
    });

    test('partial: 3 digits no dot', () {
      final f = makeField((f) => f.maskKm());
      f.value = '123';
      expect(f.value, '123');
    });

    test('partial: 4 digits adds dot', () {
      final f = makeField((f) => f.maskKm());
      f.value = '1234';
      expect(f.value, '123.4');
    });

    test('caps at 6 digits', () {
      final f = makeField((f) => f.maskKm());
      f.value = '1234567';
      expect(f.value, '123.456');
    });

    test('json strips dot', () {
      final f = makeField((f) => f.maskKm());
      f.value = '123456';
      expect(f.jsonValue, '123456');
    });
  });

  // ---------------------------------------------------------------------------
  // maskNCM
  // ---------------------------------------------------------------------------
  group('maskNCM', () {
    test('formats 8 digits as XXXX.XX.XX', () {
      final f = makeField((f) => f.maskNCM());
      f.value = '12345678';
      expect(f.value, '1234.56.78');
    });

    test('partial: 4 digits no dot', () {
      final f = makeField((f) => f.maskNCM());
      f.value = '1234';
      expect(f.value, '1234');
    });

    test('partial: 5 digits adds first dot', () {
      final f = makeField((f) => f.maskNCM());
      f.value = '12345';
      expect(f.value, '1234.5');
    });

    test('caps at 8 digits', () {
      final f = makeField((f) => f.maskNCM());
      f.value = '123456789';
      expect(f.value, '1234.56.78');
    });

    test('json strips dots', () {
      final f = makeField((f) => f.maskNCM());
      f.value = '12345678';
      expect(f.jsonValue, '12345678');
    });
  });

  // ---------------------------------------------------------------------------
  // maskNUP
  // ---------------------------------------------------------------------------
  group('maskNUP', () {
    test('formats 20 digits as XXXXXXX-XX.XXXX.X.XX.XXXX', () {
      final f = makeField((f) => f.maskNUP());
      f.value = '12345678901234567890';
      expect(f.value, '1234567-89.0123.4.56.7890');
    });

    test('partial before first separator', () {
      final f = makeField((f) => f.maskNUP());
      f.value = '1234567';
      expect(f.value, '1234567');
    });

    test('partial after first separator', () {
      final f = makeField((f) => f.maskNUP());
      f.value = '12345678';
      expect(f.value, '1234567-8');
    });

    test('caps at 20 digits', () {
      final f = makeField((f) => f.maskNUP());
      f.value = '123456789012345678901';
      expect(f.value, '1234567-89.0123.4.56.7890');
    });

    test('json strips separators', () {
      final f = makeField((f) => f.maskNUP());
      f.value = '12345678901234567890';
      expect(f.jsonValue, '12345678901234567890');
    });
  });

  // ---------------------------------------------------------------------------
  // maskPeso
  // ---------------------------------------------------------------------------
  group('maskPeso', () {
    test('single digit gives 0,d', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '8';
      expect(f.value, '0,8');
    });

    test('multiple digits: last is decimal', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '1038';
      expect(f.value, '103,8');
    });

    test('two digits: single integer + decimal', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '38';
      expect(f.value, '3,8');
    });

    test('no thousands separator', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '10000';
      expect(f.value, '1000,0');
    });

    test('empty input clears value', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '8';
      f.value = '';
      expect(f.value, '');
    });

    test('json converts comma to dot', () {
      final f = makeField((f) => f.maskPeso());
      f.value = '1038';
      expect(f.jsonValue, '103.8');
    });
  });

  // ---------------------------------------------------------------------------
  // maskPlacaVeiculo
  // ---------------------------------------------------------------------------
  group('maskPlacaVeiculo', () {
    test('formats 7 chars as XXX-XXXX', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC1234';
      expect(f.value, 'ABC-1234');
    });

    test('Mercosul format', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC1D23';
      expect(f.value, 'ABC-1D23');
    });

    test('converts to uppercase', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'abc1234';
      expect(f.value, 'ABC-1234');
    });

    test('strips special chars', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC-1234';
      expect(f.value, 'ABC-1234');
    });

    test('partial: 3 chars no dash', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC';
      expect(f.value, 'ABC');
    });

    test('partial: 4 chars adds dash', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC1';
      expect(f.value, 'ABC-1');
    });

    test('caps at 7 alphanumeric chars', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'ABC12345';
      expect(f.value, 'ABC-1234');
    });

    test('json strips dash and uppercases', () {
      final f = makeField((f) => f.maskPlacaVeiculo());
      f.value = 'abc1234';
      expect(f.jsonValue, 'ABC1234');
    });
  });

  // ---------------------------------------------------------------------------
  // maskReal
  // ---------------------------------------------------------------------------
  group('maskReal', () {
    test('formats with dot as thousands separator', () {
      final f = makeField((f) => f.maskReal());
      f.value = '1234567890';
      expect(f.value, '1.234.567.890');
    });

    test('small numbers without separator', () {
      final f = makeField((f) => f.maskReal());
      f.value = '999';
      expect(f.value, '999');
    });

    test('4 digits adds one separator', () {
      final f = makeField((f) => f.maskReal());
      f.value = '1234';
      expect(f.value, '1.234');
    });

    test('leading zeros stripped', () {
      final f = makeField((f) => f.maskReal());
      f.value = '001234';
      expect(f.value, '1.234');
    });

    test('empty input clears value', () {
      final f = makeField((f) => f.maskReal());
      f.value = '1234';
      f.value = '';
      expect(f.value, '');
    });

    test('json strips dots', () {
      final f = makeField((f) => f.maskReal());
      f.value = '1234567';
      expect(f.jsonValue, '1234567');
    });
  });

  // ---------------------------------------------------------------------------
  // maskCelular
  // ---------------------------------------------------------------------------
  group('maskCelular', () {
    test('formats 11 digits as (99) 99999-9999', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '11987654321';
      expect(f.value, '(11) 98765-4321');
    });

    test('partial: 1 digit adds opening paren', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '1';
      expect(f.value, '(1');
    });

    test('partial: 2 digits closes area code', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '11';
      expect(f.value, '(11) ');
    });

    test('partial: 7 digits adds trailing dash', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '1198765';
      expect(f.value, '(11) 98765-');
    });

    test('caps at 11 digits', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '119876543210';
      expect(f.value, '(11) 98765-4321');
    });

    test('json strips all separators', () {
      final f = makeField((f) => f.maskCelular());
      f.value = '11987654321';
      expect(f.jsonValue, '11987654321');
    });
  });

  // ---------------------------------------------------------------------------
  // maskTemperatura
  // ---------------------------------------------------------------------------
  group('maskTemperatura', () {
    test('single digit gives 0,d', () {
      final f = makeField((f) => f.maskTemperatura());
      f.value = '8';
      expect(f.value, '0,8');
    });

    test('multiple digits: last is decimal', () {
      final f = makeField((f) => f.maskTemperatura());
      f.value = '108';
      expect(f.value, '10,8');
    });

    test('no thousands separator', () {
      final f = makeField((f) => f.maskTemperatura());
      f.value = '10000';
      expect(f.value, '1000,0');
    });

    test('empty input clears value', () {
      final f = makeField((f) => f.maskTemperatura());
      f.value = '8';
      f.value = '';
      expect(f.value, '');
    });

    test('json converts comma to dot', () {
      final f = makeField((f) => f.maskTemperatura());
      f.value = '108';
      expect(f.jsonValue, '10.8');
    });
  });

  // ---------------------------------------------------------------------------
  // maskValidade
  // ---------------------------------------------------------------------------
  group('maskValidade', () {
    test('MM/AA (maxLength 4): formats 4 digits as MM/AA', () {
      final f = makeField((f) => f.maskValidade());
      f.value = '1225';
      expect(f.value, '12/25');
    });

    test('MM/AAAA (maxLength 6): formats 6 digits as MM/AAAA', () {
      final f = makeField((f) => f.maskValidade(maxLength: 6));
      f.value = '122025';
      expect(f.value, '12/2025');
    });

    test('caps at maxLength digits', () {
      final f = makeField((f) => f.maskValidade());
      f.value = '12253';
      expect(f.value, '12/25');
    });

    test('partial: 2 digits no slash', () {
      final f = makeField((f) => f.maskValidade());
      f.value = '12';
      expect(f.value, '12');
    });

    test('partial: 3 digits adds slash', () {
      final f = makeField((f) => f.maskValidade());
      f.value = '122';
      expect(f.value, '12/2');
    });

    test('json strips slash', () {
      final f = makeField((f) => f.maskValidade());
      f.value = '1225';
      expect(f.jsonValue, '1225');
    });
  });
}
