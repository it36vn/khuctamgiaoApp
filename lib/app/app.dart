import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/notifications/presentation/notification_cubit.dart';
import '../features/public/presentation/public_cubits.dart';
import '../features/reminders/presentation/reminder_cubit.dart';
import '../core/di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class KhucTamGiaoApp extends StatefulWidget {
  const KhucTamGiaoApp({super.key});

  @override
  State<KhucTamGiaoApp> createState() => _KhucTamGiaoAppState();
}

class _KhucTamGiaoAppState extends State<KhucTamGiaoApp> {
  late final LocaleCubit _localeCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _localeCubit = LocaleCubit(getIt.cacheStorage);
    _appRouter = AppRouter();
    getIt.reminderNotificationService.start(_appRouter.router);
    _startNotificationBridge();
    getIt.universalLinkBridge.start(_appRouter.router);
  }

  Future<void> _startNotificationBridge() async {
    if (!getIt.cacheStorage.hasPromptedForNotificationPermission) {
      await getIt.notificationBridge.requestPermission();
      await getIt.cacheStorage.markNotificationPermissionPrompted();
    }
    await getIt.notificationBridge.start(_appRouter.router);
  }

  @override
  void dispose() {
    getIt.notificationBridge.dispose();
    getIt.universalLinkBridge.dispose();
    _localeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _localeCubit),
        BlocProvider(create: (_) => FavoriteContentCubit(getIt.cacheStorage)),
        BlocProvider(
          create: (_) =>
              SettingsCubit(getIt.publicRepository, _localeCubit)..load(),
        ),
        BlocProvider(
          create: (_) => NotificationHistoryCubit(getIt.notificationRepository),
        ),
        BlocProvider(
          create: (_) => ReminderCubit(
            getIt.reminderRepository,
            getIt.reminderNotificationService,
          )..load(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Khúc Tâm Giao',
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('vi', 'VN'),
        ],
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
