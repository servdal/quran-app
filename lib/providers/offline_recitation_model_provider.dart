import 'package:flutter_riverpod/legacy.dart';
import 'package:quran_app/services/offline_recitation_model_service.dart';

final offlineRecitationModelServiceProvider =
    ChangeNotifierProvider<OfflineRecitationModelService>((ref) {
      return OfflineRecitationModelService();
    });
