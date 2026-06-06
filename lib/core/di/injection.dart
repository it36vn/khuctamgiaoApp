import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/native_notification_bridge.dart';
import '../../features/public/data/public_repository.dart';
import '../../features/reminders/data/reminder_notification_service.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/universal_links/universal_link_bridge.dart';
import '../network/dio_client.dart';
import '../storage/cache_storage.dart';

late final AppDependencies getIt;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final cacheStorage = CacheStorage(prefs);
  final dioClient = DioClient(cacheStorage);

  getIt = AppDependencies(
    cacheStorage: cacheStorage,
    dioClient: dioClient,
    publicRepository: PublicRepository(dioClient.dio),
    notificationRepository: NotificationRepository(dioClient.dio, cacheStorage),
    notificationBridge: NativeNotificationBridge(),
    reminderRepository: ReminderRepository(cacheStorage),
    reminderNotificationService: ReminderNotificationService(),
    universalLinkBridge: UniversalLinkBridge(),
  );
}

class AppDependencies {
  const AppDependencies({
    required this.cacheStorage,
    required this.dioClient,
    required this.publicRepository,
    required this.notificationRepository,
    required this.notificationBridge,
    required this.reminderRepository,
    required this.reminderNotificationService,
    required this.universalLinkBridge,
  });

  final CacheStorage cacheStorage;
  final DioClient dioClient;
  final PublicRepository publicRepository;
  final NotificationRepository notificationRepository;
  final NativeNotificationBridge notificationBridge;
  final ReminderRepository reminderRepository;
  final ReminderNotificationService reminderNotificationService;
  final UniversalLinkBridge universalLinkBridge;
}
