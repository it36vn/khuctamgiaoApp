import '../../../core/utils/pagination.dart';

String? _localized(Map<String, dynamic> json, String key, String? locale) {
  final suffix = locale == 'vi'
      ? '_vi'
      : locale == 'en'
      ? '_en'
      : null;
  final localized = suffix == null ? null : json['$key$suffix'];
  final value = localized?.toString();
  return value == null || value.trim().isEmpty ? null : value;
}

class MediaRef {
  const MediaRef({this.title, this.path, this.url});

  final String? title;
  final String? path;
  final String? url;

  factory MediaRef.fromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return MediaRef(
        title: value['title']?.toString(),
        path: value['path']?.toString(),
        url: value['url']?.toString(),
      );
    }
    if (value is String) return MediaRef(path: value, url: value);
    return const MediaRef();
  }
}

class SiteSettings {
  const SiteSettings({
    required this.siteName,
    this.siteTagline,
    this.brandLogo,
    this.homeBackgroundImage,
    this.contactEmail,
    this.contactPhone,
    this.contactAddress,
    this.socialUrls = const {},
    this.copyrightText,
  });

  final String siteName;
  final String? siteTagline;
  final MediaRef? brandLogo;
  final MediaRef? homeBackgroundImage;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddress;
  final Map<String, String> socialUrls;
  final String? copyrightText;

  factory SiteSettings.fromJson(Map<String, dynamic>? json, {String? locale}) {
    final data = json ?? const <String, dynamic>{};
    final social = <String, String>{};
    for (final key in [
      'facebook_url',
      'twitter_url',
      'instagram_url',
      'linkedin_url',
      'tiktok_url',
      'youtube_url',
    ]) {
      final value = data[key]?.toString() ?? '';
      if (value.isNotEmpty) social[key] = value;
    }
    return SiteSettings(
      siteName:
          _localized(data, 'site_name', locale) ??
          data['site_name']?.toString() ??
          'Khúc Tâm Giao',
      siteTagline:
          _localized(data, 'site_tagline', locale) ??
          data['site_tagline']?.toString(),
      brandLogo: MediaRef.fromJson(data['brand_logo']),
      homeBackgroundImage: MediaRef.fromJson(data['home_background_image']),
      contactEmail: data['contact_email']?.toString(),
      contactPhone: data['contact_phone']?.toString(),
      contactAddress:
          _localized(data, 'contact_address', locale) ??
          data['contact_address']?.toString(),
      socialUrls: social,
      copyrightText: data['copyright_text']?.toString(),
    );
  }
}

class SeoData {
  const SeoData({this.title, this.description, this.keywords});

  final String? title;
  final String? description;
  final String? keywords;

  factory SeoData.fromJson(Map<String, dynamic>? json) {
    return SeoData(
      title: json?['title']?.toString() ?? json?['seo_title']?.toString(),
      description:
          json?['description']?.toString() ??
          json?['seo_description']?.toString(),
      keywords:
          json?['keywords']?.toString() ?? json?['seo_keywords']?.toString(),
    );
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.path,
    required this.title,
    this.excerpt,
    this.bodyHtml,
    this.imageUrl,
    this.detailImageUrl,
    this.raw = const {},
  });

  final Object id;
  final String path;
  final String title;
  final String? excerpt;
  final String? bodyHtml;
  final String? imageUrl;
  final String? detailImageUrl;
  final Map<String, dynamic> raw;

  factory ContentItem.fromJson(Map<String, dynamic> json, {String? locale}) {
    final id = json['id'] ?? json['path'] ?? json['title'] ?? '';
    return ContentItem(
      id: id,
      path:
          _localized(json, 'path', locale) ??
          json['path']?.toString() ??
          json['slug']?.toString() ??
          id.toString(),
      title:
          _localized(json, 'title', locale) ??
          _localized(json, 'name', locale) ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          (locale == 'vi' ? 'Chưa có tiêu đề' : 'Untitled'),
      excerpt:
          _localized(json, 'excerpt', locale) ??
          _localized(json, 'description', locale) ??
          json['excerpt']?.toString() ??
          json['description']?.toString(),
      bodyHtml:
          _localized(json, 'body_html', locale) ??
          _localized(json, 'content', locale) ??
          json['body_html']?.toString() ??
          json['content']?.toString(),
      imageUrl:
          json['image_url']?.toString() ?? MediaRef.fromJson(json['image']).url,
      detailImageUrl:
          json['detail_image_url']?.toString() ??
          MediaRef.fromJson(json['detail_image']).url,
      raw: json,
    );
  }
}

class HomeData {
  const HomeData({
    required this.settings,
    this.seo = const SeoData(),
    this.services = const [],
    this.blogPosts = const [],
    this.teamMembers = const [],
    this.testimonials = const [],
    this.weddingStories = const [],
  });

  final SiteSettings settings;
  final SeoData seo;
  final List<ContentItem> services;
  final List<ContentItem> blogPosts;
  final List<ContentItem> teamMembers;
  final List<ContentItem> testimonials;
  final List<ContentItem> weddingStories;

  factory HomeData.fromJson(Map<String, dynamic> json, {String? locale}) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    List<ContentItem> list(String key) => (data[key] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => ContentItem.fromJson(item, locale: locale))
        .toList();
    return HomeData(
      settings: SiteSettings.fromJson(
        (json['settings'] ?? data['settings']) as Map<String, dynamic>?,
        locale: locale,
      ),
      seo: SeoData.fromJson(json['seo'] as Map<String, dynamic>?),
      services: list('services'),
      blogPosts: list('blog_posts'),
      teamMembers: list('team_members'),
      testimonials: list('testimonials'),
      weddingStories: list('wedding_stories'),
    );
  }
}

class ContentListData {
  const ContentListData({required this.items, required this.pagination});

  final List<ContentItem> items;
  final Pagination pagination;
}

class ContentDetailData {
  const ContentDetailData({
    required this.item,
    this.settings,
    this.seo = const SeoData(),
  });

  final ContentItem item;
  final SiteSettings? settings;
  final SeoData seo;
}
