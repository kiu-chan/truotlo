import 'package:flutter/material.dart';
import 'package:truotlo/src/page/home/home_page.dart';
import 'package:truotlo/src/page/chart/chart_page.dart';
import 'package:truotlo/src/page/map/map_page.dart';
import 'package:truotlo/src/page/mangage/manage_page.dart';
import 'package:truotlo/src/page/settings/settings_page.dart';
import 'package:truotlo/src/user/authService.dart';

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  SelectPageState createState() => SelectPageState();
}

class SelectPageState extends State<SelectPage> {
  bool _isLoggedIn = false;
  int currentindex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    bool loggedIn = await UserPreferences.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      const HomePage(),
      const MapboxPage(),
      if (_isLoggedIn) const ManagePage(),
      const ChartPage(),
      const SettingsPage(),
    ];
    return Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            color: Colors.white,
            key: ValueKey<int>(currentindex),
            child: pages[currentindex],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: (int index) {
              setState(() {
                currentindex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            currentIndex: currentindex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'Home'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined), label: 'Map'),
              if (_isLoggedIn)
                const BottomNavigationBarItem(
                  icon: Icon((Icons.manage_accounts)),
                  label: "Manage",
                ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.ssid_chart),
                label: "Chart",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ]));
  }
}
