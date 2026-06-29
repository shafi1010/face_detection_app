class DashboardStats {
  final int totalCameras;
  final int onlineCameras;
  final int offlineCameras;
  final int alertsToday;
  final int unacknowledgedAlerts;
  final int blacklistMatchesToday;
  final int totalDetectionsToday;
  final int activeWatchers;
  final double avgConfidence;

  const DashboardStats({
    this.totalCameras = 0,
    this.onlineCameras = 0,
    this.offlineCameras = 0,
    this.alertsToday = 0,
    this.unacknowledgedAlerts = 0,
    this.blacklistMatchesToday = 0,
    this.totalDetectionsToday = 0,
    this.activeWatchers = 0,
    this.avgConfidence = 0.0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCameras: json['total_cameras'] as int? ?? 0,
      onlineCameras: json['online_cameras'] as int? ?? 0,
      offlineCameras: json['offline_cameras'] as int? ?? 0,
      alertsToday: json['alerts_today'] as int? ?? 0,
      unacknowledgedAlerts: json['unacknowledged_alerts'] as int? ?? 0,
      blacklistMatchesToday: json['blacklist_matches_today'] as int? ?? 0,
      totalDetectionsToday: json['total_detections_today'] as int? ?? 0,
      activeWatchers: json['active_watchers'] as int? ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
