import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class NumverifyService {
  static final Map<String, bool> _cache = {};
  static final Map<String, Map<String, dynamic>?> _detailsCache = {};
  static Future<bool> isSpamNumber(String number) async {
    final apiKey = dotenv.env['NUMVERIFY_KEY'] ?? '';
    if (apiKey.isEmpty) return false;

    final norm = _normalize(number);
    if (_cache.containsKey(norm)) return _cache[norm]!;

    try {
      final uri = Uri.parse('https://api.apilayer.com/number_verification/validate')
          .replace(queryParameters: {'number': number});

      final resp = await http.get(uri, headers: {'apikey': apiKey}).timeout(const Duration(seconds: 8));
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

  /// Fetch full JSON details from Numverify (apilayer) for a number.
  /// Returns null on error or when API key is missing.
  static Future<Map<String, dynamic>?> fetchDetails(String number) async {
    final apiKey = dotenv.env['NUMVERIFY_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final norm = _normalize(number);
    if (_detailsCache.containsKey(norm)) return _detailsCache[norm];

    try {
      final uri = Uri.parse('https://api.apilayer.com/number_verification/validate')
          .replace(queryParameters: {'number': number});
      final resp = await http.get(uri, headers: {'apikey': apiKey}).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        _detailsCache[norm] = null;
        return null;
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      _detailsCache[norm] = data;
      return data;
    } catch (e) {
      _detailsCache[norm] = null;
      return null;
    }
  }

  static String _normalize(String number) => number.replaceAll(RegExp(r"[^0-9]"), '');
}
