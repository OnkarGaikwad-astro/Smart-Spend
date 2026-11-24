import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../theme/app_theme.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    } catch (e) {
      debugPrint('[AboutDev] Launch error: $e');
    }
  }

  void _showMoreMenu(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.share_rounded, color: colors.primary),
                  title: Text(
                    'Share Developer Profile',
                    style: TextStyle(color: colors.textMain, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(
                      ShareParams(
                        text: "Check out Onkar Gaikwad's projects & portfolio: https://astronkar.in",
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: colors.secondary),
                  title: Text(
                    'Copy Developer Email',
                    style: TextStyle(color: colors.textMain, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'onkargaikwad3319@gmail.com',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(
                      const ClipboardData(text: 'onkargaikwad3319@gmail.com'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ??
        AppTheme.getDarkColors('ocean');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textMain, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About Developer',
          style: TextStyle(
            color: colors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: colors.textMain, size: 22),
            onPressed: () => _showMoreMenu(context, colors),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. Hero Profile Header: Centered Avatar, Name, Title, and IIT Gandhinagar Tag
            Center(
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.secondary,
                          colors.purple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/Onkar_Proff.png',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) {
                          // Fallback to onkar_proff.png or initials
                          return Image.asset(
                            'assets/onkar_proff.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx2, err2, stack2) {
                              return Container(
                                color: colors.surface2,
                                child: Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: colors.primary,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Onkar Gaikwad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      color: colors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developer · AI Student',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.purple.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.purple.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'IIT Gandhinagar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.purple,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. Card: "A little about me"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.borderSubtle == Colors.transparent
                      ? (isDark ? Colors.white10 : Colors.black12)
                      : colors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A little about me',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Hey! I'm Onkar 👋\n\n"
                    "I'm an AI student at IIT Gandhinagar who loves building apps, experimenting with new technologies, and turning random ideas into actual projects.\n\n"
                    "I enjoy working with AI, mobile and web development, and sometimes spend way too much time trying to make things work exactly the way I imagined.\n\n"
                    "Most of my projects start with a simple idea and a \"let's see if I can build this\" mindset.\n\n"
                    "Thanks for using my app! ❤️",
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Card: "Find me around the internet"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.borderSubtle == Colors.transparent
                      ? (isDark ? Colors.white10 : Colors.black12)
                      : colors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find me around the internet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textMain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // GitHub Button
                      Expanded(
                        child: _buildSocialLink(
                          context: context,
                          colors: colors,
                          icon: Icons.code_rounded,
                          title: 'GitHub',
                          url: 'https://github.com/OnkarGaikwad-astro',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Portfolio Button
                      Expanded(
                        child: _buildSocialLink(
                          context: context,
                          colors: colors,
                          icon: Icons.language_rounded,
                          title: 'Portfolio',
                          url: 'https://portfolio.astronkar.in',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // LinkedIn Button
                      Expanded(
                        child: _buildSocialLink(
                          context: context,
                          colors: colors,
                          icon: Icons.work_outline_rounded,
                          title: 'LinkedIn',
                          url: 'https://www.linkedin.com/in/onk4r/',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // 4. Footer: "Built with ❤️ and lots of debugging" & "SmartSpend · Version 1.0.0"
            Center(
              child: Column(
                children: [
                  Text(
                    'Built with ❤️ and lots of debugging',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SmartSpend · Version ${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLink({
    required BuildContext context,
    required AppColors colors,
    required IconData icon,
    required String title,
    required String url,
  }) {
    return Material(
      color: colors.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _launchExternalUrl(context, url),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.borderSubtle == Colors.transparent
                  ? Colors.white.withValues(alpha: 0.05)
                  : colors.borderSubtle,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colors.textMain),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
