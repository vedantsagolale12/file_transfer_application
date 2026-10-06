import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_transfer_app/core/network/dio_client.dart';
import 'package:file_transfer_app/features/connection/data/datasources/connection_local_datasource.dart';
import 'package:file_transfer_app/features/connection/data/datasources/connection_remote_datasource.dart';
import 'package:file_transfer_app/features/connection/data/repositories/connection_repository_impl.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';
import 'package:file_transfer_app/features/connection/domain/usecases/check_connection_usecase.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/discovery/data/datasources/mdns_discovery_datasource.dart';
import 'package:file_transfer_app/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:file_transfer_app/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:file_transfer_app/features/files/data/datasources/file_remote_datasource.dart';
import 'package:file_transfer_app/features/files/data/repositories/file_repository_impl.dart';
import 'package:file_transfer_app/features/files/domain/repositories/file_repository.dart';
import 'package:file_transfer_app/features/files/domain/usecases/file_usecases.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // Discovery
  sl.registerLazySingleton<MdnsDiscoveryDataSource>(
    () => MdnsDiscoveryDataSourceImpl(),
  );
  sl.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(dataSource: sl()),
  );

  // Connection
  sl.registerLazySingleton<ConnectionRemoteDataSource>(
    () => ConnectionRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ConnectionLocalDataSource>(
    () => ConnectionLocalDataSourceImpl(prefs: sl()),
  );
  sl.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<CheckConnectionUseCase>(
    () => CheckConnectionUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetLastServerUseCase>(
    () => GetLastServerUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveServerUseCase>(
    () => SaveServerUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ClearServerUseCase>(
    () => ClearServerUseCase(repository: sl()),
  );
  sl.registerLazySingleton<ConnectionBloc>(
    () => ConnectionBloc(
      checkConnectionUseCase: sl(),
      getLastServerUseCase: sl(),
      saveServerUseCase: sl(),
      clearServerUseCase: sl(),
    ),
  );

  // Files
  sl.registerLazySingleton<FileRemoteDataSource>(
    () => FileRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<FileRepository>(
    () => FileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<GetFilesUseCase>(
    () => GetFilesUseCase(repository: sl()),
  );
  sl.registerLazySingleton<DeleteFileUseCase>(
    () => DeleteFileUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetChecksumUseCase>(
    () => GetChecksumUseCase(repository: sl()),
  );
  sl.registerLazySingleton<FileBloc>(
    () => FileBloc(
      getFilesUseCase: sl(),
      deleteFileUseCase: sl(),
      getChecksumUseCase: sl(),
      connectionBloc: sl(),
    ),
  );

  // Transfer
  sl.registerLazySingleton<UploadBloc>(
    () => UploadBloc(
      connectionBloc: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<DownloadBloc>(
    () => DownloadBloc(
      connectionBloc: sl(),
      remoteDataSource: sl(),
    ),
  );
}
