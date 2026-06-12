import '../models/playlist_model.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

class PlaylistService {
  static Future<void> savePlaylist(Playlist playlist) async {
    await SecureStorageService.instance.saveProviderPassword(
      playlist.id,
      playlist.password,
    );
    await DatabaseService.savePlaylist(_withoutSecret(playlist));
  }

  static Future<List<Playlist>> getPlaylists() async {
    return _hydrateAll(await DatabaseService.getPlaylists());
  }

  static Future<void> deletePlaylist(String id) async {
    await SecureStorageService.instance.deleteProviderPassword(id);
    await DatabaseService.deletePlaylist(id);
  }

  static Future<void> updatePlaylist(Playlist playlist) async {
    await SecureStorageService.instance.saveProviderPassword(
      playlist.id,
      playlist.password,
    );
    await DatabaseService.updatePlaylist(_withoutSecret(playlist));
  }

  static Future<Playlist?> getPlaylistById(String id) async {
    final playlist = await DatabaseService.getPlaylistById(id);
    return playlist == null ? null : _hydrate(playlist);
  }

  static Future<List<Playlist>> getXStreamPlaylists() async {
    return _hydrateAll(await DatabaseService.getPlaylistsByType(PlaylistType.xtream));
  }

  static Future<List<Playlist>> getM3UPlaylists() async {
    return _hydrateAll(await DatabaseService.getPlaylistsByType(PlaylistType.m3u));
  }

  static Playlist _withoutSecret(Playlist playlist) {
    return Playlist(
      id: playlist.id,
      name: playlist.name,
      type: playlist.type,
      url: playlist.url,
      username: playlist.username,
      password: null,
      createdAt: playlist.createdAt,
    );
  }

  static Future<Playlist> _hydrate(Playlist playlist) async {
    final password =
        await SecureStorageService.instance.readProviderPassword(playlist.id);
    return Playlist(
      id: playlist.id,
      name: playlist.name,
      type: playlist.type,
      url: playlist.url,
      username: playlist.username,
      password: password ?? playlist.password,
      createdAt: playlist.createdAt,
    );
  }

  static Future<List<Playlist>> _hydrateAll(List<Playlist> playlists) {
    return Future.wait(playlists.map(_hydrate));
  }
}
