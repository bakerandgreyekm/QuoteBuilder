import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl =
    'https://script.google.com/macros/s/AKfycbxoCHIER3sSNuYnYhCDliyfICpgnVs-sfmb26xPdAGE49PkIJTT8AJKn9ckH8YZY60CZg/exec';
const String _apiKey = 'BG_QUOTE_2026';

class SheetsException implements Exception {
  final String message;
  SheetsException(this.message);
  @override
  String toString() => message;
}

class SheetsService {
  Future<List<Map<String, dynamic>>> _get(
    String action, [
    Map<String, String>? extra,
  ]) async {
    final params = {'key': _apiKey, 'action': action, ...?extra};
    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    try {
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        throw SheetsException(body['error']?.toString() ?? 'Unknown error');
      }
      return (body['data'] as List).cast<Map<String, dynamic>>();
    } on SheetsException {
      rethrow;
    } catch (e) {
      throw SheetsException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> payload) async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({...payload, 'key': _apiKey}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        throw SheetsException(body['error']?.toString() ?? 'Unknown error');
      }
      return body;
    } on SheetsException {
      rethrow;
    } catch (e) {
      throw SheetsException('Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjects() => _get('getProjects');

  Future<List<String>> getSystemTypes() async {
    final rows = await _get('getSystemTypes');
    return rows
        .map((r) => r['System Type']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<Map<String, List<String>>> getSystemTypeTags() async {
    final rows = await _get('getSystemTypes');
    final result = <String, List<String>>{};
    for (final r in rows) {
      final systemType = r['System Type']?.toString() ?? '';
      final tags = r['Tags']?.toString() ?? '';
      if (systemType.isNotEmpty) {
        result[systemType] = tags.isEmpty
            ? []
            : tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }
    return result;
  }

  Future<Map<String, List<String>>> getSystemTypeIndustries() async {
    final rows = await _get('getSystemTypes');
    final result = <String, List<String>>{};
    for (final r in rows) {
      final systemType = r['System Type']?.toString() ?? '';
      final industries = r['Industry']?.toString() ?? '';
      if (systemType.isNotEmpty) {
        result[systemType] = industries.isEmpty
            ? []
            : industries.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }
    return result;
  }

  Future<List<String>> getEmployees() async {
    final rows = await _get('getEmployees');
    return rows
        .map((r) => r['Names']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCatalogue() => _get('getCatalogue');

  Future<List<Map<String, dynamic>>> getCatalogueByCategory(String category) =>
      _get('getCatalogueByCategory', {'category': category});

  Future<List<Map<String, dynamic>>> getLineItems(String refNumber) =>
      _get('getLineItems', {'refNumber': refNumber});

  Future<List<String>> getSystems(String refNumber) async {
    final rows = await _get('getSystems', {'refNumber': refNumber});
    return rows
        .map((r) =>
            r['System Type']?.toString() ??
            r['systemType']?.toString() ??
            '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<String> createProject({
    required String projectName,
    required String clientName,
    required String location,
    required String worker,
    String? industry,
    String? tier,
  }) async {
    final result = await _post({
      'action': 'createProject',
      'projectName': projectName,
      'clientName': clientName,
      'location': location,
      'worker': worker,
      'industry': industry ?? '',
      'tier': tier ?? '',
    });
    return result['refNumber'] as String;
  }

  Future<String> addLineItem({
    required String refNumber,
    required String systemType,
    required String category,
    required String productName,
    required String brand,
    required String unit,
    required int quantity,
    required double rate,
    required String noteText,
    required String worker,
    String? area,
  }) async {
    final result = await _post({
      'action': 'addLineItem',
      'refNumber': refNumber,
      'systemType': systemType,
      'category': category,
      'productName': productName,
      'brand': brand,
      'unit': unit,
      'quantity': quantity,
      'rate': rate,
      'noteText': noteText,
      'worker': worker,
      'area': area ?? '',
    });
    return result['id'] as String;
  }

  Future<void> updateProjectAreas({
    required String refNumber,
    required List<String> areas,
  }) async {
    await _post({
      'action': 'updateProjectAreas',
      'refNumber': refNumber,
      'areas': areas.join(','),
    });
  }

  Future<void> updateLineItem({
    required String refNumber,
    required String itemId,
    required int quantity,
    required String noteText,
    String? area,
    double? rate,
  }) async {
    final payload = <String, dynamic>{
      'action': 'updateLineItem',
      'refNumber': refNumber,
      'itemId': itemId,
      'quantity': quantity,
      'noteText': noteText,
      'area': area ?? '',
    };
    if (rate != null) payload['rate'] = rate;
    await _post(payload);
  }

  Future<void> deleteLineItem({
    required String refNumber,
    required String itemId,
  }) async {
    await _post({
      'action': 'deleteLineItem',
      'refNumber': refNumber,
      'itemId': itemId,
    });
  }

  Future<void> addSystem({
    required String refNumber,
    required String systemType,
  }) async {
    await _post({
      'action': 'addSystem',
      'refNumber': refNumber,
      'systemType': systemType,
    });
  }

  Future<void> removeSystem({
    required String refNumber,
    required String systemType,
  }) async {
    await _post({
      'action': 'removeSystem',
      'refNumber': refNumber,
      'systemType': systemType,
    });
  }

  Future<void> updateProject({
    required String refNumber,
    required String projectName,
    required String clientName,
    required String location,
    String? industry,
    String? tier,
  }) async {
    await _post({
      'action': 'updateProject',
      'refNumber': refNumber,
      'projectName': projectName,
      'clientName': clientName,
      'location': location,
      'industry': industry ?? '',
      'tier': tier ?? '',
    });
  }

  Future<void> deleteProject({required String refNumber}) async {
    await _post({
      'action': 'deleteProject',
      'refNumber': refNumber,
    });
  }
}
