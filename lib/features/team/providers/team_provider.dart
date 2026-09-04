import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exposure_status.dart';
import '../../../providers/readings_provider.dart';
import '../../../providers/worker_provider.dart';
import '../models/team_member.dart';

enum TeamFilter {
  all,
  warning,
  safe,
}

class TeamState {
  const TeamState({
    required this.members,
    this.filter = TeamFilter.all,
  });

  final List<TeamMember> members;
  final TeamFilter filter;

  List<TeamMember> get filteredMembers {
    switch (filter) {
      case TeamFilter.all:
        return members;
      case TeamFilter.warning:
        return members
            .where((m) =>
                m.status == ExposureStatus.warning ||
                m.status == ExposureStatus.critical)
            .toList();
      case TeamFilter.safe:
        return members
            .where((m) => m.status == ExposureStatus.safe)
            .toList();
    }
  }

  int get safeCount =>
      members.where((m) => m.status == ExposureStatus.safe).length;

  int get warningCount => members
      .where((m) =>
          m.status == ExposureStatus.warning ||
          m.status == ExposureStatus.critical)
      .length;

  double get averageShiftDose {
    if (members.isEmpty) return 0.0;
    final total =
        members.fold<double>(0.0, (acc, item) => acc + item.shiftDosePpmH);
    return total / members.length;
  }

  TeamState copyWith({
    List<TeamMember>? members,
    TeamFilter? filter,
  }) {
    return TeamState(
      members: members ?? this.members,
      filter: filter ?? this.filter,
    );
  }
}

final teamProvider =
    StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier(ref);
});

class TeamNotifier extends StateNotifier<TeamState> {
  TeamNotifier(this.ref) : super(_createInitialState(ref)) {
    // Listen to live readings to update the primary worker's badge in real-time
    ref.listen(latestReadingProvider, (previous, next) {
      if (next != null) {
        _updateCurrentWorkerReading(next.estimatedPpm, next.status);
      }
    });
  }

  final Ref ref;

  void setFilter(TeamFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void _updateCurrentWorkerReading(double ppm, ExposureStatus status) {
    final updated = state.members.map((m) {
      if (m.id == 'WRK-CURRENT') {
        return TeamMember(
          id: m.id,
          badgeId: m.badgeId,
          name: m.name,
          initials: m.initials,
          role: m.role,
          zoneName: m.zoneName,
          currentPpm: ppm,
          shiftDosePpmH: (m.shiftDosePpmH * 0.8) + (ppm * 0.2),
          status: status,
          avatarColor: m.avatarColor,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(members: updated);
  }

  static TeamState _createInitialState(Ref ref) {
    String currentWorkerId;
    try {
      currentWorkerId = ref.read(workerIdProvider);
    } catch (_) {
      currentWorkerId = 'WRK-9418';
    }

    final latestReading = ref.read(latestReadingProvider);
    final myPpm = latestReading?.estimatedPpm ?? 0.08;
    final myStatus = latestReading?.status ?? ExposureStatus.safe;

    final initialList = [
      TeamMember(
        id: 'WRK-CURRENT',
        badgeId: '#DOS-9418-H2S',
        name: 'You ($currentWorkerId)',
        initials: 'ME',
        role: 'Lead Operator',
        zoneName: 'ZONE 03: AUX TURBINES',
        currentPpm: myPpm,
        shiftDosePpmH: 0.12,
        status: myStatus,
        avatarColor: const Color(0xFFFF5500),
      ),
      const TeamMember(
        id: 'wrk_02',
        badgeId: 'RAD-891',
        name: 'D. Vance',
        initials: 'DV',
        role: 'Containment Specialist',
        zoneName: 'ZONE 04: CONTAINMENT 2',
        currentPpm: 0.62,
        shiftDosePpmH: 0.38,
        status: ExposureStatus.warning,
        avatarColor: Color(0xFFFF5708),
      ),
      const TeamMember(
        id: 'wrk_03',
        badgeId: 'RAD-112',
        name: 'S. Chen',
        initials: 'SC',
        role: 'Turbine Tech',
        zoneName: 'ZONE 03: AUX TURBINES',
        currentPpm: 0.15,
        shiftDosePpmH: 0.14,
        status: ExposureStatus.warning,
        avatarColor: Color(0xFFF59E0B),
      ),
      const TeamMember(
        id: 'wrk_04',
        badgeId: 'RAD-009',
        name: 'M. Torres',
        initials: 'MT',
        role: 'QA Inspector',
        zoneName: 'ZONE 01: ADMIN / QA',
        currentPpm: 0.01,
        shiftDosePpmH: 0.04,
        status: ExposureStatus.safe,
        avatarColor: Color(0xFF00C48C),
      ),
      const TeamMember(
        id: 'wrk_05',
        badgeId: 'RAD-404',
        name: 'A. Kowalski',
        initials: 'AK',
        role: 'Piping Specialist',
        zoneName: 'ZONE 04: CONTAINMENT 2',
        currentPpm: 0.58,
        shiftDosePpmH: 0.31,
        status: ExposureStatus.warning,
        avatarColor: Color(0xFFFF7033),
      ),
      const TeamMember(
        id: 'wrk_06',
        badgeId: 'RAD-221',
        name: 'R. Lewis',
        initials: 'RL',
        role: 'Scrubber Operator',
        zoneName: 'ZONE 02: H2S STRIPPER',
        currentPpm: 0.04,
        shiftDosePpmH: 0.09,
        status: ExposureStatus.safe,
        avatarColor: Color(0xFF10B981),
      ),
      const TeamMember(
        id: 'wrk_07',
        badgeId: 'RAD-734',
        name: 'E. Wright',
        initials: 'EW',
        role: 'Safety Officer',
        zoneName: 'ZONE 05: DECON AIRLOCK',
        currentPpm: 0.02,
        shiftDosePpmH: 0.05,
        status: ExposureStatus.safe,
        avatarColor: Color(0xFF00B4D8),
      ),
      const TeamMember(
        id: 'wrk_08',
        badgeId: 'RAD-556',
        name: 'N. Lopez',
        initials: 'NL',
        role: 'Electrical Tech',
        zoneName: 'ZONE 01: ADMIN / QA',
        currentPpm: 0.01,
        shiftDosePpmH: 0.03,
        status: ExposureStatus.safe,
        avatarColor: Color(0xFF34D399),
      ),
    ];

    return TeamState(members: initialList);
  }
}
