import 'package:dio/dio.dart';
import 'package:file_transfer_app/core/constants/api_constants.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';

abstract class FileRemoteDataSource {
  Future<List<FileEntity>> getFiles(String baseUrl);
  Future<FileEntity> getFileMetadata(String baseUrl, String fileId);
  Future<void> deleteFile(String baseUrl, String fileId);
  Future<String> getChecksum(String baseUrl, String fileId);
  Future<Response> downloadFile(String baseUrl, String fileId,
      {int? startBytes});
  Future<Response> uploadFileMultipart(
      String baseUrl, String filePath, String fileName);
  Future<Map<String, dynamic>> startResumableUpload(
      String baseUrl, String fileName, int totalBytes);
  Future<Map<String, dynamic>> uploadChunk(
      String baseUrl, String uploadId, List<int> chunk, int offset);
  Future<Map<String, dynamic>> getUploadProgress(
      String baseUrl, String uploadId);
  Future<void> cancelUpload(String baseUrl, String uploadId);
}

class FileRemoteDataSourceImpl implements FileRemoteDataSource {
  final Dio dio;

  FileRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<FileEntity>> getFiles(String baseUrl) async {
    final response = await dio.get(ApiConstants.filesUrl(baseUrl));
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => _fileFromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FileEntity> getFileMetadata(String baseUrl, String fileId) async {
    final response = await dio.get(ApiConstants.fileUrl(baseUrl, fileId));
    return _fileFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteFile(String baseUrl, String fileId) async {
    await dio.delete(ApiConstants.fileUrl(baseUrl, fileId));
  }

  @override
  Future<String> getChecksum(String baseUrl, String fileId) async {
    final response =
        await dio.get(ApiConstants.fileChecksumUrl(baseUrl, fileId));
    return (response.data as Map<String, dynamic>)['checksum'] as String;
  }

  @override
  Future<Response> downloadFile(String baseUrl, String fileId,
      {int? startBytes}) async {
    final options = Options(responseType: ResponseType.stream);
    if (startBytes != null && startBytes > 0) {
      options.headers = {'Range': 'bytes=$startBytes-'};
    }
    return dio.get(
      ApiConstants.fileDownloadUrl(baseUrl, fileId),
      options: options,
    );
  }

  @override
  Future<Response> uploadFileMultipart(
      String baseUrl, String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return dio.post(
      ApiConstants.fileUploadUrl(baseUrl),
      data: formData,
    );
  }

  @override
  Future<Map<String, dynamic>> startResumableUpload(
      String baseUrl, String fileName, int totalBytes) async {
    final response = await dio.post(
      '${ApiConstants.uploadsUrl(baseUrl)}?filename=${Uri.encodeComponent(fileName)}&totalBytes=$totalBytes',
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> uploadChunk(
      String baseUrl, String uploadId, List<int> chunk, int offset) async {
    final response = await dio.put(
      ApiConstants.uploadUrl(baseUrl, uploadId),
      data: Stream.fromIterable([chunk]),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': chunk.length,
          'Upload-Offset': offset,
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getUploadProgress(
      String baseUrl, String uploadId) async {
    final response = await dio.get(ApiConstants.uploadUrl(baseUrl, uploadId));
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> cancelUpload(String baseUrl, String uploadId) async {
    await dio.delete(ApiConstants.uploadUrl(baseUrl, uploadId));
  }

  FileEntity _fileFromJson(Map<String, dynamic> json) {
    return FileEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      lastModified:
          DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int),
    );
  }
}
