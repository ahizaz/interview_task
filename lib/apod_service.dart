import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apod_model.dart';

class ApodService {
  static const String _apiKey = '18QBwoiRpbFgeYBSl3PxFHi2aoJjrt7lIindJfng';

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Apod> fetchApod(DateTime date) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse('https://api.nasa.gov/planetary/apod?api_key=$_apiKey&date=$dateStr');
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return Apod.fromJson(json);
    }
    throw Exception('API returned status ${resp.statusCode}');
  }
}
