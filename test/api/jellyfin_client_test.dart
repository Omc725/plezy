import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plezy/api/jellyfin_client.dart';
import 'package:plezy/api/media_server_interface.dart';

void main() {
  group('JellyfinClient', () {
    test('implements MediaServerInterface', () {
      final client = JellyfinClient();
      expect(client, isA<MediaServerInterface>());
    });

    test('login success parses token and userId correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/Users/AuthenticateByName');
        expect(request.headers['X-Emby-Authorization'], contains('MediaBrowser Client="plezy"'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Username'], 'jfuser');
        expect(body['Pw'], 'pass123');

        return http.Response(
          jsonEncode({
            'AccessToken': 'jf-token-789',
            'User': {'Id': 'user-jf-1', 'Name': 'jfuser'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = JellyfinClient(httpClient: mockClient);
      final result = await client.login('http://jellyfin.local:8096/', 'jfuser', 'pass123');

      expect(result, isTrue);
      expect(client.serverUrl, 'http://jellyfin.local:8096');
      expect(client.token, 'jf-token-789');
      expect(client.userId, 'user-jf-1');
    });

    test('getStreamUrl generates valid stream URL when authenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'AccessToken': 'token-jf', 'User': {'Id': 'user-1'}}),
          200,
        );
      });

      final client = JellyfinClient(httpClient: mockClient);
      await client.login('http://jellyfin.local:8096', 'user', 'pass');

      final streamUrl = client.getStreamUrl('item-jf-10');
      expect(streamUrl, 'http://jellyfin.local:8096/Videos/item-jf-10/stream?static=true&api_key=token-jf');
    });
  });
}
