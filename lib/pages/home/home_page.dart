import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Orange Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              TextSpan(text: 'Chào '),
                              TextSpan(
                                text: 'MAI NGUYỄN DUY KHÁNH',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Icon(PhosphorIconsRegular.bell, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatusChip(
                        PhosphorIconsRegular.shieldSlash, 'Chưa xác thực'),
                    const SizedBox(width: 10),
                    _buildStatusChip(
                        PhosphorIconsRegular.folderSimple, 'Chưa cập nhật hồ sơ'),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Khi bạn thấy người gặp nạn, người bị té ngã hoặc bất tỉnh?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Face Recognition Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhận diện',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'khuôn mặt',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlack,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.userFocus,
                                  color: Colors.white, size: 40),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // NFC and QR Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Đọc thẻ',
                          'NFC',
                          PhosphorIconsFill.rss,
                          AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildActionCard(
                          'Quét',
                          'Mã QR',
                          PhosphorIconsFill.qrCode,
                          AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Emergency Call Cards
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.secondaryBlack),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomAction(
                            PhosphorIconsFill.phone, 'Gọi 115', Colors.green),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        _buildBottomAction(PhosphorIconsFill.videoCamera,
                            'Video call trực tiếp', AppColors.primaryGreen),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsFill.house),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.userCircle),
            label: 'Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.clockCounterClockwise),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.article),
            label: 'Tin tức',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.gear),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.secondaryBlack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
