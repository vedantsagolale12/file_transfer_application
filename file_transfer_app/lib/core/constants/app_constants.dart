class AppConstants {
  AppConstants._();

  static const String appName = 'PC File Transfer';
  static const String mdnsServiceType = '_pcfiletransfer._tcp';
  static const String mdnsServiceDomain = 'local';
  static const int mdnsScanDuration = 10; // seconds
  static const int maxConcurrentTransfers = 2;
  static const int retryAttempts = 3;
  static const int retryDelay = 2; // seconds
  static const int healthCheckTimeout = 5; // seconds
}
