import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/widgets/async_state.dart';
import '../data/notification_repository.dart';

class NotificationHistoryCubit
    extends Cubit<AsyncState<NotificationHistoryData>> {
  NotificationHistoryCubit(this._repository) : super(const AsyncInitial());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(const AsyncLoading());
    try {
      emit(AsyncLoaded(await _repository.history()));
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }

  Future<void> markRead(int receiptId) async {
    await _repository.markRead(receiptId);
    await load();
  }
}
