import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineMode = true;
  bool _autoTranslate = false;
  bool _speechEnabled = true;
  bool _notificationsEnabled = true;
  String _selectedTheme = 'Dark';
  String _selectedFontSize = 'Medium';

  final List<String> _themes = ['Dark', 'Light', 'Auto'];
  final List<String> _fontSizes = ['Small', 'Medium', 'Large'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General'),
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildSectionTitle('Translation'),
            _buildTranslationSettings(),
            const SizedBox(height: 24),
            _buildSectionTitle('Appearance'),
            _buildAppearanceSettings(),
            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            _buildAboutSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Support'),
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Offline Mode',
            subtitle: 'Use only downloaded models',
            value: _offlineMode,
            onChanged: (value) => setState(() => _offlineMode = value),
            icon: Icons.cloud_off,
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Auto Translate',
            subtitle: 'Automatically translate detected text',
            value: _autoTranslate,
            onChanged: (value) => setState(() => _autoTranslate = value),
            icon: Icons.auto_awesome,
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Speech Recognition',
            subtitle: 'Enable voice input',
            value: _speechEnabled,
            onChanged: (value) => setState(() => _speechEnabled = value),
            icon: Icons.mic,
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Notifications',
            subtitle: 'Show translation notifications',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            icon: Icons.notifications,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildListTile(
            title: 'Download Models',
            subtitle: 'Manage offline translation models',
            icon: Icons.download,
            onTap: () => _showModelDownloadDialog(),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Translation History',
            subtitle: 'View and manage translation history',
            icon: Icons.history,
            onTap: () => _showHistoryDialog(),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            icon: Icons.cleaning_services,
            onTap: () => _showClearCacheDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildDropdownTile(
            title: 'Theme',
            subtitle: 'Choose your preferred theme',
            value: _selectedTheme,
            options: _themes,
            onChanged: (value) => setState(() => _selectedTheme = value!),
            icon: Icons.palette,
          ),
          _buildDivider(),
          _buildDropdownTile(
            title: 'Font Size',
            subtitle: 'Adjust text size',
            value: _selectedFontSize,
            options: _fontSizes,
            onChanged: (value) => setState(() => _selectedFontSize = value!),
            icon: Icons.text_fields,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildListTile(
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
            icon: Icons.info,
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            icon: Icons.privacy_tip,
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Terms of Service',
            subtitle: 'App usage terms',
            icon: Icons.description,
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildListTile(
            title: 'Help Center',
            subtitle: 'Get help and support',
            icon: Icons.help_center,
            onTap: () => _launchUrl('https://example.com/help'),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Contact Us',
            subtitle: 'Send feedback or report issues',
            icon: Icons.contact_support,
            onTap: () => _launchUrl('mailto:support@example.com'),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Rate App',
            subtitle: 'Rate us on the app store',
            icon: Icons.star,
            onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.example.app'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF667eea), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF667eea),
        activeTrackColor: const Color(0xFF667eea).withOpacity(0.3),
        inactiveThumbColor: Colors.grey[600],
        inactiveTrackColor: Colors.grey[800],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF667eea), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF667eea), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF2A2F4A),
        style: GoogleFonts.poppins(color: Colors.white),
        underline: const SizedBox(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[800],
      height: 1,
      indent: 56,
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not launch $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching URL: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showModelDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Download Models',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Download offline translation models for better performance and privacy.',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            _buildModelItem('Nepali ↔ English', '12.5 MB', true),
            _buildModelItem('Sinhalese ↔ English', '11.2 MB', false),
            _buildModelItem('Hindi ↔ English', '8.7 MB', true),
            _buildModelItem('Tamil ↔ English', '9.1 MB', false),
            _buildModelItem('Marathi ↔ English', '7.8 MB', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: Text(
              'Download All',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem(String name, String size, bool isDownloaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F4A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isDownloaded ? Icons.check_circle : Icons.download,
            color: isDownloaded ? Colors.green : const Color(0xFF667eea),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            size,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Translation History',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'View and manage your translation history. You can clear old translations to free up space.',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: Text(
              'Clear History',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Clear Cache',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'This will clear all cached data and free up storage space. Downloaded models will not be affected.',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: Text(
              'Clear Cache',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
