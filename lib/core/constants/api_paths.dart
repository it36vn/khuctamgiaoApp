class ApiPaths {
  ApiPaths._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://thuongag.com/api/v1',
  );

  static const settings = '/settings';
  static const home = '/home';
  static const search = '/search';
  static const deviceNotifications = '/devices/notifications';

  static String page(String page) => '/pages/$page';
  static String content(String type) => '/content/$type';
  static String contentDetail(String type, String path) =>
      '/content/$type/$path';
  static String markDeviceNotificationRead(int receiptId) =>
      '/devices/notifications/$receiptId/read';
}
