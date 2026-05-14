import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'apod_service.dart';
import 'apod_model.dart';

class ApodViewer extends StatefulWidget {
  const ApodViewer({super.key});

  @override
  State<ApodViewer> createState() => _ApodViewerState();
}

class _ApodViewerState extends State<ApodViewer> {
  final ApodService _service = ApodService();
  static final DateTime _today = DateTime.now();

  DateTime _selectedDate = _today;
  bool _loading = false;
  String? _error;
  Apod? _data;

  @override
  void initState() {
    super.initState();
    _fetchForDate(_selectedDate);
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchForDate(DateTime date) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apod = await _service.fetchApod(date);
      setState(() => _data = apod);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _data = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1995, 6, 16),
      lastDate: _today,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _fetchForDate(picked);
    }
  }

  void _goPrevious() {
    final prev = _selectedDate.subtract(const Duration(days: 1));
    setState(() => _selectedDate = prev);
    _fetchForDate(prev);
  }

  void _goNext() {
    final next = _selectedDate.add(const Duration(days: 1));
    if (!next.isAfter(_today)) {
      setState(() => _selectedDate = next);
      _fetchForDate(next);
    }
  }

  Widget _buildMedia() {
    if (_data == null) return const SizedBox.shrink();
    final mediaType = _data!.mediaType ?? 'image';
    final url = _data!.url;
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
    return const Text('Unsupported media type');
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _formatDate(_selectedDate) == _formatDate(_today);
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
                  Expanded(child: Text('Selected: ${_formatDate(_selectedDate)}', style: const TextStyle(fontSize: 16))),
                  IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
                  ElevatedButton(onPressed: () => _fetchForDate(_selectedDate), child: const Text('Fetch')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(onPressed: _selectedDate.isAfter(DateTime(1995, 6, 16)) ? _goPrevious : null, icon: const Icon(Icons.chevron_left), label: const Text('Previous')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: isToday ? null : _goNext, icon: const Icon(Icons.chevron_right), label: const Text('Next')),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  padding: const EdgeInsets.all(8),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _data == null
                              ? const Center(child: Text('No data'))
                              : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(height: 300, child: Center(child: _buildMedia())),
                                      const SizedBox(height: 12),
                                      Text(_data!.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(_data!.date ?? ''),
                                      const SizedBox(height: 12),
                                      Text(_data!.explanation ?? ''),
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
  }
}
