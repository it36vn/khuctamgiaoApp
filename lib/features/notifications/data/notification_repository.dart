import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/cache_storage.dart';
import '../../../core/utils/pagination.dart';

class DeviceNotification {
  const DeviceNotification({
    required this.id,
    required this.receiptId,
    required this.title,
    required this.body,
    this.url,
    this.readAt,
    this.receivedAt,
  });

  final Object id;
  final int receiptId;
  final String title;
  final String body;
  final String? url;
  final String? readAt;
  final String? receivedAt;

  factory DeviceNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return DeviceNotification(
      id: json['id'] ?? json['receipt_id'] ?? '',
      receiptId: int.tryParse(json['receipt_id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      url: data is Map ? data['url']?.toString() : json['url']?.toString(),
      readAt: json['read_at']?.toString(),
      receivedAt:
          json['received_at']?.toString() ?? json['sent_at']?.toString(),
    );
  }
}

class NotificationHistoryData {
  const NotificationHistoryData({
    required this.items,
    required this.pagination,
  });

  final List<DeviceNotification> items;
  final Pagination pagination;
}

class NotificationRepository {
  NotificationRepository(this._dio, this._cacheStorage);

  final Dio _dio;
  final CacheStorage _cacheStorage;

  Future<NotificationHistoryData> history({int page = 1}) async {
    try {
      final deviceId = await _cacheStorage.stableDeviceId();
      final response = await _dio.get<dynamic>(
        ApiPaths.deviceNotifications,
        queryParameters: {'device_id': deviceId, 'page': page, 'per_page': 15},
      );
      final body = response.data as Map<String, dynamic>;
      final items = (body['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DeviceNotification.fromJson)
          .toList();
      return NotificationHistoryData(
        items: items,
        pagination: Pagination.fromJson(body['meta'] as Map<String, dynamic>?),
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<void> markRead(int receiptId) async {
    try {
      final deviceId = await _cacheStorage.stableDeviceId();
      await _dio.post<dynamic>(
        ApiPaths.markDeviceNotificationRead(receiptId),
        data: {'device_id': deviceId},
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }
}
