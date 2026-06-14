import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'comment_repository.dart';
import 'comment_model.dart';
import '../../../../core/network/api_client.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommentRepository(apiClient);
});

final commentsProvider = FutureProvider.family<List<CommentModel>, String>((
  ref,
  reportId,
) async {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.getComments(reportId);
});
