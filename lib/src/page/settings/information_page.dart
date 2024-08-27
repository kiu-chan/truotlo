import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giới thiệu hệ thống Dự báo và cảnh báo trượt lở thời gian thực tỉnh Bình Định',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Khu vực trọng điểm sử dụng trong đề tài nghiên cứu được hiểu là các khu vực có đông dân cư sinh sống, đặc biệt là các đô thị, các tuyến giao thông tỉnh lộ quan trọng, ảnh hưởng đến lưu thông trong khu vực, các khu vực hồ chứa nước thủy lợi có khả năng đe dọa các khu vực dân cư dưới hạ lưu. Trong năm 2021 vừa qua, bên cạnh 12 khu vực nguy cơ cao về trượt lở trong tỉnh, một số khu vực mới đã phát sinh với quy mô và mức độ rất lớn như ở Phù Cát, An Lão, Vĩnh Thạnh như sau:',
            ),
            const SizedBox(height: 16),
            _buildBulletPoint('Huyện Hoài Ân có 4 điểm'),
            _buildBulletPoint('Huyện An Lão còn có 3 điểm nguy cơ trượt lở ảnh hưởng đến tính mạng và tài sản người dân'),
            _buildBulletPoint('Huyện Vĩnh Thạnh có 2 điểm'),
            _buildBulletPoint('Huyện Phù Cát có 2 điểm'),
            _buildBulletPoint('Thành phố Quy Nhơn'),
            const SizedBox(height: 16),
            const Text(
              'Các khu vực mới phát sinh tại biển trượt lở đã ít nhiều gây khó khăn và bất ngờ với chính quyền và người dân địa phương. Dưới ảnh hưởng của sự gia tăng các hoạt động nhân sinh trên sườn dốc, xây dựng và mở rộng các tuyến giao thông, khai thác vật liệu xây dựng, tai biến trượt lở đất, đá có khả năng tăng cao trong thời gian tới tại tỉnh Bình Định.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngoài ra, đối với điều kiện thực tế của Việt Nam nói chung, tỉnh Bình Định nói riêng, khi các nguồn lực còn hạn chế, việc chủ động ứng phó với tai biến trượt lở là vô cùng quan trọng. Nội dung này bao gồm các hoạt động chuẩn bị ứng phó từ trước, trong và sau khi tai biến có thể xảy ra. Ứng phó chủ động nhắm mạnh vào các hoạt động chuẩn bị trước tai biến, hình thành cơ chế ứng phó tập trung vào giảm thiểu, phòng tránh, mức độ sẵn sàng để cải tạo, tái xây dựng và phục hồi sau tai biến. Công nghệ dự báo và cảnh báo sớm trượt lở đất, đá có vai trò quan trọng là thông tin đầu vào phục vụ hiệu quả cho công tác chủ động ứng phó hiện tại.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Xuất phát từ các thực tế trên, việc nghiên cứu hoàn thiện và triển khai kết quả ứng dụng công nghệ GIS, viễn thám, địa kỹ thuật, trí tuệ nhân tạo để khoảnh vùng và cảnh báo tình trạng trượt lở đất, đá tại các khu vực trọng điểm phục vụ phòng chống thiên tai tại tỉnh Bình Định là rất cần thiết.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}