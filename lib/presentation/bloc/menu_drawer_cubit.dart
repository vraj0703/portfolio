import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the title screen's drawer is open.
///
/// Its own cubit rather than a field on `SceneBloc`, and the previous site
/// had the same split for the same reason: `SceneBloc` owns where the visitor
/// *is*, and a panel sliding over the screen does not move them. Folded in,
/// every scene transition would have to decide what happens to the drawer,
/// and every drawer toggle would emit a new scene state.
class MenuDrawerCubit extends Cubit<bool> {
  MenuDrawerCubit() : super(false);

  void open() => emit(true);

  void dismiss() {
    // Guarded, because closing is reached from three places — the scrim, the
    // close control and Escape — and two of them can fire for one gesture.
    if (state) emit(false);
  }
}
