import 'package:flutter/material.dart';
import 'package:truotlo/src/data/map/district_data.dart';
import 'package:truotlo/src/data/map/map_data.dart';

class MapMenu extends StatelessWidget {
  final List<MapStyleCategory> styleCategories;
  final String currentStyle;
  final bool isDistrictsVisible;
  final bool isBorderVisible;
  final bool isCommunesVisible;
  final bool isLandslidePointsVisible;
  final List<District> districts;
  final Map<int, bool> districtVisibility;
  final Map<String, bool> districtLandslideVisibility;
  final Function(String?) onStyleChanged;
  final Function(bool?) onDistrictsVisibilityChanged;
  final Function(bool?) onBorderVisibilityChanged;
  final Function(int, bool?) onDistrictVisibilityChanged;
  final Function(bool?) onCommunesVisibilityChanged;
  final Function(bool?) onLandslidePointsVisibilityChanged;
  final Function(String, bool?) onDistrictLandslideVisibilityChanged;
  final bool showOnlyLandslideRisk;
  final Function(bool?) onShowOnlyLandslideRiskChanged;

  const MapMenu({
    super.key,
    required this.styleCategories,
    required this.currentStyle,
    required this.isDistrictsVisible,
    required this.isBorderVisible,
    required this.districts,
    required this.districtVisibility,
    required this.onStyleChanged,
    required this.onDistrictsVisibilityChanged,
    required this.onBorderVisibilityChanged,
    required this.onDistrictVisibilityChanged,
    required this.isCommunesVisible,
    required this.onCommunesVisibilityChanged,
    required this.isLandslidePointsVisible,
    required this.onLandslidePointsVisibilityChanged,
    required this.districtLandslideVisibility,
    required this.onDistrictLandslideVisibilityChanged,
    required this.showOnlyLandslideRisk,  // Thêm vào đây
    required this.onShowOnlyLandslideRiskChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Tùy chọn bản đồ',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ExpansionTile(
            leading: const Icon(Icons.map),
            title: const Text('Bản đồ'),
            children: <Widget>[
              ...styleCategories.map((category) => ExpansionTile(
                    title: Text(category.name),
                    children: category.styles
                        .map((style) => RadioListTile<String>(
                              title: Text(style.name),
                              value: style.url,
                              groupValue: currentStyle,
                              onChanged: onStyleChanged,
                            ))
                        .toList(),
                  )),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Khu vực'),
            children: <Widget>[
              CheckboxListTile(
                title: const Text('Huyện'),
                value: isDistrictsVisible,
                onChanged: onDistrictsVisibilityChanged,
              ),
              CheckboxListTile(
                title: const Text('Ranh giới'),
                value: isBorderVisible,
                onChanged: onBorderVisibilityChanged,
              ),
              CheckboxListTile(
                title: const Text('Xã'),
                value: isCommunesVisible,
                onChanged: onCommunesVisibilityChanged,
              ),
              CheckboxListTile(
                title: const Text('Điểm trượt lở'),
                value: isLandslidePointsVisible,
                onChanged: onLandslidePointsVisibilityChanged,
              ),
            ],
          ),
          if (isDistrictsVisible)
            ExpansionTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Huyện'),
              children: districts
                  .map((district) => CheckboxListTile(
                        title: Text(district.name),
                        value: districtVisibility[district.id],
                        onChanged: (bool? value) =>
                            onDistrictVisibilityChanged(district.id, value),
                      ))
                  .toList(),
            ),
          if (isLandslidePointsVisible)
            ExpansionTile(
              leading: const Icon(Icons.filter_alt),
              title: const Text('Vị trí trượt lở theo huyện'),
              children: districtLandslideVisibility.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (bool? value) =>
                      onDistrictLandslideVisibilityChanged(entry.key, value),
                );
              }).toList(),
            ),
            if (isLandslidePointsVisible)
              CheckboxListTile(
                title: const Text('Chỉ hiện điểm trượt nông'),
                subtitle: const Text('Ẩn các điểm không có nguy cơ'),
                value: showOnlyLandslideRisk,
                onChanged: onShowOnlyLandslideRiskChanged,
              ),
        ],
      ),
    );
  }
}
