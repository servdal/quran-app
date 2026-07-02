import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/offline_recitation_model_provider.dart';
import 'package:quran_app/services/offline_recitation_model_service.dart';

class OfflineModelManagerScreen extends ConsumerStatefulWidget {
  final bool autoStartDownload;

  const OfflineModelManagerScreen({super.key, this.autoStartDownload = false});

  @override
  ConsumerState<OfflineModelManagerScreen> createState() =>
      _OfflineModelManagerScreenState();
}

class _OfflineModelManagerScreenState
    extends ConsumerState<OfflineModelManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(offlineRecitationModelServiceProvider);
      if (widget.autoStartDownload) {
        service.ensureRecommendedModel();
      } else {
        service.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(offlineRecitationModelServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Hafalan Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Periksa ulang',
            onPressed:
                service.isRefreshing
                    ? null
                    : () {
                      ref.read(offlineRecitationModelServiceProvider).refresh();
                    },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _StatusHeader(service: service),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Siapkan Otomatis'),
              onPressed:
                  service.installedModelIds.isNotEmpty
                      ? null
                      : () {
                        ref
                            .read(offlineRecitationModelServiceProvider)
                            .ensureRecommendedModel();
                      },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pilihan Model',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...OfflineRecitationModelService.availableModels.map((model) {
            return _ModelTile(model: model);
          }),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final OfflineRecitationModelService service;

  const _StatusHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        service.installedModelIds.isNotEmpty ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            service.installedModelIds.isNotEmpty
                ? Icons.check_circle
                : Icons.cloud_download_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.statusMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!service.nativeAvailable) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Downloader native belum tersedia, aplikasi akan mengunduh model langsung ke penyimpanan lokal.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (service.isRefreshing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _ModelTile extends ConsumerWidget {
  final OfflineRecitationModel model;

  const _ModelTile({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(offlineRecitationModelServiceProvider);
    final info = service.downloadInfo(model.id);
    final installed = info.state == OfflineModelDownloadState.installed;
    final downloading = info.state == OfflineModelDownloadState.downloading;
    final failed = info.state == OfflineModelDownloadState.failed;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  installed
                      ? Icons.check_circle
                      : failed
                      ? Icons.error_outline
                      : Icons.graphic_eq,
                  color:
                      installed
                          ? Colors.green
                          : failed
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (model.recommended)
                            const _SmallBadge(label: 'Disarankan'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${model.engine} • ${model.sizeLabel} • unduhan otomatis',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (downloading || installed || failed) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: downloading || installed ? info.progress : 0,
              ),
              const SizedBox(height: 8),
              Text(
                _statusText(info),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: failed ? theme.colorScheme.error : null,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (installed)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    onPressed: () {
                      ref
                          .read(offlineRecitationModelServiceProvider)
                          .deleteModel(model.id);
                    },
                  )
                else
                  FilledButton.icon(
                    icon:
                        downloading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.download),
                    label: Text(downloading ? 'Mengunduh' : 'Unduh'),
                    onPressed:
                        downloading
                            ? null
                            : () {
                              ref
                                  .read(offlineRecitationModelServiceProvider)
                                  .downloadModel(model.id);
                            },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(OfflineModelDownloadInfo info) {
    if (info.state == OfflineModelDownloadState.installed) {
      return 'Selesai. Model siap digunakan.';
    }
    if (info.state == OfflineModelDownloadState.failed) {
      return info.message.isEmpty ? 'Unduhan gagal.' : info.message;
    }
    final percent = (info.progress * 100).clamp(0, 100).toStringAsFixed(0);
    return info.message.isEmpty ? '$percent%' : '$percent% • ${info.message}';
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
