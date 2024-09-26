import 'package:flutter/material.dart';
import 'package:truotlo/src/database/home.dart';
import 'package:truotlo/src/config/api.dart';
import 'package:flutter_html/flutter_html.dart';

class ReferenceDetailPage extends StatefulWidget {
  final int id;

  const ReferenceDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  _ReferenceDetailPageState createState() => _ReferenceDetailPageState();
}

class _ReferenceDetailPageState extends State<ReferenceDetailPage> {
  final HomeDatabase homeDatabase = HomeDatabase();
  final ApiConfig apiConfig = ApiConfig();
  Map<String, dynamic> referenceDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReferenceDetails();
  }

  Future<void> _fetchReferenceDetails() async {
    setState(() {
      isLoading = true;
    });
    try {
      final details = await homeDatabase.fetchReferenceDetails(widget.id);
      setState(() {
        referenceDetails = details;
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải chi tiết tài liệu: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(referenceDetails['title'] ?? 'Chi tiết tài liệu'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày đăng: ${referenceDetails['published_at'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Số lượt xem: ${referenceDetails['views'] ?? 0}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (referenceDetails['content'] != null)
                      Html(
                        data: referenceDetails['content'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(16.0),
                          ),
                        },
                      )
                    else
                      const Text('Không có nội dung'),
                  ],
                ),
              ),
            ),
    );
  }
}