import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_state.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../notifications/presentation/notification_cubit.dart';
import '../common/app_text.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationHistoryCubit,
      AsyncState<NotificationHistoryData>
    >(
      builder: (context, state) {
        if (state is AsyncInitial) {
          context.read<NotificationHistoryCubit>().load();
        }
        if (state is AsyncLoading<NotificationHistoryData>) {
          return AppSkeleton.notifications();
        }
        if (state is AsyncFailure<NotificationHistoryData>) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              AppInlineError(
                message: state.failure.message,
                onRetry: context.read<NotificationHistoryCubit>().load,
              ),
            ],
          );
        }
        if (state is! AsyncLoaded<NotificationHistoryData>) {
          return Center(child: Text(context.localize.noNotifications));
        }
        return state.data.items.isEmpty
            ? Center(child: Text(context.localize.noNotifications))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, index) {
                  final item = state.data.items[index];
                  return ListTile(
                    leading: Icon(
                      item.readAt == null
                          ? Icons.mark_email_unread_outlined
                          : Icons.mark_email_read_outlined,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    onTap: () {
                      if (item.receiptId > 0) {
                        context.read<NotificationHistoryCubit>().markRead(
                          item.receiptId,
                        );
                      }
                      if (item.url != null && item.url!.startsWith('/')) {
                        context.push(item.url!);
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: state.data.items.length,
              );
      },
    );
  }
}
