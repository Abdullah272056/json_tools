import 'package:get/get.dart';
import '../controllers/json_to_dart_controller.dart';

class JsonToDartBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JsonToDartController>(() => JsonToDartController());
  }
}
