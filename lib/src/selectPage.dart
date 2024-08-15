import 'package:flutter/material.dart';

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  _SelectPageState createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  int currentindex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];
    return Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            color: Colors.white,
            key: ValueKey<int>(currentindex),
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
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined), label: 'Map'),
              BottomNavigationBarItem(
                icon: Icon((Icons.cloud_queue)),
                label: "Forecast",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.ssid_chart),
                label: "Chart",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ]));
  }
}
