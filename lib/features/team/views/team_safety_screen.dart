import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kinetic_colors.dart';
import '../../../providers/theme_provider.dart';
import '../models/team_member.dart';
import '../providers/team_provider.dart';

/// Screen displaying active on-site personnel, live dosimeter readings, and safety status.
class TeamSafetyScreen extends ConsumerWidget {
  const TeamSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final teamState = ref.watch(teamProvider);
    final teamNotifier = ref.read(teamProvider.notifier);

    final cardBg = isDark ? KineticColors.darkCard : KineticColors.lightCard;
    final borderCol =
        isDark ? KineticColors.darkBorderSubtle : KineticColors.lightBorderSubtle;
    final textCol =
        isDark ? KineticColors.darkTextPrimary : KineticColors.lightTextPrimary;
    final secondaryText = isDark
        ? KineticColors.darkTextSecondary
        : KineticColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Header & RAD-NET Status ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top actions bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // RAD-NET Live Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? KineticColors.darkSurfaceContainer
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: KineticColors.electricCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RAD-NET LIVE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: textCol,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions: Theme toggle & User Profile
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  ref.read(themeModeProvider.notifier).toggleTheme(),
                              icon: Icon(
                                isDark
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nightlight_round,
                                color: isDark
                                    ? KineticColors.cautionYellow
                                    : KineticColors.darkCard,
                                size: 20,
                              ),
                              tooltip: isDark
                                  ? 'Switch to Light Theme'
                                  : 'Switch to Dark Theme',
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? KineticColors.darkSurfaceContainer
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: isDark
                                  ? KineticColors.darkSurfaceHigh
                                  : KineticColors.lightSurfaceHigh,
                              child: Icon(
                                Icons.person_rounded,
                                color: textCol,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Big Bold Athletic Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'TEAM SAFETY',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: textCol,
                          ),
                        ),
                        Text(
                          'FACILITY 09',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Pills Carousel
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterPill(
                            label: 'ALL MEMBERS (${teamState.members.length})',
                            isSelected: teamState.filter == TeamFilter.all,
                            isDark: isDark,
                            onTap: () => teamNotifier.setFilter(TeamFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            label: 'WARNING (${teamState.warningCount})',
                            isSelected: teamState.filter == TeamFilter.warning,
                            isDark: isDark,
                            color: KineticColors.amber,
                            onTap: () => teamNotifier.setFilter(TeamFilter.warning),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            label: 'SAFE (${teamState.safeCount})',
                            isSelected: teamState.filter == TeamFilter.safe,
                            isDark: isDark,
                            color: KineticColors.emeraldSafe,
                            onTap: () => teamNotifier.setFilter(TeamFilter.safe),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Summary Metrics Bento Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: KineticColors.emeraldSafe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ON-SITE PERSONNEL',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${teamState.members.length} Workers Active',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: textCol,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      // 3-Column Metrics Grid
                      Row(
                        children: [
                          // Safe Column
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Safe',
                              value: '${teamState.safeCount}',
                              valueColor: KineticColors.emeraldSafe,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Warning Column
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Warning',
                              value: '${teamState.warningCount}',
                              valueColor: KineticColors.amber,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Avg Dose Column
                          Expanded(
                            child: _buildMetricTile(
                              title: 'ppm·h Avg',
                              value: teamState.averageShiftDose.toStringAsFixed(2),
                              valueColor: textCol,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section Title ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'ACTIVE PERSONNEL ROSTER',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: secondaryText,
                  ),
                ),
              ),
            ),

            // ── Team Members List ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = teamState.filteredMembers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildWorkerCard(
                        member: member,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        secondaryText: secondaryText,
                      ),
                    );
                  },
                  childCount: teamState.filteredMembers.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? KineticColors.blazeOrange;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark
                  ? KineticColors.darkSurfaceContainer
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? KineticColors.darkBorderSubtle : KineticColors.lightBorderSubtle),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.barlowCondensed(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? KineticColors.darkCardAlt : KineticColors.lightCardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? KineticColors.darkBorderSubtle : KineticColors.lightBorderSubtle,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard({
    required TeamMember member,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: member.id == 'WRK-CURRENT'
              ? KineticColors.blazeOrange.withValues(alpha: 0.5)
              : borderCol,
          width: member.id == 'WRK-CURRENT' ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Initials Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: member.avatarColor,
            child: Text(
              member.initials,
              style: GoogleFonts.barlowCondensed(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name, Role & Zone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      member.badgeId,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 11,
                      color: secondaryText,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        member.zoneName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status & PPM Chip
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: member.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: member.statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: member.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      member.statusLabel,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: member.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: member.currentPpm.toStringAsFixed(2),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    TextSpan(
                      text: ' ppm',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
