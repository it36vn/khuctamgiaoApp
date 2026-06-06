import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_state.dart';
import '../../domain/public_models.dart';
import '../common/app_text.dart';
import '../public_cubits.dart';

class PublicSettingsScreen extends StatefulWidget {
  const PublicSettingsScreen({super.key});

  @override
  State<PublicSettingsScreen> createState() => _PublicSettingsScreenState();
}

class _PublicSettingsScreenState extends State<PublicSettingsScreen>
    with WidgetsBindingObserver {
  late Future<PackageInfo> _packageInfo;
  bool _notificationsEnabled = false;
  bool _loadingNotificationStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _packageInfo = PackageInfo.fromPlatform().catchError((_) {
      return PackageInfo(
        appName: 'Khúc Tâm Giao',
        packageName: '',
        version: '-',
        buildNumber: '-',
      );
    });
    _loadNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationStatus();
    }
  }

  Future<void> _loadNotificationStatus() async {
    var enabled = false;
    try {
      enabled = await getIt.notificationBridge.areNotificationsEnabled();
    } catch (_) {
      enabled = false;
    }
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loadingNotificationStatus = false;
    });
  }

  Future<void> _openNotificationSettings() async {
    setState(() => _loadingNotificationStatus = true);
    try {
      await getIt.notificationBridge.openNotificationSettings();
    } finally {
      await _loadNotificationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, AsyncState<SiteSettings>>(
      builder: (context, state) {
        final loadedSettings = switch (state) {
          AsyncLoaded<SiteSettings>(:final data) => data,
          AsyncLoading<SiteSettings>(:final previous) => previous,
          AsyncFailure<SiteSettings>(:final previous) => previous,
          _ => null,
        };
        if (loadedSettings == null && state is AsyncLoading<SiteSettings>) {
          return AppSkeleton.settings();
        }
        final settings =
            loadedSettings ?? const SiteSettings(siteName: 'Khúc Tâm Giao');
        final text = context.localize;
        final failure = state is AsyncFailure<SiteSettings> ? state : null;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<SettingsCubit>().load();
              await _loadNotificationStatus();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                if (failure != null) ...[
                  AppInlineError(
                    message: failure.failure.message,
                    onRetry: () => context.read<SettingsCubit>().load(),
                  ),
                  const SizedBox(height: 14),
                ],
                _SettingsBrandLogo(settings: settings),
                const SizedBox(height: 14),
                _SettingsBrandName(settings: settings),
                const SizedBox(height: 14),
                _SettingsSection(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.alarm_add_outlined),
                      title: Text(text.reminders),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/reminders'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _LanguageSettings(),
                const SizedBox(height: 14),
                _SettingsSection(
                  children: [
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (_) => _openNotificationSettings(),
                      secondary: const Icon(Icons.notifications_outlined),
                      title: Text(text.notifications),
                      subtitle: _loadingNotificationStatus
                          ? const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: SkeletonBox(height: 14, width: 160),
                            )
                          : Text(
                              _notificationsEnabled
                                  ? text.notificationsEnabled
                                  : text.notificationsDisabled,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ContactSettings(settings: settings),
                const SizedBox(height: 14),
                _VersionSettings(packageInfo: _packageInfo),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsBrandLogo extends StatelessWidget {
  const _SettingsBrandLogo({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            height: 104,
            width: 104,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: AppImage(
              url: settings.brandLogo?.url,
              fit: BoxFit.contain,
              borderRadius: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsBrandName extends StatelessWidget {
  const _SettingsBrandName({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        Text(
          settings.siteName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (settings.siteTagline != null && settings.siteTagline!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              settings.siteTagline!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _LanguageSettings extends StatelessWidget {
  const _LanguageSettings();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(
      builder: (context, locale) {
        final text = context.localize;
        return _SettingsSection(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(text.language),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: locale,
                  items: const [
                    DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null || value == locale) return;
                    context.read<LocaleCubit>().setLocale(value);
                    context.read<SettingsCubit>().load();
                  },
                  borderRadius: BorderRadius.circular(8),
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ),
              onTap: () {
                final next = locale == 'vi' ? 'en' : 'vi';
                context.read<LocaleCubit>().setLocale(next);
                context.read<SettingsCubit>().load();
              },
            ),
          ],
        );
      },
    );
  }
}

class _ContactSettings extends StatelessWidget {
  const _ContactSettings({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    final rows = <_ContactRow>[
      if (_hasText(settings.contactAddress))
        _ContactRow(
          icon: Icons.place_outlined,
          label: context.localize.address,
          value: settings.contactAddress!,
          uri: _googleMapsUri(settings.contactAddress!),
        ),
      if (_hasText(settings.contactPhone))
        _ContactRow(
          icon: Icons.phone_outlined,
          label: context.localize.phone,
          value: settings.contactPhone!,
          uri: Uri(scheme: 'tel', path: settings.contactPhone),
        ),
      if (_hasText(settings.contactEmail))
        _ContactRow(
          icon: Icons.mail_outline,
          label: context.localize.email,
          value: settings.contactEmail!,
          uri: Uri(scheme: 'mailto', path: settings.contactEmail),
        ),
      ...settings.socialUrls.entries.map(
        (entry) => _ContactRow(
          icon: Icons.link,
          label: _socialLabel(entry.key),
          value: entry.value,
          uri: Uri.tryParse(entry.value),
        ),
      ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();
    return _SettingsSection(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            context.localize.contactInfo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final row in rows) row,
      ],
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _socialLabel(String key) {
    return key.replaceAll('_url', '').replaceAll('_', ' ');
  }

  static Uri _googleMapsUri(String address) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.uri,
  });

  final IconData icon;
  final String label;
  final String value;
  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    final canOpen =
        uri != null &&
        (uri!.scheme == 'tel' ||
            uri!.scheme == 'mailto' ||
            uri!.scheme == 'http' ||
            uri!.scheme == 'https');
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: canOpen ? const Icon(Icons.open_in_new, size: 18) : null,
      onTap: canOpen
          ? () async {
              final opened = await launchUrl(
                uri!,
                mode: uri!.scheme.startsWith('http')
                    ? LaunchMode.externalApplication
                    : LaunchMode.platformDefault,
              );
              if (!opened && uri!.scheme.startsWith('http')) {
                await launchUrl(uri!, mode: LaunchMode.platformDefault);
              }
            }
          : null,
    );
  }
}

class _VersionSettings extends StatelessWidget {
  const _VersionSettings({required this.packageInfo});

  final Future<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      children: [
        FutureBuilder<PackageInfo>(
          future: packageInfo,
          builder: (context, snapshot) {
            final info = snapshot.data;
            return ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.localize.versionInfo),
              subtitle: info == null
                  ? const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: SkeletonBox(height: 14, width: 140),
                    )
                  : Text(
                      context.localize.version(info.version, info.buildNumber),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
