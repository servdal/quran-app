// lib/screens/download_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/download_provider.dart';

class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadTasks = ref.watch(downloadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduh Audio per Surah'),
      ),
      body: downloadTasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: downloadTasks.length,
              itemBuilder: (context, index) {
                final task = downloadTasks[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(task.surah.suraId.toString())),
                  title: Text(task.surah.englishName),
                  subtitle: _buildStatusWidget(task),
                  trailing: _buildActionButton(ref, task),
                );
              },
            ),
    );
  }

  Widget _buildStatusWidget(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return LinearProgressIndicator(value: task.progress);
      case DownloadStatus.completed:
        return const Text('Selesai', style: TextStyle(color: Colors.green));
      case DownloadStatus.failed:
        return const Text('Gagal', style: TextStyle(color: Colors.red));
      default:
        return Text('${task.surah.numberOfAyahs} Ayat');
    }
  }

  Widget _buildActionButton(WidgetRef ref, DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.replay, color: Colors.red),
          onPressed: () {
            ref.read(downloadProvider.notifier).startDownload(task.surah.suraId);
          },
        );
      default: // none
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            ref.read(downloadProvider.notifier).startDownload(task.surah.suraId);
          },
        );
    }
  }
}