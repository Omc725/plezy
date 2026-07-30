import 'dart:convert';
import 'package:http/http.dart' as http;
import 'media_server_interface.dart';

class EmbyClient implements MediaServerInterface {
  String? _token;
  String? _serverUrl;
  String? _userId;

  // Emby'nin zorunlu tuttuğu kimlik doğrulama başlık parametreleri
  final String _deviceId;
  final String _clientName;
  final String _version;
  final http.Client _httpClient;

  EmbyClient({
    http.Client? httpClient,
    String deviceId = "plezy-custom-id",
    String clientName = "plezy",
    String version = "1.0.0",
  })  : _httpClient = httpClient ?? http.Client(),
        _deviceId = deviceId,
        _clientName = clientName,
        _version = version;

  @override
  String? get token => _token;

  @override
  String? get serverUrl => _serverUrl;

  @override
  String? get userId => _userId;

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Emby-Authorization':
          'MediaBrowser Client="$_clientName", Device="Mobile", DeviceId="$_deviceId", Version="$_version"',
      if (_token != null) 'X-Emby-Token': _token!,
    };
  }

  @override
  Future<bool> login(String url, String username, String password) async {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_serverUrl/Users/AuthenticateByName'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'Username': username,
          'Pw': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['AccessToken'] as String?;
        if (data.containsKey('User') && data['User'] is Map) {
          _userId = (data['User'] as Map<String, dynamic>)['Id'] as String?;
        } else if (data.containsKey('Id')) {
          _userId = data['Id'] as String?;
        }
        return _token != null && _token!.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  String getStreamUrl(String itemId) {
    if (_serverUrl == null || _token == null) return '';
    return '$_serverUrl/Videos/$itemId/stream?static=true&api_key=$_token';
  }

  @override
  Future<List<Map<String, dynamic>>> getItems({String? parentId, String? includeItemTypes}) async {
    if (_serverUrl == null || _token == null) return [];

    final queryParams = <String, String>{
      'api_key': _token!,
      if (parentId != null) 'ParentId': parentId,
      if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes,
    };

    final uri = Uri.parse('$_serverUrl/Items').replace(queryParameters: queryParams);
    try {
      final response = await _httpClient.get(uri, headers: _buildHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['Items'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getPlaybackInfo(String itemId) async {
    if (_serverUrl == null || _token == null) return null;

    final queryParams = <String, String>{
      'api_key': _token!,
      if (_userId != null) 'UserId': _userId!,
    };

    final uri = Uri.parse('$_serverUrl/Items/$itemId/PlaybackInfo').replace(queryParameters: queryParams);
    try {
      final response = await _httpClient.post(uri, headers: _buildHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

