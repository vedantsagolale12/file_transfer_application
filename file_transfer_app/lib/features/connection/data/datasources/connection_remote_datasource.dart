import 'package:dio/dio.dart';
import 'package:file_transfer_app/core/constants/api_constants.dart';
import 'package:file_transfer_app/core/error/app_exception.dart';

abstract class ConnectionRemoteDataSource {
  Future<Map<String, dynamic>> checkHealth(String baseUrl);
}

class ConnectionRemoteDataSourceImpl implements ConnectionRemoteDataSource {
  final Dio dio;

  ConnectionRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> checkHealth(String baseUrl) async {
    try {
      final response = await dio.get(
        ApiConstants.healthUrl(baseUrl),
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw NetworkException(
        message: 'Health check failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(
          message: e.message ?? 'Network error', originalError: e);
    }
  }
}
