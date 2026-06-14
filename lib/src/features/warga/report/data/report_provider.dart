import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'report_repository.dart';
import 'report_model.dart';


final reportsProvider = FutureProvider.family<List<ReportModel>, String>((
  ref,
  filter,
) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getReports(filter: filter);
});

final heatmapProvider = FutureProvider<List<HeatmapData>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getHeatmapData();
});
