import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/storage/cache_storage.dart';
import '../../../core/widgets/async_state.dart';
import '../data/public_repository.dart';
import '../domain/public_models.dart';

class LocaleCubit extends Cubit<String> {
  LocaleCubit(this._cacheStorage) : super(_cacheStorage.locale);

  final CacheStorage _cacheStorage;

  Future<void> setLocale(String locale) async {
    final next = locale == 'vi' ? 'vi' : 'en';
    await _cacheStorage.setLocale(next);
    emit(next);
  }
}

class FavoriteContentCubit extends Cubit<Set<String>> {
  FavoriteContentCubit(this._cacheStorage)
    : super(_cacheStorage.favoriteContentKeys);

  final CacheStorage _cacheStorage;

  static String keyFor(String type, String path) => '$type|$path';

  bool isFavorite(String type, String path) {
    return state.contains(keyFor(type, path));
  }

  Future<void> toggle(String type, String path) async {
    final key = keyFor(type, path);
    final next = Set<String>.of(state);
    if (!next.remove(key)) {
      next.add(key);
    }
    emit(next);
    await _cacheStorage.setFavoriteContentKeys(next);
  }
}

class SettingsCubit extends Cubit<AsyncState<SiteSettings>> {
  SettingsCubit(this._repository, this._localeCubit)
    : super(const AsyncInitial());

  final PublicRepository _repository;
  final LocaleCubit _localeCubit;

  Future<void> load() async {
    final previous = state is AsyncLoaded<SiteSettings>
        ? (state as AsyncLoaded<SiteSettings>).data
        : state is AsyncLoading<SiteSettings>
        ? (state as AsyncLoading<SiteSettings>).previous
        : null;
    emit(AsyncLoading(previous: previous));
    try {
      emit(AsyncLoaded(await _repository.getSettings(_localeCubit.state)));
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }
}

class HomeCubit extends Cubit<AsyncState<HomeData>> {
  HomeCubit(this._repository, this._localeCubit) : super(const AsyncInitial());

  final PublicRepository _repository;
  final LocaleCubit _localeCubit;

  Future<void> load() async {
    final previous = state is AsyncLoaded<HomeData>
        ? (state as AsyncLoaded<HomeData>).data
        : state is AsyncLoading<HomeData>
        ? (state as AsyncLoading<HomeData>).previous
        : null;
    emit(AsyncLoading(previous: previous));
    try {
      emit(AsyncLoaded(await _repository.getHome(_localeCubit.state)));
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }
}

class ContentListCubit extends Cubit<AsyncState<ContentListData>> {
  ContentListCubit(this._repository, this._localeCubit)
    : super(const AsyncInitial());

  final PublicRepository _repository;
  final LocaleCubit _localeCubit;

  Future<void> load(String type, {int page = 1}) async {
    final previous = state is AsyncLoaded<ContentListData>
        ? (state as AsyncLoaded<ContentListData>).data
        : state is AsyncLoading<ContentListData>
        ? (state as AsyncLoading<ContentListData>).previous
        : null;
    emit(AsyncLoading(previous: previous));
    try {
      emit(
        AsyncLoaded(
          await _repository.getContentList(
            type: type,
            locale: _localeCubit.state,
            page: page,
          ),
        ),
      );
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }
}

class ContentDetailCubit extends Cubit<AsyncState<ContentDetailData>> {
  ContentDetailCubit(this._repository, this._localeCubit)
    : super(const AsyncInitial());

  final PublicRepository _repository;
  final LocaleCubit _localeCubit;

  Future<void> load(String type, String path) async {
    final previous = state is AsyncLoaded<ContentDetailData>
        ? (state as AsyncLoaded<ContentDetailData>).data
        : state is AsyncLoading<ContentDetailData>
        ? (state as AsyncLoading<ContentDetailData>).previous
        : null;
    emit(AsyncLoading(previous: previous));
    try {
      emit(
        AsyncLoaded(
          await _repository.getContentDetail(
            type: type,
            path: path,
            locale: _localeCubit.state,
          ),
        ),
      );
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }
}

class SearchCubit extends Cubit<AsyncState<Map<String, List<ContentItem>>>> {
  SearchCubit(this._repository, this._localeCubit)
    : super(const AsyncInitial());

  final PublicRepository _repository;
  final LocaleCubit _localeCubit;
  String _query = '';

  Future<void> search(String query) async {
    _query = query.trim();
    if (_query.isEmpty) {
      emit(const AsyncInitial());
      return;
    }
    final previous = state is AsyncLoaded<Map<String, List<ContentItem>>>
        ? (state as AsyncLoaded<Map<String, List<ContentItem>>>).data
        : state is AsyncLoading<Map<String, List<ContentItem>>>
        ? (state as AsyncLoading<Map<String, List<ContentItem>>>).previous
        : null;
    emit(AsyncLoading(previous: previous));
    try {
      emit(AsyncLoaded(await _repository.search(_query, _localeCubit.state)));
    } catch (error) {
      emit(AsyncFailure(error is Failure ? error : Failure(error.toString())));
    }
  }

  Future<void> refresh() => search(_query);
}
