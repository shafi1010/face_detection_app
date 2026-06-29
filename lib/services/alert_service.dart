import '../core/network/api_client.dart';
import '../models/alert.dart';
import '../models/dashboard_stats.dart';

class AlertService {
  final ApiClient _apiClient;

  AlertService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Alert>> getAlerts({
    int page = 1,
    int limit = 20,
    String? status,
    String? severity,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (severity != null) params['severity'] = severity;

    return await _apiClient.get<List<Alert>>(
      '/alerts',
      queryParams: params,
      fromJson: (json) {
        final list = json as List;
        return list.map((e) => Alert.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<Alert> getAlert(String id) async {
    return await _apiClient.get<Alert>(
      '/alerts/$id',
      fromJson: (json) => Alert.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> acknowledgeAlert(String id) async {
    await _apiClient.patch<void>('/alerts/$id/acknowledge');
  }

  Future<void> dismissAlert(String id) async {
    await _apiClient.patch<void>('/alerts/$id/dismiss');
  }

  Future<void> escalateAlert(String id, {String? reason}) async {
    await _apiClient.patch<void>(
      '/alerts/$id/escalate',
      body: reason != null ? {'reason': reason} : null,
    );
  }

  Future<DashboardStats> getDashboardStats() async {
    return await _apiClient.get<DashboardStats>(
      '/dashboard/stats',
      fromJson: (json) => DashboardStats.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<int> getUnacknowledgedCount() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/alerts/count',
      queryParams: {'status': 'unacknowledged'},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return result['count'] as int;
  }
}
