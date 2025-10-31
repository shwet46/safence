import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NumlookupResult {
  final String? owner;
  final bool? isSpam;
  final double? spamScore;
  final Map<String, dynamic> raw;

  NumlookupResult({this.owner, this.isSpam, this.spamScore, required this.raw});
}
class NumlookupService {
  static final _base = dotenv.env['NUMLOOKUP_BASE_URL'] ?? 'https://api.numlookupapi.com/v1/validate';
  static final _key = dotenv.env['NUMLOOKUP_KEY'] ?? '';

  static Future<NumlookupResult?> lookup(String number) async {
    if (_key.isEmpty) return null;

    try {
      final baseUri = Uri.parse(_base);
      final path = (baseUri.path.endsWith('/')) ? '${baseUri.path}$number' : '${baseUri.path}/$number';
      final uri = baseUri.replace(path: path, queryParameters: {
        ...baseUri.queryParameters,
        if (_key.isNotEmpty) 'apikey': _key,
      });

      final headers = <String, String>{'Accept': 'application/json'};
      if (_key.isNotEmpty) headers['apikey'] = _key;

      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(resp.body) as Map<String, dynamic>;


      String? owner;
      for (final k in ['owner', 'owner_name', 'name', 'caller_name', 'callerid', 'contact_name']) {
        if (data.containsKey(k) && data[k] is String && (data[k] as String).trim().isNotEmpty) {
          owner = data[k] as String;
          break;
        }
      }

      // Heuristic spam detection from provider fields
      bool? isSpam;
      double? spamScore;
      if (data.containsKey('spam')) {
        final v = data['spam'];
        if (v is bool) isSpam = v;
        if (v is num) isSpam = v > 0;
        if (v is String) isSpam = (v.toLowerCase() == 'true' || int.tryParse(v) != 0);
      }

      if (isSpam == null) {
        // check for score-like fields
        for (final k in ['spam_score', 'fraud_score', 'risk']) {
          if (data.containsKey(k)) {
            final v = data[k];
            final n = v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? -1);
            if (n >= 0) {
              isSpam = n >= 50; // threshold
              spamScore = n;
              break;
            }
          }
        }
      }

      return NumlookupResult(owner: owner, isSpam: isSpam, spamScore: spamScore, raw: data);
    } catch (e) {
      return null;
    }
  }
}
