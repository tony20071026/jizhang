import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category_item.g.dart';

/// 记账分类。
///
/// 落库为 `HiveObject`，因此顺序、名称、图标、颜色都可由用户自由调整。
/// 图标以 `codePoint` 存储，读取时经 [CategoryIcons.resolve] 反查回
/// **常量** `IconData` —— 这样 release 构建的图标 tree-shaking 不会把
/// 用到的字形裁掉（动态 new IconData 会被裁掉，必须避免）。
@HiveType(typeId: 2)
class CategoryItem extends HiveObject {
  CategoryItem({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.isExpense,
    this.sortIndex = 0,
    this.builtIn = false,
  });

  /// 分类名称，同时写入 `TransactionItem.title`。
  @HiveField(0)
  String name;

  /// `IconData.codePoint`
  @HiveField(1)
  int iconCodePoint;

  /// `Color.toARGB32()`
  @HiveField(2)
  int colorValue;

  /// true = 支出分类，false = 收入分类。
  @HiveField(3)
  bool isExpense;

  /// 排序位（升序），拖拽排序即写回该字段。
  @HiveField(4)
  int sortIndex;

  /// 内置分类。内置分类可排序、可改名改图标，但不建议删除。
  @HiveField(5)
  bool builtIn;

  IconData get icon => CategoryIcons.resolve(iconCodePoint);

  Color get color => Color(colorValue);

  /// 浅色胶囊背景色（用于分类标签 / 图标底盘）。
  Color get softColor => color.withValues(alpha: 0.12);

  CategoryItem copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isExpense,
    int? sortIndex,
    bool? builtIn,
  }) {
    return CategoryItem(
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isExpense: isExpense ?? this.isExpense,
      sortIndex: sortIndex ?? this.sortIndex,
      builtIn: builtIn ?? this.builtIn,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
    'isExpense': isExpense,
    'sortIndex': sortIndex,
    'builtIn': builtIn,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      name: (json['name'] ?? '未命名').toString(),
      iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe5d3,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF9AA0A6,
      isExpense: json['isExpense'] != false,
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      builtIn: json['builtIn'] == true,
    );
  }
}

/// 图标查找表。
///
/// [choices] 中每一项都是 `Icons.*` 常量引用，编译器与 tree-shaker 都能看到
/// 它们被使用，因此 release 包里这些字形会被保留。
class CategoryIcons {
  const CategoryIcons._();

  /// 自定义分类时可选的图标全集（按场景分组，便于选择器排版）。
  static const List<IconData> choices = <IconData>[
    // 餐饮饮食
    Icons.restaurant_rounded,
    Icons.restaurant_menu_rounded,
    Icons.fastfood_rounded,
    Icons.lunch_dining_rounded,
    Icons.local_cafe_rounded,
    Icons.local_drink_rounded,
    Icons.emoji_food_beverage_rounded,
    Icons.cake_rounded,
    Icons.icecream_rounded,
    Icons.cookie_rounded,
    Icons.bakery_dining_rounded,
    Icons.local_pizza_rounded,
    Icons.rice_bowl_rounded,
    Icons.ramen_dining_rounded,
    Icons.set_meal_rounded,
    Icons.tapas_rounded,
    Icons.egg_alt_rounded,
    Icons.eco_rounded,
    // 购物服饰
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.storefront_rounded,
    Icons.local_mall_rounded,
    Icons.local_grocery_store_rounded,
    Icons.checkroom_rounded,
    Icons.diamond_rounded,
    Icons.spa_rounded,
    Icons.face_retouching_natural,
    // 居住日用
    Icons.home_rounded,
    Icons.house_rounded,
    Icons.apartment_rounded,
    Icons.chair_rounded,
    Icons.chair_alt_rounded,
    Icons.soap_rounded,
    Icons.local_laundry_service_rounded,
    Icons.cleaning_services_rounded,
    Icons.iron_rounded,
    Icons.lightbulb_rounded,
    Icons.water_drop_rounded,
    Icons.bolt_rounded,
    Icons.umbrella_rounded,
    Icons.door_sliding_rounded,
    Icons.yard_rounded,
    Icons.balcony_rounded,
    Icons.build_rounded,
    Icons.handyman_rounded,
    // 出行交通
    Icons.directions_bus_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bike,
    Icons.directions_run_rounded,
    Icons.train_rounded,
    Icons.motorcycle_rounded,
    Icons.local_shipping_rounded,
    Icons.flight_takeoff_rounded,
    Icons.luggage_rounded,
    Icons.airplane_ticket_rounded,
    Icons.hotel_rounded,
    Icons.beach_access_rounded,
    Icons.map_rounded,
    Icons.explore_rounded,
    // 娱乐运动
    Icons.sports_esports_rounded,
    Icons.sports_soccer_rounded,
    Icons.sports_tennis_rounded,
    Icons.fitness_center_rounded,
    Icons.movie_rounded,
    Icons.theater_comedy_rounded,
    Icons.museum_rounded,
    Icons.headphones_rounded,
    Icons.celebration_rounded,
    Icons.casino_rounded,
    // 通讯数码
    Icons.phone_android_rounded,
    Icons.devices_rounded,
    Icons.watch_rounded,
    Icons.sim_card_rounded,
    Icons.wifi_rounded,
    Icons.brush_rounded,
    Icons.palette_rounded,
    // 医疗健康
    Icons.medical_services_rounded,
    Icons.local_hospital_rounded,
    Icons.medication_rounded,
    Icons.vaccines_rounded,
    Icons.health_and_safety_rounded,
    Icons.favorite_rounded,
    // 学习办公
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.workspace_premium_rounded,
    Icons.business_center_rounded,
    Icons.receipt_long_rounded,
    // 人情往来
    Icons.groups_rounded,
    Icons.people_rounded,
    Icons.family_restroom_rounded,
    Icons.child_care_rounded,
    Icons.elderly_rounded,
    Icons.pets_rounded,
    Icons.card_giftcard_rounded,
    Icons.redeem_rounded,
    Icons.volunteer_activism_rounded,
    // 金融收支
    Icons.savings_rounded,
    Icons.account_balance_rounded,
    Icons.credit_card_rounded,
    Icons.trending_up_rounded,
    Icons.work_rounded,
    Icons.emoji_events_rounded,
    Icons.star_rounded,
    // 烟酒其他
    Icons.liquor_rounded,
    Icons.smoking_rooms_rounded,
    Icons.local_bar_rounded,
    Icons.wine_bar_rounded,
    Icons.more_horiz_rounded,
  ];

