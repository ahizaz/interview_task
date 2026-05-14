import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/apod_controller.dart';

class ApodViewer extends StatelessWidget {
  const ApodViewer({super.key});

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    late final ApodController controller;
    try {
      controller = Get.find<ApodController>();
    } catch (_) {
      Get.reset();
      controller = Get.put(ApodController());
    }
    final today = DateTime.now();

    Future<void> _pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: controller.selectedDate.value,
        firstDate: DateTime(1995, 6, 16),
        lastDate: today,
      );
      if (picked != null && picked != controller.selectedDate.value) {
        await controller.fetchForDate(picked);
      }
    }

    Widget _buildMedia() {
      final apod = controller.data.value;
      if (apod == null) return const SizedBox.shrink();
      final mediaType = apod.mediaType ?? 'image';
      final url = apod.url;
      if (mediaType == 'image' && url != null) {
        return InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain, loadingBuilder: (c, w, p) {
            if (p == null) return w;
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 120)),
        );
      }
      if (mediaType == 'video' && url != null) {
        return Column(
          children: [
            const Icon(Icons.play_circle_filled, size: 120, color: Colors.blueGrey),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open video'),
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open video link')));
                }
              },
            ),
          ],
        );
      }
      return const Text('Preview is not available for this media type');
    }

    return Obx(() {
      final selected = controller.selectedDate.value;
      final isToday = _formatDate(selected) == _formatDate(today);
      return Scaffold(
        appBar: AppBar(title: const Text('NASA APOD')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Selected: ${_formatDate(selected)}', style: const TextStyle(fontSize: 16))),
                    IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
                    ElevatedButton(onPressed: () => controller.fetchForDate(selected), child: const Text('Fetch')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: selected.isAfter(DateTime(1995, 6, 16)) ? () => controller.fetchForDate(selected.subtract(const Duration(days: 1))) : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isToday ? null : () => controller.fetchForDate(selected.add(const Duration(days: 1))),
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(8),
                    child: controller.loading.value
                        ? const Center(child: CircularProgressIndicator())
                        : controller.error.value != null
                            ? Center(child: Text(controller.error.value!, style: const TextStyle(color: Colors.red)))
                            : controller.data.value == null
                                ? const Center(child: Text('No data'))
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(height: 300, child: Center(child: _buildMedia())),
                                        const SizedBox(height: 12),
                                        Text(controller.data.value!.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(controller.data.value!.date ?? ''),
                                        const SizedBox(height: 12),
                                        Text(controller.data.value!.explanation ?? ''),
                                      ],
                                    ),
                                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
