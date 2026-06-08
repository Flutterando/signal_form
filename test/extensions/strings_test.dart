import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('String Validators', () {
    test('notEmpty and isEmpty', () {
      final form = formCtrl(
        () => (
          nonEmptyField: Field<String>('nonEmptyField').notEmpty(),
          emptyField: Field<String>('emptyField').isEmpty(),
        ),
      );

      form.fields.nonEmptyField.value = '';
      expect(form.fields.nonEmptyField.validate(), isFalse);

      form.fields.nonEmptyField.value = 'text';
      expect(form.fields.nonEmptyField.validate(), isTrue);

      form.fields.emptyField.value = 'text';
      expect(form.fields.emptyField.validate(), isFalse);

      form.fields.emptyField.value = '  ';
      expect(form.fields.emptyField.validate(), isTrue);
    });

    test('matchesPattern and validEmail', () {
      final form = formCtrl(
        () => (
          patternField: Field<String>(
            'patternField',
          ).matchesPattern(RegExp(r'^\d+$')),
          emailField: Field<String>('emailField').email(),
        ),
      );

      form.fields.patternField.value = 'abc';
      expect(form.fields.patternField.validate(), isFalse);

      form.fields.patternField.value = '123';
      expect(form.fields.patternField.validate(), isTrue);

      // Invalid emails
      final invalidEmails = [
        'invalid-email',
        'test@example..com',
        'test@.example.com',
        'test@example-.com',
        'test@-example.com',
        'test@example',
      ];
      for (final email in invalidEmails) {
        form.fields.emailField.value = email;
        expect(
          form.fields.emailField.validate(),
          isFalse,
          reason: 'Should reject $email',
        );
      }

      // Valid emails
      final validEmails = [
        'test@example.com',
        'test+alias@example.com',
        'test.alias@example.co.uk',
        'test%alias@example.com',
      ];
      for (final email in validEmails) {
        form.fields.emailField.value = email;
        expect(
          form.fields.emailField.validate(),
          isTrue,
          reason: 'Should accept $email',
        );
      }
    });

    test('mustHaveNumbers and mustHaveSpecialCharacter', () {
      final form = formCtrl(
        () => (
          numField: Field<String>('numField').mustHaveNumbers(),
          specField: Field<String>('specField').mustHaveSpecialCharacter(),
        ),
      );

      form.fields.numField.value = 'abc';
      expect(form.fields.numField.validate(), isFalse);

      form.fields.numField.value = 'abc1';
      expect(form.fields.numField.validate(), isTrue);

      form.fields.specField.value = 'abc';
      expect(form.fields.specField.validate(), isFalse);

      form.fields.specField.value = 'abc!';
      expect(form.fields.specField.validate(), isTrue);
    });

    test('Brazil Validators (CPF, CNPJ, CEP, CPFOrCNPJ, Phones)', () {
      final form = formCtrl(
        () => (
          cpf: Field<String>('cpf').validCPF(),
          cnpj: Field<String>('cnpj').validCNPJ(),
          cep: Field<String>('cep').validCEP(),
          cpfOrCnpj: Field<String>('cpfOrCnpj').validCPFOrCNPJ(),
          phoneBr: Field<String>(
            'phoneBr',
          ).validPhoneBR().mask('(##) #####-####'),
          phoneCcBr: Field<String>('phoneCcBr').validPhoneWithCountryCodeBR(),
        ),
      );

      // CPF test
      form.fields.cpf.value = '11111111111'; // invalid sequence
      expect(form.fields.cpf.validate(), isFalse);
      form.fields.cpf.value = '12345678909'; // mathematically valid
      expect(form.fields.cpf.validate(), isTrue);

      // CNPJ test
      form.fields.cnpj.value = '11111111111111';
      expect(form.fields.cnpj.validate(), isFalse);
      form.fields.cnpj.value = '11222333000181'; // mathematically valid
      expect(form.fields.cnpj.validate(), isTrue);

      // CEP test
      form.fields.cep.value = '123-45';
      expect(form.fields.cep.validate(), isFalse);
      form.fields.cep.value = '12345-678';
      expect(form.fields.cep.validate(), isTrue);

      // CPFOrCNPJ test
      form.fields.cpfOrCnpj.value = '12345';
      expect(form.fields.cpfOrCnpj.validate(), isFalse);
      form.fields.cpfOrCnpj.value = '12345678909';
      expect(form.fields.cpfOrCnpj.validate(), isTrue);
      form.fields.cpfOrCnpj.value = '11222333000181';
      expect(form.fields.cpfOrCnpj.validate(), isTrue);

      // Phones test
      form.fields.phoneBr.value = '1188888888'; // 10 digits
      expect(form.fields.phoneBr.validate(), isFalse);
      form.fields.phoneBr.value = '11987654321'; // 11 digits, index 2 is 9
      expect(form.fields.phoneBr.value, equals('(11) 98765-4321'));
      expect(form.fields.phoneBr.validate(), isTrue);

      form.fields.phoneCcBr.value = '5511888888888'; // index 4 is 8, not 9
      expect(form.fields.phoneCcBr.validate(), isFalse);
      form.fields.phoneCcBr.value = '5511987654321'; // index 4 is 9
      expect(form.fields.phoneCcBr.validate(), isTrue);
    });

    test('maskCPFOrCNPJ', () {
      final form = formCtrl(
        () => (doc: Field<String>('doc').maskCPFOrCNPJ().validCPFOrCNPJ()),
      );

      // CPF mask
      form.fields.doc.value = '12345678909';
      expect(form.fields.doc.value, equals('123.456.789-09'));
      expect(form.fields.doc.validate(), isTrue);

      // CNPJ mask transition
      form.fields.doc.value = '11222333000181';
      expect(form.fields.doc.value, equals('11.222.333/0001-81'));
      expect(form.fields.doc.validate(), isTrue);
      expect(form.fields.doc.jsonValue, equals('11222333000181'));
    });

    test('validCredCard', () {
      final form = formCtrl(
        () => (
          card: Field<String>(
            'card',
          ).validCreditCard().mask('#### #### #### ####'),
        ),
      );

      form.fields.card.value = '1234567890123453'; // invalid luhn
      expect(form.fields.card.validate(), isFalse);

      form.fields.card.value = '4242424242424242'; // valid luhn
      expect(form.fields.card.validate(), isTrue);
      expect(form.fields.card.value, equals('4242 4242 4242 4242'));
    });

    test('hasNoSequentialRepeatedCharacters and hasNoSequentialCharacters', () {
      final form = formCtrl(
        () => (
          repeated: Field<String>(
            'repeated',
          ).hasNoSequentialRepeatedCharacters(maxRepeated: 3),
          sequential: Field<String>(
            'sequential',
          ).hasNoSequentialCharacters(seqLength: 3),
        ),
      );

      form.fields.repeated.value = 'aaab';
      expect(form.fields.repeated.validate(), isFalse);

      form.fields.repeated.value = 'aab';
      expect(form.fields.repeated.validate(), isTrue);

      form.fields.sequential.value = '123';
      expect(form.fields.sequential.validate(), isFalse);

      form.fields.sequential.value = '135';
      expect(form.fields.sequential.validate(), isTrue);
    });
  });

  group('UUID / ID Validators', () {
    test('uuid - any version', () {
      final form = formCtrl(
        () => (field: Field<String>('field').uuid()),
      );

      for (final val in ['not-a-uuid', '12345678-1234-1234', 'xxxxxxxx-xxxx-xxxx-xxxx-zzzzzzzzzzzz']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in [
        '550e8400-e29b-41d4-a716-446655440000',
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
        '00000000-0000-0000-0000-000000000000',
      ]) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('uuidv4', () {
      final form = formCtrl(
        () => (field: Field<String>('field').uuidv4()),
      );

      // v1 - should reject
      form.fields.field.value = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
      expect(form.fields.field.validate(), isFalse);

      // v4 - should accept
      form.fields.field.value = '550e8400-e29b-41d4-a716-446655440000';
      expect(form.fields.field.validate(), isTrue);
    });

    test('uuidv6', () {
      final form = formCtrl(
        () => (field: Field<String>('field').uuidv6()),
      );

      form.fields.field.value = '550e8400-e29b-41d4-a716-446655440000'; // v4
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = '1ec9414c-232a-6370-9b8d-c0e4c4f94c6b';
      expect(form.fields.field.validate(), isTrue);
    });

    test('uuidv7', () {
      final form = formCtrl(
        () => (field: Field<String>('field').uuidv7()),
      );

      form.fields.field.value = '550e8400-e29b-41d4-a716-446655440000'; // v4
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = '0190163d-8694-7000-a24a-a1e0be1d61e1';
      expect(form.fields.field.validate(), isTrue);
    });

    test('guid is alias for uuidv4', () {
      final form = formCtrl(
        () => (field: Field<String>('field').guid()),
      );

      form.fields.field.value = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // v1
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = '550e8400-e29b-41d4-a716-446655440000'; // v4
      expect(form.fields.field.validate(), isTrue);
    });

    test('cuid and cuid2', () {
      final form = formCtrl(
        () => (
          cuidField: Field<String>('cuidField').cuid(),
          cuid2Field: Field<String>('cuid2Field').cuid2(),
        ),
      );

      form.fields.cuidField.value = 'invalid';
      expect(form.fields.cuidField.validate(), isFalse);
      form.fields.cuidField.value = 'cjld2cyuq0000t3rmniod1foy'; // c + 24 alphanum
      expect(form.fields.cuidField.validate(), isTrue);

      form.fields.cuid2Field.value = 'INVALID_STARTS_UPPER';
      expect(form.fields.cuid2Field.validate(), isFalse);
      form.fields.cuid2Field.value = 'tz4a98xxat96iws9zmbrgj3a'; // 24 lowercase alphanum
      expect(form.fields.cuid2Field.validate(), isTrue);
    });

    test('nanoid', () {
      final form = formCtrl(
        () => (field: Field<String>('field').nanoid()),
      );

      form.fields.field.value = 'tooshort';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'V1StGXR8_Z5jdHi6B-myTX'; // 22 chars
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'V1StGXR8_Z5jdHi6B-myT'; // 21 chars
      expect(form.fields.field.validate(), isTrue);
    });

    test('nanoid with custom size', () {
      final form = formCtrl(
        () => (field: Field<String>('field').nanoid(size: 10)),
      );

      form.fields.field.value = 'V1StGXR8_Z5jdHi6B-myT'; // 21 chars
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'V1StGXR8_Z'; // 10 chars
      expect(form.fields.field.validate(), isTrue);
    });

    test('ulid', () {
      final form = formCtrl(
        () => (field: Field<String>('field').ulid()),
      );

      form.fields.field.value = 'TOOSHORT';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = '01ARZ3NDEKTSV4RRFFQ69G5FAI'; // contains I (invalid)
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = '01ARZ3NDEKTSV4RRFFQ69G5FAV'; // 26 valid chars
      expect(form.fields.field.validate(), isTrue);
    });
  });

  group('Date and Time String Validators', () {
    test('date and isoDate (YYYY-MM-DD)', () {
      final form = formCtrl(
        () => (
          dateField: Field<String>('dateField').date(),
          isoDateField: Field<String>('isoDateField').isoDate(),
        ),
      );

      for (final val in ['2024-1-15', '2024-13-01', '2024/01/15', 'not-a-date']) {
        form.fields.dateField.value = val;
        expect(form.fields.dateField.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['2024-01-15', '2000-12-31', '1999-02-28']) {
        form.fields.dateField.value = val;
        expect(form.fields.dateField.validate(), isTrue, reason: 'Should accept $val');
        form.fields.isoDateField.value = val;
        expect(form.fields.isoDateField.validate(), isTrue, reason: 'isoDate alias should also accept $val');
      }
    });

    test('time (HH:mm:ss)', () {
      final form = formCtrl(
        () => (field: Field<String>('field').time()),
      );

      for (final val in ['25:00:00', '12:60:00', '12:30', 'not-time', '12:30:00+00:00']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['14:30:00', '00:00:00', '23:59:59', '12:30:45.123']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('isoTime (HH:mm:ss with optional timezone)', () {
      final form = formCtrl(
        () => (field: Field<String>('field').isoTime()),
      );

      form.fields.field.value = '25:00:00';
      expect(form.fields.field.validate(), isFalse);

      for (final val in ['14:30:00', '14:30:00Z', '14:30:00+05:30', '14:30:00.500Z']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('datetime and isoDatetime (ISO 8601)', () {
      final form = formCtrl(
        () => (
          dtField: Field<String>('dtField').datetime(),
          isoDtField: Field<String>('isoDtField').isoDatetime(),
        ),
      );

      for (final val in ['2024-01-15', 'not-datetime', '2024-01-15 14:30:00']) {
        form.fields.dtField.value = val;
        expect(form.fields.dtField.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in [
        '2024-01-15T14:30:00Z',
        '2024-01-15T14:30:00.123Z',
        '2024-01-15T14:30:00+05:30',
        '2024-01-15T00:00:00',
      ]) {
        form.fields.dtField.value = val;
        expect(form.fields.dtField.validate(), isTrue, reason: 'Should accept $val');
        form.fields.isoDtField.value = val;
        expect(form.fields.isoDtField.validate(), isTrue, reason: 'isoDatetime alias should also accept $val');
      }
    });

    test('isoDuration', () {
      final form = formCtrl(
        () => (field: Field<String>('field').isoDuration()),
      );

      for (final val in ['P', 'PT', '1Y2M', 'not-duration', 'invalid']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['P1D', 'P1Y', 'PT1H30M', 'P1Y2M3DT4H5M6S', 'PT0.5S']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });
  });

  group('Network Validators', () {
    test('httpUrl', () {
      final form = formCtrl(
        () => (field: Field<String>('field').httpUrl()),
      );

      for (final val in ['ftp://example.com', 'example.com', 'not-url', '://missing-scheme.com']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in [
        'https://example.com',
        'http://example.com/path?q=1',
        'https://sub.domain.co.uk/path',
      ]) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('hostname', () {
      final form = formCtrl(
        () => (field: Field<String>('field').hostname()),
      );

      for (final val in ['localhost', '-invalid.com', 'example', '192.168.0.1']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['example.com', 'sub.example.co.uk', 'my-host.example.org']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('ipv4', () {
      final form = formCtrl(
        () => (field: Field<String>('field').ipv4()),
      );

      for (final val in ['256.0.0.1', '192.168.0', 'not-ip', '192.168.0.1.1']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['192.168.0.1', '0.0.0.0', '255.255.255.255', '10.0.0.1']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('ipv6', () {
      final form = formCtrl(
        () => (field: Field<String>('field').ipv6()),
      );

      for (final val in ['not-ipv6', '1:2:3:4:5:6:7:8:9', '2001:db8::1::1']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in [
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        '::1',
        'fe80::1',
        '::',
      ]) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('mac', () {
      final form = formCtrl(
        () => (field: Field<String>('field').mac()),
      );

      for (final val in ['00:1A:2B:3C:4D', 'not-mac', 'GG:1A:2B:3C:4D:5E']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['00:1A:2B:3C:4D:5E', '00-1A-2B-3C-4D-5E', 'ff:ff:ff:ff:ff:ff']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('cidrv4', () {
      final form = formCtrl(
        () => (field: Field<String>('field').cidrv4()),
      );

      for (final val in ['192.168.0.0/33', '192.168.0.0', 'not-cidr', '256.0.0.0/24']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['192.168.0.0/24', '10.0.0.0/8', '0.0.0.0/0', '255.255.255.255/32']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('cidrv6', () {
      final form = formCtrl(
        () => (field: Field<String>('field').cidrv6()),
      );

      for (final val in ['2001:db8::', 'not-cidr', '2001:db8::/129']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['2001:db8::/32', 'fe80::/10', '::/0', '::1/128']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });
  });

  group('Encoding Validators', () {
    test('base64', () {
      final form = formCtrl(
        () => (field: Field<String>('field').base64()),
      );

      for (final val in ['not-base64!', 'SGV', 'hello world', 'YQ']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['SGVsbG8gV29ybGQ=', 'dGVzdA==', 'aGVsbG8=', 'dGVzdA==']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('base64url', () {
      final form = formCtrl(
        () => (field: Field<String>('field').base64url()),
      );

      form.fields.field.value = 'has+plus';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'has/slash';
      expect(form.fields.field.validate(), isFalse);

      for (final val in ['SGVsbG8', 'dGVzdA', 'aGVsbG8-dGVzdA_', 'abc123']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('hex', () {
      final form = formCtrl(
        () => (field: Field<String>('field').hex()),
      );

      for (final val in ['xyz', '0xdeadbeef', 'dead beef', 'GHIJ']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in ['deadbeef', '0123456789abcdef', 'DEADBEEF', 'ABCDEF']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });

    test('jwt', () {
      final form = formCtrl(
        () => (field: Field<String>('field').jwt()),
      );

      for (final val in ['notajwt', 'only.two', 'too.many.dots.here.five']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject $val');
      }

      for (final val in [
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
        'header.payload.signature',
        'aaa.bbb.ccc',
      ]) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept $val');
      }
    });
  });

  group('Misc String Validators', () {
    test('emoji', () {
      final form = formCtrl(
        () => (field: Field<String>('field').emoji()),
      );

      for (final val in ['hello', 'abc', '123', 'no emoji here']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isFalse, reason: 'Should reject "$val" (no emoji)');
      }

      for (final val in ['\u{1F600}', '\u{1F389}test', 'hi\u{1F680}']) {
        form.fields.field.value = val;
        expect(form.fields.field.validate(), isTrue, reason: 'Should accept "$val" (has emoji)');
      }
    });

    test('hash - md5', () {
      final form = formCtrl(
        () => (field: Field<String>('field').hash('md5')),
      );

      form.fields.field.value = 'not_a_hash';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'd41d8cd98f00b204e9800998ecf8427'; // 31 chars
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'd41d8cd98f00b204e9800998ecf8427e'; // 32 hex chars (MD5 of "")
      expect(form.fields.field.validate(), isTrue);
    });

    test('hash - sha256', () {
      final form = formCtrl(
        () => (field: Field<String>('field').hash('sha256')),
      );

      form.fields.field.value = 'd41d8cd98f00b204e9800998ecf8427e'; // MD5 (32 chars)
      expect(form.fields.field.validate(), isFalse);

      // SHA-256 of "" — 64 hex chars
      form.fields.field.value = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      expect(form.fields.field.validate(), isTrue);
    });

    test('hash - sha512', () {
      final form = formCtrl(
        () => (field: Field<String>('field').hash('sha512')),
      );

      form.fields.field.value = 'd41d8cd98f00b204e9800998ecf8427e'; // MD5
      expect(form.fields.field.validate(), isFalse);

      // 128 hex chars
      form.fields.field.value =
          'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce'
          '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e';
      expect(form.fields.field.validate(), isTrue);
    });

    test('uppercase and lowercase', () {
      final form = formCtrl(
        () => (
          upperField: Field<String>('upperField').uppercase(),
          lowerField: Field<String>('lowerField').lowercase(),
        ),
      );

      form.fields.upperField.value = 'Hello';
      expect(form.fields.upperField.validate(), isFalse);
      form.fields.upperField.value = 'hello';
      expect(form.fields.upperField.validate(), isFalse);
      form.fields.upperField.value = 'HELLO';
      expect(form.fields.upperField.validate(), isTrue);
      form.fields.upperField.value = 'HELLO 123';
      expect(form.fields.upperField.validate(), isTrue);

      form.fields.lowerField.value = 'Hello';
      expect(form.fields.lowerField.validate(), isFalse);
      form.fields.lowerField.value = 'HELLO';
      expect(form.fields.lowerField.validate(), isFalse);
      form.fields.lowerField.value = 'hello';
      expect(form.fields.lowerField.validate(), isTrue);
      form.fields.lowerField.value = 'hello 123';
      expect(form.fields.lowerField.validate(), isTrue);
    });
  });
}
