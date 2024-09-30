import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'menu.dart';
import 'map_state.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

  @override
  MapboxPageState createState() => MapboxPageState();
}

class MapboxPageState extends State<MapboxPage> with MapState {
  @override
  void initState() {
    super.initState();
    connectToDatabase();
    initializeLocationService();
  }

  Widget buildRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'no_risk':
        return Image.asset('lib/assets/map/landslide_0.png',
            width: 16, height: 16);
      case 'very_low':
        return Image.asset('lib/assets/map/landslide_1.png',
            width: 16, height: 16);
      case 'low':
        return Image.asset('lib/assets/map/landslide_2.png',
            width: 16, height: 16);
      case 'medium':
        return Image.asset('lib/assets/map/landslide_3.png',
            width: 16, height: 16);
      case 'high':
        return Image.asset('lib/assets/map/landslide_4.png',
            width: 16, height: 16);
      case 'very_high':
        return Image.asset('lib/assets/map/landslide_5.png',
            width: 16, height: 16);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildLegend(String riskLevel, String text) {
    return Row(
      children: [
        buildRiskIcon(riskLevel),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget buildAdministrativeLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  void _showInfoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chú giải bản đồ'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Lớp hành chính:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                buildAdministrativeLegend('Ranh giới', Colors.pink),
                buildAdministrativeLegend('Ranh giới huyện', Colors.black),
                buildAdministrativeLegend('Ranh giới xã', Colors.grey),
                const SizedBox(height: 16),
                const Text('Điểm trượt lở:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                buildLegend('no_risk', 'Không có nguy cơ'),
                buildLegend('very_low', 'Rất thấp'),
                buildLegend('low', 'Thấp'),
                buildLegend('medium', 'Trung bình'),
                buildLegend('high', 'Cao'),
                buildLegend('very_high', 'Rất cao'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoPopup,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: MapMenu(
        styleCategories: styleCategories,
        currentStyle: currentStyle,
        isDistrictsVisible: isDistrictsVisible,
        isBorderVisible: isBorderVisible,
        isCommunesVisible: isCommunesVisible,
        isLandslidePointsVisible: isLandslidePointsVisible,
        districts: districts,
        districtVisibility: districtVisibility,
        districtLandslideVisibility: districtLandslideVisibility,
        onStyleChanged: changeMapStyle,
        onDistrictsVisibilityChanged: toggleDistrictsVisibility,
        onBorderVisibilityChanged: toggleBorderVisibility,
        onCommunesVisibilityChanged: toggleCommunesVisibility,
        onLandslidePointsVisibilityChanged: toggleLandslidePointsVisibility,
        onDistrictVisibilityChanged: toggleDistrictVisibility,
        onDistrictLandslideVisibilityChanged: toggleDistrictLandslideVisibility,
      ),
      body: Stack(
        children: [
          MapboxMap(
            accessToken: mapToken,
            initialCameraPosition: CameraPosition(
              target: defaultTarget,
              zoom: defaultZoom,
            ),
            styleString: currentStyle,
            onStyleLoadedCallback: onStyleLoaded,
            onMapCreated: onMapCreated,
          ),
          buildRouteInfo(),
          if (currentLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: Text(
                  'Vị trí cá nhân hiện tại: ${currentLocation!.latitude.toStringAsFixed(6)}, ${currentLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: moveToCurrentLocation,
            heroTag: 'moveToCurrentLocation',
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: moveToDefaultLocation,
            heroTag: 'moveToDefaultLocation',
            backgroundColor: Colors.white,
            child: const Icon(Icons.home, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationService.stopLocationUpdates();
    mapController.onSymbolTapped.remove(onSymbolTapped);
    super.dispose();
  }
}
