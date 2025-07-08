import 'package:image_picker/image_picker.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

abstract class IPicker {
  Future<ProgressPicture?> pickImage(ImageSource source);
}
