class ApiConstants {
  ApiConstants._();

  static const String apiPrefix = '/api/v1';
  static const String healthEndpoint = '/api/v1/health';
  static const String filesEndpoint = '/api/v1/files';
  static const String uploadsEndpoint = '/api/v1/uploads';

  static const int defaultPort = 8080;
  static const String defaultProtocol = 'http';
  static const String httpsProtocol = 'https';

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  static const int chunkSize = 5 * 1024 * 1024; // 5 MB
  static const int maxChunkSize = 10 * 1024 * 1024; // 10 MB
  static const int smallFileThreshold = 10 * 1024 * 1024; // 10 MB

  static String baseUrl(String protocol, String host, int port) {
    return '$protocol://$host:$port';
  }

  static String healthUrl(String baseUrl) => '$baseUrl$healthEndpoint';
  static String filesUrl(String baseUrl) => '$baseUrl$filesEndpoint';
  static String fileUrl(String baseUrl, String id) =>
      '$baseUrl$filesEndpoint/$id';
  static String fileDownloadUrl(String baseUrl, String id) =>
      '$baseUrl$filesEndpoint/$id/download';
  static String fileChecksumUrl(String baseUrl, String id) =>
      '$baseUrl$filesEndpoint/$id/checksum';
  static String uploadsUrl(String baseUrl) => '$baseUrl$uploadsEndpoint';
  static String uploadUrl(String baseUrl, String uploadId) =>
      '$baseUrl$uploadsEndpoint/$uploadId';
  static String fileUploadUrl(String baseUrl) =>
      '$baseUrl$filesEndpoint/upload';
}
