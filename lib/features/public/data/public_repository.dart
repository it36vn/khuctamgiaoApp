import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/pagination.dart';
import '../domain/public_models.dart';

class PublicRepository {
  PublicRepository(this._dio);

  final Dio _dio;

  Future<SiteSettings> getSettings(String locale) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.settings,
        queryParameters: {'locale': locale},
      );
      return SiteSettings.fromJson(
        response.data['data'] as Map<String, dynamic>?,
        locale: locale,
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<HomeData> getHome(String locale) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.home,
        queryParameters: {'locale': locale},
      );
      return HomeData.fromJson(
        response.data as Map<String, dynamic>,
        locale: locale,
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<ContentListData> getContentList({
    required String type,
    required String locale,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.content(type),
        queryParameters: {'locale': locale, 'page': page, 'per_page': perPage},
      );
      final body = response.data as Map<String, dynamic>;
      final items = (body['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => ContentItem.fromJson(item, locale: locale))
          .toList();
      return ContentListData(
        items: items,
        pagination: Pagination.fromJson(body['meta'] as Map<String, dynamic>?),
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<ContentDetailData> getContentDetail({
    required String type,
    required String path,
    required String locale,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.contentDetail(type, path),
        queryParameters: {'locale': locale},
      );
      final body = response.data as Map<String, dynamic>;
      return ContentDetailData(
        item: ContentItem.fromJson(
          body['data'] as Map<String, dynamic>,
          locale: locale,
        ),
        seo: SeoData.fromJson(body['seo'] as Map<String, dynamic>?),
        settings: SiteSettings.fromJson(
          body['settings'] as Map<String, dynamic>?,
          locale: locale,
        ),
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<Map<String, List<ContentItem>>> search(
    String query,
    String locale,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.search,
        queryParameters: {'q': query, 'locale': locale},
      );
      final data =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return data.map((key, value) {
        if (value is! List) {
          return MapEntry(key, []);
        }
        final items = (value as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((item) => ContentItem.fromJson(item, locale: locale))
            .toList();
        return MapEntry(key, items);
      });
    } catch (error) {
      throw mapDioFailure(error);
    }
  }
}