  /// 把 codePoint 反查回常量 `IconData`；未命中时回退到「其他」。
  static IconData resolve(int codePoint) {
    for (final IconData icon in choices) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }
    return Icons.more_horiz_rounded;
  }
}

/// 内置默认分类。
class CategoryDefaults {
  const CategoryDefaults._();

  /// 分类配色循环池（柔和低饱和，深浅色模式下都耐看）。
  static const List<Color> palette = <Color>[
    Color(0xFFF0655B),
    Color(0xFFF2994A),
    Color(0xFFF2C94C),
    Color(0xFF6FCF97),
    Color(0xFF2EB872),
    Color(0xFF14B3A0),
    Color(0xFF56CCF2),
    Color(0xFF4C8DF6),
    Color(0xFF9B6DF3),
    Color(0xFFF2A0C0),
    Color(0xFF9AA0A6),
    Color(0xFF7B8FA1),
  ];

  /// 33 个默认支出分类（顺序即默认展示顺序，前 8 个为常驻位）。
  static const List<String> expenseNames = <String>[
    '餐饮',
    '购物',
    '日用',
    '交通',
    '水果',
    '零食',
    '运动',
    '娱乐',
    '通讯',
    '服饰',
    '美容',
    '住房',
    '居家',
    '孩子',
    '长辈',
    '社交',
    '旅行',
    '烟酒',
    '数码',
    '汽车',
    '医疗',
    '书籍',
    '学习',
    '宠物',
    '礼金',
    '礼物',
    '办公',
    '维修',
    '捐赠',
    '彩票',
    '亲友',
    '快递',
    '饮料',
  ];

  /// 与 [expenseNames] 一一对应。
  static const List<IconData> expenseIcons = <IconData>[
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.soap_rounded,
    Icons.directions_bus_rounded,
    Icons.eco_rounded,
    Icons.cookie_rounded,
    Icons.fitness_center_rounded,
    Icons.sports_esports_rounded,
    Icons.phone_android_rounded,
    Icons.checkroom_rounded,
    Icons.spa_rounded,
    Icons.apartment_rounded,
    Icons.chair_rounded,
    Icons.child_care_rounded,
    Icons.elderly_rounded,
    Icons.groups_rounded,
    Icons.flight_takeoff_rounded,
    Icons.liquor_rounded,
    Icons.devices_rounded,
    Icons.directions_car_rounded,
    Icons.medical_services_rounded,
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.card_giftcard_rounded,
    Icons.redeem_rounded,
    Icons.business_center_rounded,
    Icons.handyman_rounded,
    Icons.volunteer_activism_rounded,
    Icons.casino_rounded,
    Icons.family_restroom_rounded,
    Icons.local_shipping_rounded,
    Icons.local_cafe_rounded,
  ];

  static const List<String> incomeNames = <String>[
    '工资',
    '奖金',
    '理财',
    '兼职',
    '红包',
    '其他',
  ];

  static const List<IconData> incomeIcons = <IconData>[
    Icons.work_rounded,
    Icons.emoji_events_rounded,
    Icons.trending_up_rounded,
    Icons.business_center_rounded,
    Icons.card_giftcard_rounded,
    Icons.more_horiz_rounded,
  ];

  /// 记账弹窗默认常驻显示的分类数量，其余折叠在「展开」之后。
  static const int pinnedCount = 8;

  /// 生成一套完整的默认分类（尚未写入 Hive）。
  static List<CategoryItem> build(bool isExpense) {
    final List<String> names = isExpense ? expenseNames : incomeNames;
    final List<IconData> icons = isExpense ? expenseIcons : incomeIcons;
    return List<CategoryItem>.generate(names.length, (int index) {
      return CategoryItem(
        name: names[index],
        iconCodePoint: icons[index].codePoint,
        colorValue: palette[index % palette.length].toARGB32(),
        isExpense: isExpense,
        sortIndex: index,
        builtIn: true,
      );
    });
  }
}
