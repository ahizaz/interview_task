import 'package:get/get.dart';
import '../apod_service.dart';
import '../apod_model.dart';

class ApodController extends GetxController {
  final ApodService _service = ApodService();
  final selectedDate = DateTime.now().obs;
  final loading = false.obs;
  final error = RxnString();
  final data = Rxn<Apod>();

  Future<void> fetchForDate(DateTime date) async {
    loading.value = true;
    error.value = null;
    try {
      final apod = await _service.fetchApod(date);
      data.value = apod;
      selectedDate.value = date;
    } catch (e) {
      error.value = e.toString();
      data.value = null;
    } finally {
      loading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchForDate(selectedDate.value);
  }
}
