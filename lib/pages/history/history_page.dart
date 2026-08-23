import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/history/widgets/history_cards.dart';
import 'package:help_me_app/pages/history/widgets/history_detail_sheets.dart';
import 'package:help_me_app/pages/history/widgets/history_dialogs.dart';
import 'package:help_me_app/pages/history/widgets/history_sheet.dart';
import 'package:help_me_app/pages/history/widgets/history_states.dart';
import 'package:help_me_app/pages/history/widgets/history_tokens.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Màn "Lịch sử hoạt động" của công dân, gồm ba tab:
///
/// 1. **Đã cấp quyền** — các phiên mình được xem hồ sơ y tế của nạn nhân.
/// 2. **Báo cáo sự cố** — các sự cố khẩn cấp mình đã gửi đi.
/// 3. **Được truy xuất** — nhật ký ai đã xem hồ sơ y tế của mình.
///
/// Toàn bộ phần dựng giao diện nằm trong `widgets/`; file này chỉ giữ việc
/// nạp dữ liệu và nối các mảnh lại với nhau.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _accessGranted = [];
  List<dynamic> _accessReceived = [];
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await AuthService.getHistory();
      if (mounted) {
        setState(() {
          _accessGranted = data['accessGranted'] as List<dynamic>? ?? [];
          _accessReceived = data['accessReceived'] as List<dynamic>? ?? [];
          _reports = data['reports'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Mở hồ sơ y tế của nạn nhân gắn với một phiên còn hiệu lực.
  Future<void> _openVictimRecord(BuildContext context, String victimId) async {
    showHistoryLoadingDialog(context);

    try {
      final result = await AuthService.getVictimSession(victimId);
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => IdentityResultPage(data: result)),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        showHistorySnack(
          context,
          'Lỗi tải hồ sơ nạn nhân: ${e.toString().replaceAll("Exception: ", "")}',
          tone: HistoryPalette.danger,
        );
      }
    }
  }

  void _openReportDetail(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDetailSheet(
        report: report,
        onOpenVictimRecord: (victimId) => _openVictimRecord(context, victimId),
      ),
    );
  }

  void _openAccessReceivedDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccessReceivedSheet(
        item: item,
        onComplain: (sessionId, responderName) => showHistoryComplaintDialog(
          context,
          sessionId: sessionId,
          responderName: responderName,
          onComplaintSubmitted: _loadHistory,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Khung màn hình
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HistoryPalette.canvas,
      appBar: AppBar(
        backgroundColor: HistoryPalette.surface,
        surfaceTintColor: HistoryPalette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        shape: const Border(bottom: BorderSide(color: HistoryPalette.border)),
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            color: HistoryPalette.inkMuted,
            tooltip: 'Tải lại',
            icon: const Icon(PhosphorIconsBold.arrowsClockwise, size: 20),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: _buildTabBar(),
        ),
      ),
      body: _isLoading
          ? const HistorySkeletonList()
          : _errorMessage != null
          ? HistoryErrorState(message: _errorMessage!, onRetry: _loadHistory)
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildAccessGrantedTab(),
                _buildReportsTab(),
                _buildAccessReceivedTab(),
              ],
            ),
    );
  }

  /// Bộ chuyển tab dạng "segmented control" nằm trong AppBar.
  Widget _buildTabBar() {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HistoryPalette.neutral.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(11),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: HistoryPalette.inkMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        splashBorderRadius: BorderRadius.circular(11),
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        tabs: const <Widget>[
          Tab(
            height: 38,
            child: Text(
              'Đã cấp quyền',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tab(
            height: 38,
            child: Text(
              'Báo cáo sự cố',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tab(
            height: 38,
            child: Text(
              'Được truy xuất',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapRefresh(Widget child) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryOrange,
      child: child,
    );
  }

  /// Danh sách chung cho cả ba tab: một dòng tóm tắt rồi tới các thẻ.
  Widget _buildList({
    required IconData introIcon,
    required String unit,
    required String description,
    required int itemCount,
    required Widget Function(int index) cardBuilder,
  }) {
    return _wrapRefresh(
      ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Chừa chỗ cho thanh điều hướng nổi của HomePage.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: itemCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return HistoryTabIntro(
              icon: introIcon,
              count: itemCount,
              unit: unit,
              description: description,
            );
          }
          return cardBuilder(index - 1);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tab 1 — Đã cấp quyền
  // ---------------------------------------------------------------------

  Widget _buildAccessGrantedTab() {
    if (_accessGranted.isEmpty) {
      return _wrapRefresh(
        const HistoryEmptyState(
          icon: PhosphorIconsRegular.firstAid,
          title: 'Chưa có phiên cứu trợ nào',
          subtitle:
              'Khi bạn quét NFC, QR hoặc khuôn mặt nạn nhân, phiên xem hồ sơ y tế sẽ hiển thị tại đây.',
        ),
      );
    }

    return _buildList(
      introIcon: PhosphorIconsRegular.firstAid,
      unit: 'phiên',
      description: 'Hồ sơ y tế bạn được phép xem sau khi quét nạn nhân.',
      itemCount: _accessGranted.length,
      cardBuilder: (index) => AccessGrantedCard(
        item: _accessGranted[index] as Map<String, dynamic>,
        onOpenRecord: (victimId) => _openVictimRecord(context, victimId),
        onBlocked: (status) =>
            showHistorySessionStatusDialog(context, status: status),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tab 2 — Báo cáo sự cố
  // ---------------------------------------------------------------------

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return _wrapRefresh(
        const HistoryEmptyState(
          icon: PhosphorIconsRegular.siren,
          title: 'Chưa có báo cáo sự cố nào',
          subtitle:
              'Các sự cố khẩn cấp bạn đã gửi đến tổng đài 114 và người thân sẽ hiển thị tại đây.',
        ),
      );
    }

    return _buildList(
      introIcon: PhosphorIconsRegular.siren,
      unit: 'báo cáo',
      description: 'Sự cố khẩn cấp bạn đã gửi đi từ hiện trường.',
      itemCount: _reports.length,
      cardBuilder: (index) {
        final item = _reports[index] as Map<String, dynamic>;
        return ReportCard(item: item, onTap: () => _openReportDetail(item));
      },
    );
  }

  // ---------------------------------------------------------------------
  // Tab 3 — Được truy xuất
  // ---------------------------------------------------------------------

  Widget _buildAccessReceivedTab() {
    if (_accessReceived.isEmpty) {
      return _wrapRefresh(
        const HistoryEmptyState(
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'Chưa có lượt truy xuất nào',
          subtitle:
              'Nhật ký bảo mật: Bất kỳ ai quét thẻ NFC hoặc mã QR hồ sơ y tế của bạn sẽ được ghi lại minh bạch tại đây.',
        ),
      );
    }

    return _buildList(
      introIcon: PhosphorIconsRegular.shieldCheck,
      unit: 'lượt',
      description: 'Nhật ký minh bạch: ai đã xem hồ sơ y tế của bạn.',
      itemCount: _accessReceived.length,
      cardBuilder: (index) {
        final item = _accessReceived[index] as Map<String, dynamic>;
        return AccessReceivedCard(
          item: item,
          onTap: () => _openAccessReceivedDetail(item),
        );
      },
    );
  }
}
