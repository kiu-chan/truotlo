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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
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
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: moveToDefaultLocation,
            heroTag: 'moveToDefaultLocation',
            child: const Icon(Icons.home),
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
