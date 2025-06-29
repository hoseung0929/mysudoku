import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showNotificationIcon;
  final bool showLogoutIcon;

  const CustomAppBar({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.showNotificationIcon = true,
    this.showLogoutIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : const Text('미사용'),
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
      actions: actions ?? _buildDefaultActions(context),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    final defaultActions = <Widget>[];

    if (showNotificationIcon) {
      defaultActions.add(
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('알림 기능은 아직 구현되지 않았습니다.'),
              ),
            );
          },
        ),
      );
    }

    if (showLogoutIcon) {
      defaultActions.add(
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그아웃'),
                content: const Text('정말 로그아웃 하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('로그아웃 되었습니다.'),
                        ),
                      );
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return defaultActions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
