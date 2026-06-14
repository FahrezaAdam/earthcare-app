import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_repository.dart';
import 'notification_model.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return await repository.getNotifications();
    });
