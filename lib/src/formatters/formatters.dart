import '../core.dart';

String _withThousandSep(String digits, String sep) {
  final b = StringBuffer();
  final n = digits.length;
  for (var i = 0; i < n; i++) {
    if (i > 0 && (n - i) % 3 == 0) b.write(sep);
    b.write(digits[i]);
  }
  return b.toString();
}

extension FormatterStringFieldValidators on Field<String> {
  static final _nonDigitRegex = RegExp(r'[^0-9]');
  static final _nonAlphanumRegex = RegExp(r'[^0-9a-zA-Z]');

  /// Dynamic CPF/CNPJ mask: up to 11 digits → CPF `###.###.###-##`,
  /// 12–14 digits → CNPJ `##.###.###/####-##`.
  Field<String> maskCPFOrCNPJ({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val is String) return val.replaceAll(_nonDigitRegex, '');
        return val;
      });
    }
    onValueChanged = (oldValue, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      String formatted;
      if (clean.length <= 11) {
        final buffer = StringBuffer();
        for (var i = 0; i < clean.length; i++) {
          if (i == 3 || i == 6) buffer.write('.');
          if (i == 9) buffer.write('-');
          buffer.write(clean[i]);
        }
        formatted = buffer.toString();
      } else {
        final limitClean = clean.substring(0, clean.length.clamp(0, 14));
        final buffer = StringBuffer();
        for (var i = 0; i < limitClean.length; i++) {
          if (i == 2 || i == 5) buffer.write('.');
          if (i == 8) buffer.write('/');
          if (i == 12) buffer.write('-');
          buffer.write(limitClean[i]);
        }
        formatted = buffer.toString();
      }
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Height: `1,82` (meters,centimeters — max 3 digits).
  Field<String> maskAltura({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val == null) return null;
        return val.replaceAll(',', '.');
      });
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 3 ? clean.substring(0, 3) : clean;
      final formatted = limited.length <= 1
          ? limited
          : '${limited[0]},${limited.substring(1)}';
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Credit card: `0000 1111 2222 3333` (16 digits, groups of 4).
  Field<String> maskCartaoCredito({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 16 ? clean.substring(0, 16) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Brazilian decimal: `9.999.999.999,00`.
  /// [casasDecimais] sets the number of decimal places (default 2).
  /// JSON value uses dot as decimal separator: `9999999999.00`.
  Field<String> maskDecimal({
    int casasDecimais = 2,
    bool removeMaskOnJson = true,
  }) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val == null) return null;
        return val.replaceAll('.', '').replaceAll(',', '.');
      });
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      if (clean.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      String formatted;
      if (casasDecimais <= 0) {
        final digits = clean.replaceAll(RegExp(r'^0+(?=.)'), '');
        formatted = _withThousandSep(digits.isEmpty ? '0' : digits, '.');
      } else {
        final padded = clean.padLeft(casasDecimais + 1, '0');
        final intRaw = padded.substring(0, padded.length - casasDecimais);
        final decPart = padded.substring(padded.length - casasDecimais);
        final intDigits = intRaw.replaceAll(RegExp(r'^0+(?=.)'), '');
        final intFormatted = _withThousandSep(
          intDigits.isEmpty ? '0' : intDigits,
          '.',
        );
        formatted = '$intFormatted,$decPart';
      }
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// CEP (postal code): `XX.XXX-XXX` when [ponto] is true, `XXXXX-XXX` otherwise.
  Field<String> maskCEP({bool ponto = true, bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 8 ? clean.substring(0, 8) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (ponto && i == 2) buffer.write('.');
        if (i == 5) buffer.write('-');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Birth certificate: `XXXXXX XX XX XXXX X XXXXX XXX XXXXXXX XX` (32 digits).
  Field<String> maskCertidaoNascimento({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 32 ? clean.substring(0, 32) : clean;
      final buffer = StringBuffer();
      const spaceBefore = {6, 8, 10, 14, 15, 20, 23, 30};
      for (var i = 0; i < limited.length; i++) {
        if (spaceBefore.contains(i)) buffer.write(' ');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// CEST: `XX.XXX.XX` (7 digits).
  Field<String> maskCEST({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 7 ? clean.substring(0, 7) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 2 || i == 5) buffer.write('.');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// CNPJ alphanumeric: `XX.XXX.XXX/XXXX-XX` (14 alphanumeric chars, uppercase).
  Field<String> maskCNPJAlfanumerico({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson(
        (val) => val?.replaceAll(_nonAlphanumRegex, '').toUpperCase(),
      );
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonAlphanumRegex, '').toUpperCase();
      final limited = clean.length > 14 ? clean.substring(0, 14) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// CNPJ (numeric): `99.999.999/9999-99`.
  Field<String> maskCNPJ({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 14 ? clean.substring(0, 14) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Phone card: `000 1111 2222 3333` (15 digits: 3 + 4 + 4 + 4).
  Field<String> maskCartaoTelefone({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 15 ? clean.substring(0, 15) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 3 || i == 7 || i == 11) buffer.write(' ');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// CPF: `XXX.XXX.XXX-XX` (11 digits).
  Field<String> maskCPF({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 11 ? clean.substring(0, 11) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 3 || i == 6) buffer.write('.');
        if (i == 9) buffer.write('-');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Date: `DD/MM/YYYY`.
  Field<String> maskData({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 8 ? clean.substring(0, 8) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 2 || i == 4) buffer.write('/');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Time: `HH:mm`. Clamps hour to 0–23 and minute to 0–59.
  Field<String> maskHora({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 4 ? clean.substring(0, 4) : clean;
      if (limited.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      final buffer = StringBuffer();
      final hourStr = limited.length >= 2 ? limited.substring(0, 2) : limited;
      if (limited.length >= 2) {
        final hour = int.tryParse(hourStr) ?? 0;
        buffer.write(hour > 23 ? '23' : hourStr);
      } else {
        buffer.write(hourStr);
      }
      if (limited.length > 2) {
        buffer.write(':');
        final minStr = limited.length >= 4
            ? limited.substring(2, 4)
            : limited.substring(2);
        if (limited.length >= 4) {
          final minute = int.tryParse(minStr) ?? 0;
          buffer.write(minute > 59 ? '59' : minStr);
        } else {
          buffer.write(minStr);
        }
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// IOF rate: `1,234567` (1 integer digit + 6 decimal digits).
  Field<String> maskIOF({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val == null) return null;
        return val.replaceAll(',', '.');
      });
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 7 ? clean.substring(0, 7) : clean;
      if (limited.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      final formatted = limited.length <= 1
          ? limited
          : '${limited[0]},${limited.substring(1)}';
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Kilometers: `000.000` (6 digits with dot after 3rd).
  Field<String> maskKm({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 6 ? clean.substring(0, 6) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 3) buffer.write('.');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// NCM: `XXXX.XX.XX` (8 digits).
  Field<String> maskNCM({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 8 ? clean.substring(0, 8) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 4 || i == 6) buffer.write('.');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// NUP (Numeração Única de Processos): `XXXXXXX-XX.XXXX.X.XX.XXXX` (20 digits).
  Field<String> maskNUP({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 20 ? clean.substring(0, 20) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 7) buffer.write('-');
        if (i == 9 || i == 13 || i == 14 || i == 16) buffer.write('.');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Weight: `103,8` (kg,g — variable integer digits + 1 decimal, no thousands separator).
  Field<String> maskPeso({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val == null) return null;
        return val.replaceAll(',', '.');
      });
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      if (clean.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      final padded = clean.padLeft(2, '0');
      final intRaw = padded.substring(0, padded.length - 1);
      final decDigit = padded[padded.length - 1];
      final intDigits = intRaw.replaceAll(RegExp(r'^0+(?=.)'), '');
      final formatted = '${intDigits.isEmpty ? '0' : intDigits},$decDigit';
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Vehicle plate: `XXX-XXXX` (alphanumeric, uppercase).
  Field<String> maskPlacaVeiculo({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson(
        (val) => val?.replaceAll(_nonAlphanumRegex, '').toUpperCase(),
      );
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonAlphanumRegex, '').toUpperCase();
      final limited = clean.length > 7 ? clean.substring(0, 7) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 3) buffer.write('-');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// BRL integer with thousands separator: `999.999.999.999`.
  Field<String> maskReal({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      if (clean.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      final digits = clean.replaceAll(RegExp(r'^0+(?=.)'), '');
      final formatted = _withThousandSep(digits.isEmpty ? '0' : digits, '.');
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Phone: `(99) 99999-9999` (11 digits).
  Field<String> maskCelular({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > 11 ? clean.substring(0, 11) : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 0) buffer.write('(');
        buffer.write(limited[i]);
        if (i == 1) buffer.write(') ');
        if (i == 6) buffer.write('-');
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Temperature: `10,8` °C (variable integer digits + 1 decimal, no thousands separator).
  Field<String> maskTemperatura({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val == null) return null;
        return val.replaceAll(',', '.');
      });
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      if (clean.isEmpty) {
        if (newValue.isNotEmpty) value = '';
        return;
      }
      final padded = clean.padLeft(2, '0');
      final intRaw = padded.substring(0, padded.length - 1);
      final decDigit = padded[padded.length - 1];
      final intDigits = intRaw.replaceAll(RegExp(r'^0+(?=.)'), '');
      final formatted = '${intDigits.isEmpty ? '0' : intDigits},$decDigit';
      if (newValue != formatted) value = formatted;
    };
    return this;
  }

  /// Card expiry date: `MM/AA` when [maxLength] is 4 (default), `MM/AAAA` when 6.
  Field<String> maskValidade({
    int maxLength = 4,
    bool removeMaskOnJson = true,
  }) {
    assert(
      maxLength == 4 || maxLength == 6,
      'maxLength must be 4 (MM/AA) or 6 (MM/AAAA)',
    );
    if (removeMaskOnJson) {
      transformToJson((val) => val?.replaceAll(_nonDigitRegex, ''));
    }
    onValueChanged = (_, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      final limited = clean.length > maxLength
          ? clean.substring(0, maxLength)
          : clean;
      final buffer = StringBuffer();
      for (var i = 0; i < limited.length; i++) {
        if (i == 2) buffer.write('/');
        buffer.write(limited[i]);
      }
      final formatted = buffer.toString();
      if (newValue != formatted) value = formatted;
    };
    return this;
  }
}
