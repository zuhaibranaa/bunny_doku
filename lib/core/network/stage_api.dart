import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/release_config.dart';

/// Fetches stage packs from a remote endpoint with local asset fallback.
class StageApi {
  final http.Client client;

  StageApi({http.Client? client}) : client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> fetchStagePack() async {
    // Try remote endpoint first
    try {
      final uri = Uri.parse('${ReleaseConfig.stagePackBaseUrl}/v${ReleaseConfig.contentVersion}.json');
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Remote unavailable, fall through to local fallback
    }

    // Fallback: load stages from bundled assets
    final manifest = await rootBundle.loadString(
      'assets/stages/stage_pack_v1.json',
    );
    final List<dynamic> data = jsonDecode(manifest) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Service for checking remote config version.
  /// Returns null if remote is unavailable (falls back to local content version).
  static Future<int?> checkContentVersion(StageApi api) async {
    try {
      final uri = Uri.parse('${ReleaseConfig.stagePackBaseUrl}/version.json');
      final response = await api.client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['contentVersion'] as int?;
      }
    } catch (_) {
      // Remote unavailable — use local content version
    }
    return ReleaseConfig.contentVersion;
  }
}
