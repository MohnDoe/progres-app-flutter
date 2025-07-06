import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/pictures/_shared/repositories/pictures_repository.dart';

final picturesRepositoryProvider = Provider<PicturesRepository>((ref) {
  return PicturesRepository();
});

final userPicturesRepositoryProvider = Provider<UserPicturesRepository>((ref) {
  return UserPicturesRepository();
});
