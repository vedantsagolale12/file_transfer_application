import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_transfer_app/core/error/app_exception.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only log method + URL, never body content
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }

  AppException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Request timed out. Check your network connection.',
          originalError: err,
        );
      case DioExceptionType.connectionError:
        if (err.error is SocketException) {
          final socketErr = err.error as SocketException;
          if (socketErr.message.contains('Connection refused') ||
              socketErr.osError?.errorCode == 111) {
            return ConnectionRefusedException(
              message:
                  'Unable to connect to the PC. Make sure the PC server is running and both devices are connected to the same network.',
              originalError: err,
            );
          }
        }
        return NoNetworkException(originalError: err);
      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response?.statusCode, err);
      case DioExceptionType.cancel:
        return AppException(message: 'Request cancelled', originalError: err);
      default:
        return NetworkException(
          message: 'An unexpected error occurred.',
          originalError: err,
        );
    }
  }

  AppException _mapStatusCode(int? statusCode, DioException err) {
    switch (statusCode) {
      case 400:
        return NetworkException(
          message: 'Bad request. Please check your input.',
          statusCode: 400,
          originalError: err,
        );
      case 404:
        return FileNotFoundException(originalError: err);
      case 409:
        return TransferOutOfSyncException(originalError: err);
      case 413:
        return FileTooLargeException(originalError: err);
      case 416:
        return TransferOutOfSyncException(
          message: 'Transfer range not satisfiable.',
          originalError: err,
        );
      case 429:
        return NetworkException(
          message: 'Too many requests. Please wait a moment and try again.',
          statusCode: 429,
          originalError: err,
        );
      case 500:
        return NetworkException(
          message: 'Server error. Please try again later.',
          statusCode: 500,
          originalError: err,
        );
      case 503:
        return NetworkException(
          message: 'Server is temporarily unavailable. Please try again later.',
          statusCode: 503,
          originalError: err,
        );
      default:
        return NetworkException(
          message: 'Network error (status: $statusCode).',
          statusCode: statusCode,
          originalError: err,
        );
    }
  }
}

extension AppExceptionStatusCode on AppException {
  int? get statusCode {
    if (this is NetworkException) return (this as NetworkException).statusCode;
    return null;
  }
}
