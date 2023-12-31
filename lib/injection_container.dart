import 'package:get_it/get_it.dart';

import 'package:cityvista/bloc/register/register_bloc.dart';
import 'package:cityvista/bloc/username/username_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => RegisterBloc());
  sl.registerFactory(() => UsernameBloc());
}