import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/cache/local_cache.dart';
import '../core/media_cache/media_url_cache.dart';
import '../core/native/native_permission_service.dart';
import '../core/native/device_identity_service.dart';
import '../core/native/native_push_bridge.dart';
import '../core/native/home_widget_service.dart';
import '../core/security/app_lock_service.dart';
import '../core/security/e2ee_engine.dart';
import '../core/provider/provider_readiness.dart';
import '../core/push/push_coordinator.dart';
import '../core/realtime/realtime_coordinator.dart';
import '../core/settings/app_preferences.dart';
import '../core/sync/sync_coordinator.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/couple/data/couple_repository.dart';
import '../features/discovery/data/discovery_repository.dart';
import '../features/home/data/home_repository.dart';
import '../features/legal/data/legal_repository.dart';
import '../features/location/data/location_repository.dart';
import '../features/media/data/media_repository.dart';
import '../features/memories/data/memory_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/data/push_device_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/security/data/crypto_repository.dart';
import '../features/support/data/support_repository.dart';
import '../features/us/data/advanced_repository.dart';
import '../features/us/data/couple_life_repository.dart';
import '../features/us/data/relationship_tools_repository.dart';
import '../features/us/data/us_repository.dart';
import '../features/us/data/album_local_cache.dart';
import '../features/us/data/calendar_photo_local_cache.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final localCacheProvider = Provider<LocalCache>((ref) => LocalCache());
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) => SyncCoordinator(ref.read(apiClientProvider)));
final realtimeCoordinatorProvider = ChangeNotifierProvider<RealtimeCoordinator>(
  (ref) => RealtimeCoordinator(ref.read(apiClientProvider), ref.read(syncCoordinatorProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider), ref.read(localCacheProvider)),
);
final coupleRepositoryProvider = Provider<CoupleRepository>((ref) => CoupleRepository(ref.read(apiClientProvider)));
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) => DiscoveryRepository(ref.read(apiClientProvider), ref.read(localCacheProvider)));
final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) => CryptoRepository(ref.read(apiClientProvider)));
final legalRepositoryProvider = Provider<LegalRepository>((ref) => LegalRepository(ref.read(apiClientProvider)));
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.read(apiClientProvider), ref.read(localCacheProvider)),
);
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) => MemoryRepository(ref.read(apiClientProvider)));
final mediaRepositoryProvider = Provider<MediaRepository>((ref) => MediaRepository(ref.read(apiClientProvider)));
final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository(ref.read(apiClientProvider)));
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.read(apiClientProvider), ref.read(localCacheProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.read(apiClientProvider)));
final pushDeviceRepositoryProvider = Provider<PushDeviceRepository>((ref) => PushDeviceRepository(ref.read(apiClientProvider)));
final pushCoordinatorProvider = Provider<PushCoordinator>((ref) => PushCoordinator(ref.read(pushDeviceRepositoryProvider)));
final mediaUrlCacheProvider = Provider<MediaUrlCache>((ref) => MediaUrlCache(ref.read(mediaRepositoryProvider)));
final usRepositoryProvider = Provider<UsRepository>((ref) => UsRepository(ref.read(apiClientProvider)));
final coupleLifeRepositoryProvider = Provider<CoupleLifeRepository>((ref) => CoupleLifeRepository(ref.read(apiClientProvider)));
final relationshipToolsRepositoryProvider = Provider<RelationshipToolsRepository>((ref) => RelationshipToolsRepository(ref.read(apiClientProvider)));
final advancedRepositoryProvider = Provider<AdvancedRepository>((ref) => AdvancedRepository(ref.read(apiClientProvider)));
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(apiClientProvider), ref.read(localCacheProvider)),
);
final appPreferencesProvider = ChangeNotifierProvider<AppPreferences>((ref) => AppPreferences());

final nativePermissionServiceProvider = Provider<NativePermissionService>((ref) => NativePermissionService());
final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) => DeviceIdentityService());
final appLockServiceProvider = ChangeNotifierProvider<AppLockService>((ref) => AppLockService());
final e2eeEngineProvider = Provider<E2eeEngine>((ref) => const SecurityReviewRequiredE2eeEngine());
final providerReadinessProvider = Provider<ProviderReadiness>((ref) => const ProviderReadiness());
final nativePushBridgeProvider = Provider<NativePushBridge>((ref) => NativePushBridge(ref.read(pushDeviceRepositoryProvider)));
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService(ref.read(advancedRepositoryProvider)));
final supportRepositoryProvider = Provider<SupportRepository>((ref) => SupportRepository(ref.read(apiClientProvider)));


final albumLocalCacheProvider = Provider<AlbumLocalCache>((ref) => AlbumLocalCache());
final calendarPhotoLocalCacheProvider = Provider<CalendarPhotoLocalCache>((ref) => CalendarPhotoLocalCache());
