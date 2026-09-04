import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/facility_zone.dart';
import '../providers/facility_map_provider.dart';
import '../widgets/dose_advisory_card.dart';
import '../widgets/worker_badge_marker.dart';
import '../widgets/zone_bottom_sheet.dart';

/// Live Facility Mapping and Telemetry Viewport.
class FacilityMapScreen extends ConsumerStatefulWidget {
  const FacilityMapScreen({super.key});

  @override
  ConsumerState<FacilityMapScreen> createState() => _FacilityMapScreenState();
}

class _FacilityMapScreenState extends ConsumerState<FacilityMapScreen> {
  final MapController _mapController = MapController();
  bool _showPolygons = true;
  bool _showTrail = true;
  bool _showBadges = true;

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(facilityMapProvider);
    final notifier = ref.read(facilityMapProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── FlutterMap Viewport ───────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.telemetry.facilityCenter,
              initialZoom: 16.3,
              minZoom: 14.0,
              maxZoom: 19.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                // Ray-casting check for tapped zone
                FacilityZone? hitZone;
                for (final zone in mapState.zones) {
                  if (zone.containsPoint(point)) {
                    hitZone = zone;
                    break;
                  }
                }
                notifier.selectZone(hitZone);
              },
            ),
            children: [
              // 1. Dark-mode minimalist industrial tile layer (CartoDB Dark Matter)
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.h2ssentinel.app',
                maxZoom: 20,
              ),

              // 2. Custom industrial facility grid & blueprint background overlay
              const _IndustrialGridOverlay(),

              // 3. Semi-transparent interactive Polygons for facility sectors
              if (_showPolygons)
                PolygonLayer(
                  polygons: mapState.zones.map((zone) {
                    final isSelected = mapState.selectedZone?.id == zone.id;
                    return Polygon(
                      points: zone.polygonPoints,
                      color: isSelected
                          ? zone.statusColor.withValues(alpha: 0.32)
                          : zone.fillColor,
                      borderColor: zone.borderColor,
                      borderStrokeWidth: isSelected ? 3.0 : 1.5,
                      pattern: isSelected
                          ? const StrokePattern.solid()
                          : StrokePattern.dashed(segments: const [8, 4]),
                    );
                  }).toList(),
                ),

              // 4. Sector Name Callout Labels at Polygon Centers
              if (_showPolygons)
                MarkerLayer(
                  markers: mapState.zones.map((zone) {
                    final isSelected = mapState.selectedZone?.id == zone.id;
                    return Marker(
                      point: zone.centerPoint,
                      width: 140,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => notifier.selectZone(zone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? zone.statusColor
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: zone.statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  zone.name.split(':').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // 5. Dotted Polyline tracking worker's recent movement history
              if (_showTrail)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.telemetry.movementHistory,
                      strokeWidth: 3.2,
                      color: AppColors.reticle.withValues(alpha: 0.85),
                      pattern: const StrokePattern.dotted(spacingFactor: 2.0),
                    ),
                  ],
                ),

              // 6. Active Worker Badges Markers Layer
              if (_showBadges)
                MarkerLayer(
                  markers: mapState.workerBadges.map((badge) {
                    return Marker(
                      point: badge.position,
                      width: 90,
                      height: 62,
                      child: WorkerBadgeMarker(
                        data: badge,
                        onTap: () {
                          // Find zone containing this badge
                          final zone = mapState.zones.firstWhere(
                            (z) => z.id == badge.currentZoneId,
                            orElse: () => mapState.zones.first,
                          );
                          notifier.selectZone(zone);
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // ── Top-Anchored Floating Dose Advisory Card ──────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: DoseAdvisoryCard(
                telemetry: mapState.telemetry,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // ── Floating Action Map Controls (Right Side) ────────────────────
          Positioned(
            right: 16,
            bottom: mapState.selectedZone != null ? 310 : 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControl(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter on My Badge',
                  onTap: () {
                    final pos = notifier.getCurrentWorkerPosition();
                    _mapController.move(pos, 17.2);
                  },
                ),
                const SizedBox(height: 10),
                _buildMapControl(
                  icon: Icons.zoom_in_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom + 1.0);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapControl(
                  icon: Icons.zoom_out_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom - 1.0);
                  },
                ),
                const SizedBox(height: 10),
                _buildMapControl(
                  icon: Icons.layers_rounded,
                  tooltip: 'Toggle Sector Polygons',
                  isActive: _showPolygons,
                  onTap: () {
                    setState(() => _showPolygons = !_showPolygons);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapControl(
                  icon: Icons.route_rounded,
                  tooltip: 'Toggle Movement Trail',
                  isActive: _showTrail,
                  onTap: () {
                    setState(() => _showTrail = !_showTrail);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapControl(
                  icon: Icons.sensors_rounded,
                  tooltip: 'Toggle Active Badges',
                  isActive: _showBadges,
                  onTap: () {
                    setState(() => _showBadges = !_showBadges);
                  },
                ),
              ],
            ),
          ),

          // ── Emergency Evacuation Toast Banner (If Active) ─────────────────
          if (mapState.isEvacuationRequested)
            Positioned(
              left: 16,
              right: 16,
              top: 140,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.critical,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.critical.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EVACUATION ORDER BROADCAST FOR ${mapState.selectedZone?.name ?? "SECTOR"}',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Interactive Zone Bottom Sheet ─────────────────────────────────
          if (mapState.selectedZone != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: ZoneBottomSheet(
                zone: mapState.selectedZone!,
                onClose: () => notifier.selectZone(null),
                onRequestEvacuation: () {
                  notifier.requestSectorEvacuation(mapState.selectedZone!.id);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accent
            : AppColors.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon,
            color: isActive ? Colors.white : AppColors.textPrimary, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

/// Custom industrial grid overlay simulating high-tech facility schematic blueprints.
class _IndustrialGridOverlay extends StatelessWidget {
  const _IndustrialGridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2638).withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
