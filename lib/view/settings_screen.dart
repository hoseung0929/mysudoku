import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: const CustomAppBar(title: '설정'),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 왼쪽 설정 목록
        SizedBox(
          width: 300,
          child: _buildSettingsList(),
        ),
        // 오른쪽 설정 콘텐츠
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildSettingsContent(),
          ),
        ),
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    return _buildSettingsList();
  }

  /// 설정 목록 위젯
  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          '알림',
          [
            _buildSettingsTile(
              icon: Icons.notifications,
              title: '알림 설정',
              subtitle: '게임 알림을 관리합니다',
              onTap: () {
                // 알림 설정 기능
              },
            ),
            _buildSettingsTile(
              icon: Icons.schedule,
              title: '알림 시간',
              subtitle: '알림을 받을 시간을 설정합니다',
              onTap: () {
                // 알림 시간 설정 기능
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          '외관',
          [
            _buildSettingsTile(
              icon: Icons.color_lens,
              title: '테마 설정',
              subtitle: '앱의 색상 테마를 변경합니다',
              onTap: () {
                // 테마 설정 기능
              },
            ),
            _buildSettingsTile(
              icon: Icons.brightness_6,
              title: '다크 모드',
              subtitle: '다크 모드를 켜거나 끕니다',
              onTap: () {
                // 다크 모드 설정 기능
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          '언어',
          [
            _buildSettingsTile(
              icon: Icons.language,
              title: '언어 설정',
              subtitle: '앱 언어를 변경합니다',
              onTap: () {
                // 언어 설정 기능
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          '정보',
          [
            _buildSettingsTile(
              icon: Icons.info,
              title: '앱 정보',
              subtitle: '앱 버전 및 개발자 정보',
              onTap: () {
                // 앱 정보 다이얼로그
              },
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: '개인정보처리방침',
              subtitle: '개인정보 수집 및 이용에 관한 안내',
              onTap: () {
                // 개인정보처리방침
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 설정 섹션 위젯
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// 설정 타일 위젯
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFB8E6B8).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF2C3E50),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF7F8C8D),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF7F8C8D),
      ),
      onTap: onTap,
    );
  }

  /// 설정 콘텐츠 위젯 (데스크톱용)
  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '게임 알림을 관리하고 설정할 수 있습니다.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '알림 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('게임 완료 알림'),
                  subtitle: const Text('게임을 완료했을 때 알림을 받습니다'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('일일 목표 알림'),
                  subtitle: const Text('일일 목표 달성 시 알림을 받습니다'),
                  value: false,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('힌트 사용 알림'),
                  subtitle: const Text('힌트를 사용할 때 알림을 받습니다'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
