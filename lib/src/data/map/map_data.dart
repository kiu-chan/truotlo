class MapStyle {
  final String name;
  final String url;

  MapStyle(this.name, this.url);
}

class MapStyleCategory {
  final String name;
  final List<MapStyle> styles;

  MapStyleCategory(this.name, this.styles);
}