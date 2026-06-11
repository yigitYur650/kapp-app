// lib/features/home/presentation/screens/hub_screen.dart
//
// Evim (Hub) ekranı - Henüz bir evi olmayan kullanıcı (No Home State) tasarımı.
// Netflix Dark temasına sadık, ortalanmış (max 450px) ve responsive.

import 'package:flutter/material.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class HubScreen extends m.StatelessWidget {
  const HubScreen({super.key});

  void _openCreateHomeSheet(m.BuildContext context) {
    m.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: m.Colors.transparent,
      builder: (_) => const _CreateHomeSheet(),
    );
  }

  void _openJoinHomeSheet(m.BuildContext context) {
    m.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: m.Colors.transparent,
      builder: (_) => const _JoinHomeSheet(),
    );
  }

  @override
  m.Widget build(m.BuildContext context) {
    final l = AppLocalizations.of(context);

    return m.Center(
      child: m.SingleChildScrollView(
        padding: const m.EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: m.ConstrainedBox(
          constraints: const m.BoxConstraints(maxWidth: 450),
          child: m.Column(
            mainAxisSize: m.MainAxisSize.min,
            crossAxisAlignment: m.CrossAxisAlignment.stretch,
            children: [
              // ── Glowing Logo/Icon ──────────────────────────────────
              m.Center(
                child: m.Container(
                  width: 80,
                  height: 80,
                  decoration: m.BoxDecoration(
                    color: AppTheme.bgCard,
                    border: m.Border.all(color: AppTheme.netflixRed.withValues(alpha: 0.5), width: 1.5),
                    borderRadius: m.BorderRadius.circular(24),
                    boxShadow: [
                      m.BoxShadow(
                        color: AppTheme.netflixRed.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const m.Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const m.Icon(
                    m.Icons.home_rounded,
                    color: AppTheme.netflixRed,
                    size: 38,
                  ),
                ),
              ),
              const m.SizedBox(height: 28),

              // ── Başlıklar ──────────────────────────────────────────
              Text('Kap-App')
                  .h2()
                  .bold()
                  .center()
                  .foreground(),
              const m.SizedBox(height: 8),
              Text(l.t('tenant.no_home'))
                  .small()
                  .muted()
                  .center()
                  .foreground(),
              const m.SizedBox(height: 40),

              // ── Seçenek Kartları ───────────────────────────────────
              _buildOptionCard(
                context: context,
                icon: m.Icons.add_circle_outline_rounded,
                title: l.t('tenant.create_home'),
                description: l.t('tenant.create_home_desc'),
                onTap: () => _openCreateHomeSheet(context),
              ),
              const m.SizedBox(height: 16),
              _buildOptionCard(
                context: context,
                icon: m.Icons.group_add_outlined,
                title: l.t('tenant.join_home'),
                description: l.t('tenant.join_home_desc'),
                onTap: () => _openJoinHomeSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  m.Widget _buildOptionCard({
    required m.BuildContext context,
    required m.IconData icon,
    required String title,
    required String description,
    required m.VoidCallback onTap,
  }) {
    return m.Container(
      decoration: m.BoxDecoration(
        color: AppTheme.bgCard,
        border: m.Border.all(color: AppTheme.borderDefault, width: 0.8),
        borderRadius: m.BorderRadius.circular(14),
      ),
      child: m.Material(
        color: m.Colors.transparent,
        child: m.InkWell(
          onTap: onTap,
          borderRadius: m.BorderRadius.circular(14),
          splashColor: AppTheme.netflixRed.withValues(alpha: 0.08),
          highlightColor: AppTheme.netflixRed.withValues(alpha: 0.04),
          child: m.Padding(
            padding: const m.EdgeInsets.all(20),
            child: m.Row(
              children: [
                m.Container(
                  padding: const m.EdgeInsets.all(10),
                  decoration: m.BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: m.BorderRadius.circular(10),
                  ),
                  child: m.Icon(icon, color: AppTheme.netflixRed, size: 24),
                ),
                const m.SizedBox(width: 16),
                m.Expanded(
                  child: m.Column(
                    crossAxisAlignment: m.CrossAxisAlignment.start,
                    children: [
                      Text(title)
                          .semiBold()
                          .large()
                          .foreground(),
                      const m.SizedBox(height: 4),
                      Text(description)
                          .small()
                          .muted()
                          .foreground(),
                    ],
                  ),
                ),
                const m.SizedBox(width: 8),
                const m.Icon(
                  m.Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Yeni Ev Oluştur Bottom Sheet ──────────────────────────────────────────

class _CreateHomeSheet extends m.StatefulWidget {
  const _CreateHomeSheet();

  @override
  m.State<_CreateHomeSheet> createState() => _CreateHomeSheetState();
}

class _CreateHomeSheetState extends m.State<_CreateHomeSheet> {
  final m.TextEditingController _nameController = m.TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  m.Widget build(m.BuildContext context) {
    final l = AppLocalizations.of(context);

    return m.Padding(
      padding: m.EdgeInsets.only(bottom: m.MediaQuery.of(context).viewInsets.bottom),
      child: m.Container(
        decoration: const m.BoxDecoration(
          color: AppTheme.bgSheet,
          borderRadius: m.BorderRadius.vertical(top: m.Radius.circular(20)),
        ),
        child: m.SafeArea(
          child: m.SingleChildScrollView(
            padding: const m.EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: m.Column(
              mainAxisSize: m.MainAxisSize.min,
              crossAxisAlignment: m.CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                m.Center(
                  child: m.Container(
                    width: 36,
                    height: 4,
                    decoration: m.BoxDecoration(
                      color: AppTheme.borderDefault,
                      borderRadius: m.BorderRadius.circular(2),
                    ),
                  ),
                ),
                const m.SizedBox(height: 20),

                // Başlık
                m.Row(
                  children: [
                    m.Container(
                      width: 3,
                      height: 18,
                      decoration: m.BoxDecoration(
                        color: AppTheme.netflixRed,
                        borderRadius: m.BorderRadius.circular(1.5),
                      ),
                    ),
                    const m.SizedBox(width: 8),
                    Text(l.t('tenant.create_home'))
                        .bold()
                        .large()
                        .foreground(),
                  ],
                ),
                const m.SizedBox(height: 24),

                // Ev Adı Inputu
                Text(l.t('tenant.home_name'))
                    .semiBold()
                    .small()
                    .foreground(),
                const m.SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  placeholder: Text(l.t('tenant.home_name')),
                  features: const [
                    InputLeadingFeature(
                      m.Icon(m.Icons.home_outlined, size: 18, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const m.SizedBox(height: 24),

                // Oluştur Butonu
                Button.primary(
                  onPressed: _isLoading ? null : () async {
                    if (_nameController.text.trim().isEmpty) return;
                    setState(() => _isLoading = true);
                    // Mock API call
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (context.mounted) {
                      m.Navigator.pop(context);
                    }
                  },
                  child: _isLoading
                      ? const m.SizedBox(
                          width: 20,
                          height: 20,
                          child: m.CircularProgressIndicator(
                            strokeWidth: 2,
                            color: m.Colors.white,
                          ),
                        )
                      : Text(l.t('tenant.create_button')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Davet Koduyla Katıl Bottom Sheet ────────────────────────────────────────

class _JoinHomeSheet extends m.StatefulWidget {
  const _JoinHomeSheet();

  @override
  m.State<_JoinHomeSheet> createState() => _JoinHomeSheetState();
}

class _JoinHomeSheetState extends m.State<_JoinHomeSheet> {
  final m.TextEditingController _codeController = m.TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  m.Widget build(m.BuildContext context) {
    final l = AppLocalizations.of(context);

    return m.Padding(
      padding: m.EdgeInsets.only(bottom: m.MediaQuery.of(context).viewInsets.bottom),
      child: m.Container(
        decoration: const m.BoxDecoration(
          color: AppTheme.bgSheet,
          borderRadius: m.BorderRadius.vertical(top: m.Radius.circular(20)),
        ),
        child: m.SafeArea(
          child: m.SingleChildScrollView(
            padding: const m.EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: m.Column(
              mainAxisSize: m.MainAxisSize.min,
              crossAxisAlignment: m.CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                m.Center(
                  child: m.Container(
                    width: 36,
                    height: 4,
                    decoration: m.BoxDecoration(
                      color: AppTheme.borderDefault,
                      borderRadius: m.BorderRadius.circular(2),
                    ),
                  ),
                ),
                const m.SizedBox(height: 20),

                // Başlık
                m.Row(
                  children: [
                    m.Container(
                      width: 3,
                      height: 18,
                      decoration: m.BoxDecoration(
                        color: AppTheme.netflixRed,
                        borderRadius: m.BorderRadius.circular(1.5),
                      ),
                    ),
                    const m.SizedBox(width: 8),
                    Text(l.t('tenant.join_home'))
                        .bold()
                        .large()
                        .foreground(),
                  ],
                ),
                const m.SizedBox(height: 24),

                // Davet Kodu Inputu
                Text(l.t('tenant.home_code'))
                    .semiBold()
                    .small()
                    .foreground(),
                const m.SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  placeholder: Text(l.t('tenant.home_code')),
                  features: const [
                    InputLeadingFeature(
                      m.Icon(m.Icons.vpn_key_outlined, size: 18, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const m.SizedBox(height: 24),

                // Katıl Butonu
                Button.primary(
                  onPressed: _isLoading ? null : () async {
                    if (_codeController.text.trim().isEmpty) return;
                    setState(() => _isLoading = true);
                    // Mock API call
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (context.mounted) {
                      m.Navigator.pop(context);
                    }
                  },
                  child: _isLoading
                      ? const m.SizedBox(
                          width: 20,
                          height: 20,
                          child: m.CircularProgressIndicator(
                            strokeWidth: 2,
                            color: m.Colors.white,
                          ),
                        )
                      : Text(l.t('tenant.join_button')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
