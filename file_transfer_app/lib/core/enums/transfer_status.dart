enum TransferStatus {
  queued,
  preparing,
  running,
  paused,
  completed,
  failed,
  cancelled,
  verifying,
  verified,
  integrityFailed,
}

enum TransferType {
  upload,
  download,
}
