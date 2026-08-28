import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pinned admin list header — title stays readable (no FlexibleSpaceBar overlap).
class AdminListHeader extends StatelessWidget {
  const AdminListHeader({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  static const navy = Color(0xFF031273);
  static const sky = Color(0xFF0056D2);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: navy,
      foregroundColor: Colors.white,
      centerTitle: false,
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [navy, sky],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
