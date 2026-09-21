import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_scaffold.dart';
import 'services/category_service.dart';
import 'services/db_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 本地数据库必须先于 UI 初始化完成。
  await DBService.init();
  await CategoryService.init();

  // 竖屏锁定，贴合移动端记账场景。
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LedgerApp());
}

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 跟随系统（Android 12+ 的深色模式 / 省电自动切换）。
      themeMode: ThemeMode.system,
      builder: (BuildContext context, Widget? child) {
        final AppPalette palette = context.palette;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: palette.isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: palette.isDark
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: palette.background,
            systemNavigationBarIconBrightness: palette.isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child!,
        );
      },
      home: const MainScaffold(),
    );
  }
}
