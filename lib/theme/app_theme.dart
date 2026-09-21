import 'package:flutter/material.dart';

/// 语义色板：随明 / 暗主题切换，widget 一律通过 `context.palette` 取色，
/// 禁止再使用硬编码的静态色值。
///
/// 设计参考 iOS / 澎湃 OS 3 的现代化极简美学：
/// 微灰底 + 白卡片 + 极其克制的弥散投影；深色下改用低饱和深灰与描边构建层级。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.onPrimary,
    required this.expense,
    required this.expenseSoft,
    required this.income,
    required this.incomeSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.hairline,
    required this.snackbarBackground,
    required this.snackbarForeground,
    required this.isDark,
  });

  /// 全局底色：浅色为微灰，深色为近黑灰（避免纯黑刺眼）。
  final Color background;

  /// 卡片 / 弹窗表面色。
  final Color surface;

  /// 次级容器（输入框、内嵌统计条、分段控件底槽）。
  final Color surfaceMuted;

  /// 主色调：克制的薄荷冷色系。
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color onPrimary;

  /// 支出（暖红）/ 收入（青绿），深色下提亮以维持对比度。
  final Color expense;
  final Color expenseSoft;
  final Color income;
  final Color incomeSoft;

  /// 中性文字：主文本 / 辅助说明 / 更弱的提示与占位。
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  /// 极弱分割 / 描边色。
  final Color hairline;

  final Color snackbarBackground;
  final Color snackbarForeground;

  final bool isDark;

  // ------------------------------------------------------------ 预设

  static const AppPalette light = AppPalette(
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F5F7),
    primary: Color(0xFF14B3A0),
    primaryDark: Color(0xFF0E9384),
    primarySoft: Color(0xFFE6F7F4),
    onPrimary: Color(0xFFFFFFFF),
    expense: Color(0xFFF0655B),
    expenseSoft: Color(0xFFFDECEA),
    income: Color(0xFF2EB872),
    incomeSoft: Color(0xFFE8F7EF),
    textPrimary: Color(0xFF1B1D21),
    textSecondary: Color(0xFF9AA0A6),
    textHint: Color(0xFFC3C7CC),
    hairline: Color(0xFFF0F1F3),
    snackbarBackground: Color(0xFF2B3138),
    snackbarForeground: Color(0xFFFFFFFF),
    isDark: false,
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0F1113),
    surface: Color(0xFF191C1F),
    surfaceMuted: Color(0xFF24282C),
    primary: Color(0xFF2ED3BE),
    primaryDark: Color(0xFF14B3A0),
    primarySoft: Color(0xFF123431),
    onPrimary: Color(0xFF06231F),
    expense: Color(0xFFFF8A7A),
    expenseSoft: Color(0xFF3A2220),
    income: Color(0xFF4FD08C),
    incomeSoft: Color(0xFF1B3328),
    textPrimary: Color(0xFFEDF0F2),
    textSecondary: Color(0xFF9AA0A6),
    textHint: Color(0xFF6B7280),
    hairline: Color(0xFF2A2E33),
    snackbarBackground: Color(0xFF33383E),
    snackbarForeground: Color(0xFFEDF0F2),
    isDark: true,
  );

  // ------------------------------------------------------------ ThemeExtension

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryDark,
    Color? primarySoft,
    Color? onPrimary,
    Color? expense,
    Color? expenseSoft,
    Color? income,
    Color? incomeSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? hairline,
    Color? snackbarBackground,
    Color? snackbarForeground,
    bool? isDark,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      hairline: hairline ?? this.hairline,
      snackbarBackground: snackbarBackground ?? this.snackbarBackground,
      snackbarForeground: snackbarForeground ?? this.snackbarForeground,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      snackbarBackground:
          Color.lerp(snackbarBackground, other.snackbarBackground, t)!,
      snackbarForeground:
          Color.lerp(snackbarForeground, other.snackbarForeground, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// 让任意 widget 通过 `context.palette` 拿到当前色板。
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppRadius {
  const AppRadius._();

  /// 统一模块化卡片圆角。
  static const double card = 20.0;
  static const double sheet = 28.0;
  static const double chip = 12.0;
  static const double pill = 999.0;
  static const double input = 14.0;
}

class AppShadows {
  const AppShadows._();

  /// 极其克制的微弱弥散投影：black @ 4%，blur 12，offset (0, 4)。
  static final BoxShadow card = BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: 0.04),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  /// 底部悬浮组件（药丸导航 / FAB）使用的稍强投影。
  static final BoxShadow floating = BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: 0.08),
    blurRadius: 20,
    offset: const Offset(0, 6),
  );

  /// 深色模式下投影几乎不可见，改用 1px 描边勾勒卡片边界。
  static BoxBorder borderFor(AppPalette palette) =>
      palette.isDark ? Border.all(color: palette.hairline, width: 1) : const Border();
}

class AppSpacing {
  const AppSpacing._();

  static const double page = 16.0;
  static const double cardPadding = 20.0;
  static const double gap = 12.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final ColorScheme seed = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    );
    final ColorScheme scheme = seed.copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceMuted,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.surface,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
      // 底部弹窗统一大圆角。
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: palette.surface,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: palette.snackbarBackground,
        contentTextStyle: TextStyle(
          color: palette.snackbarForeground,
          fontSize: 14,
        ),
        actionTextColor: palette.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: palette.textHint, fontSize: 14),
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onPrimary;
          }
          return palette.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => Colors.transparent,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
