import 'package:equatable/equatable.dart';
import 'package:file_transfer_app/core/enums/transfer_status.dart';

class TransferTask extends Equatable {
  final String id;
  final String fileName;
  final String? localPath;
  final String? serverFileId;
  final String? uploadId;
  final int totalBytes;
  final int transferredBytes;
  final TransferType type;
  final TransferStatus status;
  final double speed;
  final int? estimatedSecondsRemaining;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool checksumVerified;

  const TransferTask({
    required this.id,
    required this.fileName,
    this.localPath,
    this.serverFileId,
    this.uploadId,
    required this.totalBytes,
    this.transferredBytes = 0,
    required this.type,
    this.status = TransferStatus.queued,
    this.speed = 0.0,
    this.estimatedSecondsRemaining,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.checksumVerified = false,
  });

  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0.0;

  TransferTask copyWith({
    String? id,
    String? fileName,
    String? localPath,
    String? serverFileId,
    String? uploadId,
    int? totalBytes,
    int? transferredBytes,
    TransferType? type,
    TransferStatus? status,
    double? speed,
    int? estimatedSecondsRemaining,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? checksumVerified,
  }) {
    return TransferTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      serverFileId: serverFileId ?? this.serverFileId,
      uploadId: uploadId ?? this.uploadId,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      type: type ?? this.type,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      estimatedSecondsRemaining:
          estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      checksumVerified: checksumVerified ?? this.checksumVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'localPath': localPath,
        'serverFileId': serverFileId,
        'uploadId': uploadId,
        'totalBytes': totalBytes,
        'transferredBytes': transferredBytes,
        'type': type.name,
        'status': status.name,
        'speed': speed,
        'errorMessage': errorMessage,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'checksumVerified': checksumVerified,
      };

  factory TransferTask.fromJson(Map<String, dynamic> json) => TransferTask(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        localPath: json['localPath'] as String?,
        serverFileId: json['serverFileId'] as String?,
        uploadId: json['uploadId'] as String?,
        totalBytes: json['totalBytes'] as int,
        transferredBytes: json['transferredBytes'] as int? ?? 0,
        type: TransferType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransferType.upload,
        ),
        status: TransferStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TransferStatus.failed,
        ),
        speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
        errorMessage: json['errorMessage'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        completedAt: json['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
            : null,
        checksumVerified: json['checksumVerified'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        fileName,
        localPath,
        serverFileId,
        uploadId,
        totalBytes,
        transferredBytes,
        type,
        status,
        speed,
        estimatedSecondsRemaining,
        errorMessage,
        createdAt,
        completedAt,
        checksumVerified,
      ];
}
