import 'package:flutter/material.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  ManagePageState createState() => ManagePageState();
}

class ManagePageState extends State<ManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage'),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ExpansionTile(
              leading: Icon(Icons.api),
              title: Text('Hành chính'),
              children: [
                ListTile(
                  title: Text('Dự báo 5 ngày'),
                ),
                ListTile(
                  title: Text('Cảnh báo theo giờ'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Manage Page'),
      ),
    );
  }
}
