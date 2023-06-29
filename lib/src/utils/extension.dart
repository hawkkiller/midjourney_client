import 'package:path/path.dart' as p;

extension UriX on String {
  /// Converts a string to a [Uri].
  Uri get uri => Uri.parse(this);

  /// Replaces host in a [Uri].
  String replaceHost(String u) {
    final uri = this.uri;
    final $uri = Uri.parse(u);
    // replace host, but consider that the host can be followed by a path
    return uri
        .replace(
          host: $uri.host,
          port: $uri.port,
          path: p.joinAll(
            [
              $uri.path,
              ...uri.pathSegments,
            ],
          ),
        )
        .toString();
  }
}
