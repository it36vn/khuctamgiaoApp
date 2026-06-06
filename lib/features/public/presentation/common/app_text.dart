import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../public_cubits.dart';

extension AppTextX on BuildContext {
  AppText get localize => AppText(watch<LocaleCubit>().state);
  AppText get localizeCallback => AppText(read<LocaleCubit>().state);
}

class AppText {
  const AppText(this.locale);

  final String locale;

  static AppText read(BuildContext context) {
    return AppText(context.read<LocaleCubit>().state);
  }

  static AppText watch(BuildContext context) {
    return AppText(context.watch<LocaleCubit>().state);
  }

  bool get isVi => locale == 'vi';

  String get home => isVi ? 'Trang chủ' : 'Home';
  String get services => isVi ? 'Dịch vụ' : 'Services';
  String get blog => isVi ? 'Blog' : 'Blog';
  String get journal => isVi ? 'Nhật ký' : 'Journal';
  String get stories => isVi ? 'Câu chuyện' : 'Stories';
  String get weddingStories => isVi ? 'Câu chuyện cưới' : 'Wedding stories';
  String get planner => isVi ? 'Planner' : 'Planner';
  String get testimonials => isVi ? 'Cảm nhận' : 'Testimonials';
  String get settings => isVi ? 'Cài đặt' : 'Settings';
  String get search => isVi ? 'Tìm kiếm' : 'Search';
  String get notifications => isVi ? 'Thông báo' : 'Notifications';
  String get reminders => isVi ? 'Đặt nhắc nhở' : 'Reminders';
  String get reminderList => isVi ? 'Danh sách nhắc nhở' : 'Reminder list';
  String get addReminder => isVi ? 'Thêm nhắc nhở' : 'Add reminder';
  String get editReminder => isVi ? 'Sửa nhắc nhở' : 'Edit reminder';
  String get reminderDetail => isVi ? 'Chi tiết nhắc nhở' : 'Reminder detail';
  String get upcomingReminders => isVi ? 'Sắp đến' : 'Upcoming';
  String get pastReminders => isVi ? 'Quá khứ' : 'Past';
  String get noReminders =>
      isVi ? 'Bạn chưa có nhắc nhở nào.' : 'You do not have reminders yet.';
  String get reminderNotFound =>
      isVi ? 'Không tìm thấy nhắc nhở.' : 'Reminder not found.';
  String get reminderTitle => isVi ? 'Tiêu đề' : 'Title';
  String get reminderContent => isVi ? 'Nội dung' : 'Content';
  String get reminderTime => isVi ? 'Thời gian nhắc' : 'Reminder time';
  String get importance => isVi ? 'Mức độ quan trọng' : 'Importance';
  String get reminderTimeMustBeFuture => isVi
      ? 'Thời gian phải lớn hơn hiện tại ít nhất 1 phút.'
      : 'Reminder time must be at least 1 minute in the future.';
  String get detail => isVi ? 'Chi tiết' : 'Detail';
  String get back => isVi ? 'Quay lại' : 'Back';
  String get favorite => isVi ? 'Yêu thích' : 'Favorite';
  String get unfavorite => isVi ? 'Bỏ yêu thích' : 'Unfavorite';
  String get share => isVi ? 'Chia sẻ' : 'Share';
  String get edit => isVi ? 'Sửa' : 'Edit';
  String get delete => isVi ? 'Xoá' : 'Delete';
  String get save => isVi ? 'Lưu' : 'Save';
  String get cancel => isVi ? 'Huỷ' : 'Cancel';
  String get deleteReminder => isVi ? 'Xoá nhắc nhở?' : 'Delete reminder?';
  String get requiredField =>
      isVi ? 'Vui lòng nhập thông tin này.' : 'This field is required.';
  String get retry => isVi ? 'Thử lại' : 'Retry';
  String get noResults => isVi ? 'Không tìm thấy kết quả' : 'No results found';
  String get noNotifications => isVi
      ? 'Bạn chưa có thông báo nào.'
      : 'You do not have notifications yet.';
  String get notificationsEnabled =>
      isVi ? 'Đã bật trên thiết bị này' : 'Enabled on this device';
  String get notificationsDisabled =>
      isVi ? 'Đã tắt trên thiết bị này' : 'Disabled on this device';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get contact => isVi ? 'Liên hệ' : 'Contact';
  String get contactInfo => isVi ? 'Thông tin liên hệ' : 'Contact information';
  String get address => isVi ? 'Địa chỉ' : 'Address';
  String get phone => isVi ? 'Điện thoại' : 'Phone';
  String get email => 'Email';
  String get selectDate => isVi ? 'Chọn ngày' : 'Select date';
  String get selectTime => isVi ? 'Chọn giờ' : 'Select time';
  String get select => isVi ? 'Chọn' : 'Select';
  String get versionInfo =>
      isVi ? 'Thông tin phiên bản' : 'Version information';
  String version(String version, String buildNumber) =>
      isVi ? 'v.$version.$buildNumber' : 'v.$version.$buildNumber';
  String get weddingAndEventPlanning => isVi
      ? 'Dịch vụ lập kế hoạch cưới và sự kiện'
      : 'Wedding and event planning';
  String get untitled => isVi ? 'Chưa có tiêu đề' : 'Untitled';

  String routeTitle(String key) {
    return switch (key) {
      'blog' => journal,
      'our-story' => weddingStories,
      'services' => services,
      'planner' => planner,
      'testimonials' => testimonials,
      _ => key.replaceAll('-', ' '),
    };
  }

  String searchSectionTitle(String type) {
    return switch (type) {
      'blog' => journal,
      'our-story' => weddingStories,
      'services' => services,
      'planner' => planner,
      'testimonials' => testimonials,
      _ => type.replaceAll('_', ' ').replaceAll('-', ' '),
    };
  }
}
