import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plezy/api/emby_client.dart';
import 'package:plezy/api/media_server_interface.dart';

void main() {
  group('EmbyClient', () {
    test('implements MediaServerInterface', () {
      final client = EmbyClient();
      expect(client, isA<MediaServerInterface>());
    });

    test('login success parses token and userId correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/Users/AuthenticateByName');
        expect(request.headers['X-Emby-Authorization'], contains('MediaBrowser Client="plezy"'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Username'], 'admin');
        expect(body['Pw'], 'secret');

        return http.Response(
          jsonEncode({
            'AccessToken': 'emby-token-123',
            'User': {'Id': 'user-456', 'Name': 'admin'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = EmbyClient(httpClient: mockClient);
      final result = await client.login('http://emby.local:8096/', 'admin', 'secret');

      expect(result, isTrue);
      expect(client.serverUrl, 'http://emby.local:8096');
      expect(client.token, 'emby-token-123');
      expect(client.userId, 'user-456');
    });

    test('login failure returns false', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final client = EmbyClient(httpClient: mockClient);
      final result = await client.login('http://emby.local:8096', 'wrong', 'pass');

      expect(result, isFalse);
      expect(client.token, isNull);
    });

    test('getStreamUrl generates valid stream URL when authenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'AccessToken': 'token-xyz', 'User': {'Id': 'user-1'}}),
          200,
        );
      });

      final client = EmbyClient(httpClient: mockClient);
      await client.login('http://emby.local:8096', 'user', 'pass');

      final streamUrl = client.getStreamUrl('item-999');
      expect(streamUrl, 'http://emby.local:8096/Videos/item-999/stream?static=true&api_key=token-xyz');
    });

    test('getItems fetches item list using token and headers', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/Users/AuthenticateByName') {
          return http.Response(
            jsonEncode({'AccessToken': 'token-abc', 'User': {'Id': 'user-1'}}),
            200,
          );
        }
        if (request.url.path == '/Items') {
          expect(request.url.queryParameters['api_key'], 'token-abc');
          expect(request.url.queryParameters['ParentId'], 'parent-10');
          expect(request.url.queryParameters['IncludeItemTypes'], 'Movie,Series');
          expect(request.headers['X-Emby-Token'], 'token-abc');

          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': '1', 'Name': 'Movie 1', 'Type': 'Movie'},
                {'Id': '2', 'Name': 'Series 1', 'Type': 'Series'},
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = EmbyClient(httpClient: mockClient);
      await client.login('http://emby.local:8096', 'user', 'pass');

      final items = await client.getItems(parentId: 'parent-10', includeItemTypes: 'Movie,Series');
      expect(items.length, 2);
      expect(items[0]['Name'], 'Movie 1');
      expect(items[1]['Type'], 'Series');
    });

    test('getPlaybackInfo posts request and returns JSON metadata', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/Users/AuthenticateByName') {
          return http.Response(
            jsonEncode({'AccessToken': 'token-abc', 'User': {'Id': 'user-77'}}),
            200,
          );
        }
        if (request.url.path == '/Items/item-55/PlaybackInfo') {
          expect(request.url.queryParameters['api_key'], 'token-abc');
          expect(request.url.queryParameters['UserId'], 'user-77');

          return http.Response(
            jsonEncode({
              'MediaSources': [
                {'Id': 'ms-1', 'Path': '/media/movie.mp4'}
              ],
              'PlaySessionId': 'session-123',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = EmbyClient(httpClient: mockClient);
      await client.login('http://emby.local:8096', 'user', 'pass');

      final playbackInfo = await client.getPlaybackInfo('item-55');
      expect(playbackInfo, isNotNull);
      expect(playbackInfo!['PlaySessionId'], 'session-123');
    });
  });
}
