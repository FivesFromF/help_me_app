import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryOrange,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryOrange,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Chính sách bảo mật',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(PhosphorIconsRegular.calendar, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Lần cập nhật cuối cùng: 01/01/2026',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.downloadSimple,
                    size: 18,
                    color: AppColors.primaryBlack,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tải bản PDF',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('1. Giới thiệu'),
              const _BodyText(
                'HelpMe ("chúng tôi") cam kết bảo vệ dữ liệu cá nhân của bạn. Chính sách này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ thông tin của bạn, tuân thủ Nghị định 13/2023/NĐ-CP, Luật Bảo vệ Dữ liệu Cá nhân số 91/2025/QH15 và Luật An ninh mạng 116/2025/QH15.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('2. Dữ liệu chúng tôi thu thập'),
              const _RichText(
                title: 'Thông tin cá nhân',
                content: 'Họ tên, ngày sinh, số CCCD, số điện thoại, ảnh đại diện.',
              ),
              const _RichText(
                title: 'Dữ liệu y tế',
                content: 'Nhóm máu, bệnh nền, tiền sử bệnh lý, dị ứng thuốc, thông tin người liên lạc khẩn cấp.',
              ),
              const _RichText(
                title: 'Dữ liệu sinh trắc học',
                content: 'Ảnh khuôn mặt 5 góc được chuyển đổi thành vector đặc trưng mã hoá. Ảnh gốc bị xoá ngay sau khi xử lý.',
              ),
              const _RichText(
                title: 'Dữ liệu sử dụng',
                content: 'Nhật ký truy cập hồ sơ, thời điểm và vai trò của người tra cứu.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('3. Mục đích sử dụng'),
              const _BodyText('Chúng tôi sử dụng dữ liệu của bạn để:'),
              const _Bullet('Nhận diện danh tính trong tình huống khẩn cấp'),
              const _Bullet('Cung cấp thông tin y tế cho nhân viên cấp cứu'),
              const _Bullet('Bảo mật và chống lạm dụng hệ thống'),
              const _Bullet('Cải thiện chất lượng dịch vụ'),
              const SizedBox(height: 20),
              const _SectionTitle('4. Cơ sở pháp lý xử lý dữ liệu'),
              const _Bullet('Sự đồng ý của bạn — khi đăng ký và khai báo thông tin'),
              const _Bullet('Tình huống khẩn cấp — Nghị định 13 cho phép xử lý dữ liệu không cần đồng ý khi mục đích là bảo vệ tính mạng, sức khoẻ con người'),
              const SizedBox(height: 20),
              const _SectionTitle('5. Chia sẻ dữ liệu'),
              const _BodyText(
                'Chúng tôi không bán dữ liệu của bạn. Dữ liệu chỉ được chia sẻ trong các trường hợp:',
              ),
              const _Bullet('Nhân viên y tế / cấp cứu được xác minh trong tình huống khẩn cấp'),
              const _Bullet('Bệnh viện đối tác có ký hợp đồng bảo mật ràng buộc'),
              const _Bullet('Yêu cầu của cơ quan nhà nước có thẩm quyền theo quy định pháp luật'),
              const SizedBox(height: 20),
              const _SectionTitle('6. Lưu trữ dữ liệu'),
              const _BodyText(
                'Toàn bộ dữ liệu được lưu trữ trên máy chủ đặt tại Việt Nam, tuân thủ yêu cầu của Luật An ninh mạng. Dữ liệu được mã hoá và bảo vệ theo tiêu chuẩn bảo mật quốc tế.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('7. Quyền của bạn'),
              const _BodyText('Bạn có quyền:'),
              const _Bullet('Xem toàn bộ dữ liệu cá nhân đang được lưu trữ'),
              const _Bullet('Chỉnh sửa thông tin khi có thay đổi'),
              const _Bullet('Xoá toàn bộ dữ liệu bằng cách yêu cầu huỷ tài khoản'),
              const _Bullet('Tra cứu nhật ký truy cập hồ sơ bất cứ lúc nào'),
              const _Bullet('Phản đối việc xử lý dữ liệu trong các trường hợp không khẩn cấp'),
              const _BodyText(
                '\nYêu cầu sẽ được xử lý trong vòng 30 ngày kể từ ngày nhận.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('8. Bảo mật dữ liệu'),
              const _BodyText(
                'Chúng tôi áp dụng các biện pháp bảo mật gồm: mã hoá dữ liệu truyền tải và lưu trữ, kiểm soát truy cập theo vai trò (Citizen / Healthcare Staff / Admin), giám sát và ghi log toàn bộ lượt truy cập hồ sơ, và hệ thống phát hiện xâm nhập.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('9. Thay đổi chính sách'),
              const _BodyText(
                'Khi có thay đổi quan trọng, chúng tôi sẽ thông báo qua ứng dụng hoặc email ít nhất 7 ngày trước khi có hiệu lực.',
              ),
              const SizedBox(height: 20),
              const _SectionTitle('10. Liên hệ'),
              const _BodyText('Mọi thắc mắc về chính sách bảo mật, vui lòng liên hệ:'),
              const _BodyText('Data Protection Officer (DPO) — HelpMe'),
              const _BulletText(title: 'Email', content: 'privacy@helpme.vn'),
              const _BulletText(title: 'Hotline', content: '1XXXXXXXXX'),
              const Padding(
                padding: EdgeInsets.only(left: 22),
                child: Text(
                  '(Thứ 2 đến Thứ 6 | 8 giờ đến 17 giờ)',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '© 2026 HelpMe.',
                  style: TextStyle(color: AppColors.primaryBlack, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: InkWell(
                  onTap: _scrollToTop,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, size: 20, color: AppColors.primaryBlack),
                      SizedBox(width: 4),
                      Text(
                        'Cuộn lên đầu trang',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryOrange,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryBlack,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  const _RichText({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.primaryBlack, fontSize: 15, height: 1.5),
          children: [
            TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.primaryBlack, fontSize: 15),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text: content,
                  style: title == 'Email' ? const TextStyle(color: AppColors.primaryGreen) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

