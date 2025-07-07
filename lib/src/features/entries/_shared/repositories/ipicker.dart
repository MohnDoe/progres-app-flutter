import 'package:progres/src/core/domain/models/progress_picture.dart';

abstract class IPicker {
  Future<ProgressPicture> selectImage();
}
