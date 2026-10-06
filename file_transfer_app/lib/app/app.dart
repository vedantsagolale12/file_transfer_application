import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_transfer_app/app/router/app_router.dart';
import 'package:file_transfer_app/app/theme/light_theme.dart';
import 'package:file_transfer_app/app/theme/dark_theme.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_bloc.dart';
import 'package:file_transfer_app/injection_container.dart' as di;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectionBloc>(
          create: (_) => di.sl<ConnectionBloc>(),
        ),
        BlocProvider<FileBloc>(
          create: (_) => di.sl<FileBloc>(),
        ),
        BlocProvider<UploadBloc>(
          create: (_) => di.sl<UploadBloc>(),
        ),
        BlocProvider<DownloadBloc>(
          create: (_) => di.sl<DownloadBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'PC File Transfer',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
