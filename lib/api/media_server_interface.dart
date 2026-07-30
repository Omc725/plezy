abstract class MediaServerInterface {
  Future<bool> login(String url, String username, String password);
  String getStreamUrl(String itemId);
  Future<List<Map<String, dynamic>>> getItems({String? parentId, String? includeItemTypes});
  Future<Map<String, dynamic>?> getPlaybackInfo(String itemId);

  String? get token;
  String? get serverUrl;
  String? get userId;
}

