import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String colorCode;
  final String profileId;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorCode,
    required this.profileId,
  });

  Color get color => _parseHexColor(colorCode);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      colorCode: json['color_code']?.toString() ?? '#5A8DF3',
      profileId: json['profile_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_code': colorCode,
      'profile_id': profileId,
    };
  }

  static Color _parseHexColor(String value) {
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return const Color(0xFF5A8DF3);
    }

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return const Color(0xFF5A8DF3);
    }
    return Color(parsed);
  }
}

