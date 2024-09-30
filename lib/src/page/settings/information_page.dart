import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:truotlo/src/database/database.dart';
class InformationPage extends StatefulWidget {
  const InformationPage({Key? key}) : super(key: key);

  @override
  InformationPageState createState() => InformationPageState();
}

class InformationPageState extends State<InformationPage> {
  final DefaultDatabase database = DefaultDatabase();
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      await database.connect();
      final content = await database.fetchAboutContent();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Error loading content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Html(
                data: _content,
                style: {
                  "body": Style(
                    fontSize: FontSize(16.0),
                    fontFamily: 'Arial, Helvetica, sans-serif',
                  ),
                  "h1": Style(
                    fontSize: FontSize(24.0),
                    fontWeight: FontWeight.bold,
                  ),
                  "h2": Style(
                    fontSize: FontSize(20.0),
                    fontWeight: FontWeight.bold,
                  ),
                  "p": Style(
                    margin: Margins(bottom: Margin(10)),
                  ),
                },
              ),
            ),
    );
  }
}