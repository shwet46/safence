import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class NumverifyService {
  static final Map<String, bool> _cache = {};
  static Future<bool> isSpamNumber(String number) async {
    final apiKey = dotenv.env['NUMVERIFY_KEY'] ?? '';
    if (apiKey.isEmpty) return false;

    final norm = _normalize(number);
    if (_cache.containsKey(norm)) return _cache[norm]!;

    try {
      final uri = Uri.parse('http://apilayer.net/api/validate')
          .replace(queryParameters: {
        'access_key': apiKey,
        'number': number,
        'format': '1',
      });

      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        _cache[norm] = false;
        return false;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;

      final valid = data['valid'] == true;
      final lineType = (data['line_type'] as String?)?.toLowerCase();
      final carrier = (data['carrier'] as String?)?.toLowerCase();

      var isSpam = false;
      if (!valid) {
        isSpam = true;
      } else if (lineType == 'voip' || lineType == 'pager' || lineType == 'unknown') {
        isSpam = true;
      } else if (carrier == null || carrier.isEmpty) {
        isSpam = true;
      }

      _cache[norm] = isSpam;
      return isSpam;
    } catch (e) {
      return false;
    }
  }

  static String _normalize(String number) => number.replaceAll(RegExp(r"[^0-9]"), '');
}
