import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom-of-page branding footer with a background image + dark overlay,
/// app logo, tagline, social links, and copyright/version line.
///
/// Usage: add as the last child in your home page's scroll view, e.g.
///
/// SingleChildScrollView(
///   child: Column(
///     children: [
///       ...sections,
///       const AppFooterBranding(),
///     ],
///   ),
/// )
class AppFooterBranding extends StatelessWidget {
  const AppFooterBranding({
    super.key,
    this.backgroundImage = 'assets/images/FooterBanner.png',
    this.appName = 'Instant Delivery',
    this.version = 'v1.0.0',
    this.instagramUrl,
    this.twitterUrl,
    this.facebookUrl,
    this.supportEmail,
  });

  final String backgroundImage;
  final String appName;
  final String version;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? facebookUrl;
  final String? supportEmail;

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return ClipRRect(
      // borderRadius: BorderRadius.circular(16),
      child: Container(
        // margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.55),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),

              // Social row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIcon(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _openLink(instagramUrl!),
                  ),

                  _SocialIcon(
                    icon: Icons.alternate_email_rounded,
                    onTap: () => _openLink(twitterUrl!),
                  ),

                  _SocialIcon(
                    icon: Icons.facebook_outlined,
                    onTap: () => _openLink(facebookUrl!),
                  ),

                  _SocialIcon(
                    icon: Icons.mail_outline_rounded,
                    onTap: () => _openLink('mailto:$supportEmail'),
                  ),
                ],
              ),
              // Copyright / version
              Text(
                '© $year $appName · $version',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: const Color.fromARGB(255, 239, 41, 41).withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}
