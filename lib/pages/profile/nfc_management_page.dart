import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/services/nfc_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NfcManagementPage extends StatefulWidget {
  const NfcManagementPage({super.key});

  @override
  State<NfcManagementPage> createState() => _NfcManagementPageState();
}

class _NfcManagementPageState extends State<NfcManagementPage> {
  List<dynamic> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await AuthService.getNFCTags();
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách thẻ: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startActivation() async {
    // 1. Kiểm tra NFC
    final available = await NfcService.isAvailable();
    if (!available) {
      if (mounted) {
        _showErrorDialog(
          'NFC không khả dụng trên thiết bị của bạn hoặc chưa được bật.',
        );
      }
      return;
    }

    // 2. Hiện Dialog hướng dẫn quét
    if (!mounted) return;
    _showScanningBottomSheet();
  }

  void _showScanningBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return _NfcScanWorkflow(
          onSuccess: () {
            Navigator.pop(context);
            _loadTags();
          },
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5ED),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'Quản lý thẻ NFC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _tags.isEmpty
          ? _buildEmptyState()
          : _buildTagList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startActivation,
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
        label: const Text(
          'Kích hoạt thẻ mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.rssSimple,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'Bạn chưa có thẻ NFC nào được kích hoạt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Liên kết thẻ NFC để người cứu hộ có thể nhanh chóng định danh và trợ giúp bạn trong tình huống khẩn cấp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        final isActive = tag['status'] == 'ACTIVE';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.primaryOrange : Colors.grey)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.rssSimple,
                  color: isActive ? AppColors.primaryOrange : Colors.grey,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag['name'] ?? 'Thẻ NFC của tôi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${tag['id']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryGreen
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Đang hoạt động' : 'Tạm khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primaryGreen
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, tag),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isActive ? 'Tạm khóa' : 'Kích hoạt lại'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa thẻ', style: TextStyle(color: Colors.red)),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(String action, dynamic tag) async {
    try {
      if (action == 'toggle') {
        final newStatus = tag['status'] == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
        await AuthService.updateNFCTagStatus(tag['id'], newStatus);
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn gỡ liên kết thẻ NFC này? Sau khi gỡ, người cứu hộ sẽ không thể quét thông tin từ thẻ này nữa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        await AuthService.deleteNFCTag(tag['id']);
      }
      _loadTags();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}

class _NfcScanWorkflow extends StatefulWidget {
  final VoidCallback onSuccess;
  const _NfcScanWorkflow({required this.onSuccess});

  @override
  State<_NfcScanWorkflow> createState() => _NfcScanWorkflowState();
}

class _NfcScanWorkflowState extends State<_NfcScanWorkflow> {
  String _status =
      'SCANNING_UID'; // SCANNING_UID, LINKING, WRITING, WRITING_RETRY, SUCCESS, ERROR
  String _message = 'Áp thẻ vào gần cảm biến NFC của điện thoại để bắt đầu...';
  String? _errorMessage;
  String? _pendingHashedId;

  @override
  void initState() {
    super.initState();
    _startActivation();
  }

  Future<void> _startActivation() async {
    debugPrint('NfcWorkflow: Starting activation process...');
    await NfcService.startSession(
      onTag: (tag) async {
        // 1. Lấy UID
        final uid = NfcService.getTagUid(tag);
        debugPrint('NfcWorkflow: Tag detected, UID = $uid');
        if (uid == null) {
          setState(() {
            _status = 'ERROR';
            _message = 'Không thể nhận diện định dạng thẻ này.';
          });
          return;
        }

        // 2. Kiểm tra xem có đang chờ ghi hay không (Retry write)
        if (_status == 'WRITING_RETRY' && _pendingHashedId != null) {
           debugPrint('NfcWorkflow: Retrying write for hashedId: $_pendingHashedId');
           setState(() {
             _status = 'WRITING';
             _message = 'Đang ghi lại mã bảo mật...';
           });
           
           try {
             final success = await NfcService.writeNdef(tag, _pendingHashedId!);
             if (success) {
                _onWriteSuccess();
             } else {
                setState(() {
                  _status = 'WRITING_RETRY';
                  _message = 'Thẻ không hỗ trợ ghi dữ liệu. Vui lòng thử thẻ khác.';
                });
             }
           } catch (e) {
             debugPrint('NfcWorkflow: Retry write failed: $e');
             setState(() {
               _status = 'WRITING_RETRY';
               _message = 'Vẫn chưa ghi được. Vui lòng CHẠM GIỮ THẺ lâu hơn một chút...';
             });
           }
           return; // <--- QUAN TRỌNG: Phải thoát ở đây để không Link lại
        }

        // 3. Link Backend (Flow bình thường)
        debugPrint('NfcWorkflow: Linking tag $uid with backend...');
        setState(() {
          _status = 'LINKING';
          _message = 'Đang đồng bộ với hệ thống...';
        });

        try {
          final res = await AuthService.linkNFCTag(uid, 'Thẻ NFC');
          final hashedId = res['hashedCitizenId'];
          _pendingHashedId = hashedId;
          debugPrint('NfcWorkflow: Linked successfully. Received HashedId: $hashedId');

          // 4. Ghi thẻ
          setState(() {
            _status = 'WRITING';
            _message =
                'Hệ thống đã nhận diện thành công!\nVui lòng GIỮ THẺ để ghi mã bảo mật...';
          });

          debugPrint('NfcWorkflow: Writing HashedId to tag...');
          try {
            final success = await NfcService.writeNdef(tag, hashedId);
            if (success) {
              _onWriteSuccess();
            } else {
              throw Exception('Hỗ trợ ghi NDEF thất bại.');
            }
          } catch (e) {
            debugPrint('NfcWorkflow: Write failed with: $e. Transitioning to WRITING_RETRY.');
            setState(() {
              _status = 'WRITING_RETRY';
              _message = 'Mất kết nối đột ngột!\nVui lòng CHẠM LẠI THẺ để hoàn tất.';
            });
            // Don't stop session here, we want it to stay active for the retry if possible, 
            // but usually nfc_manager stops it on error. 
            // So we'll restart it if needed in the build/retry button or automatically.
          }
        } catch (e) {
          debugPrint('NfcWorkflow: Error during workflow: $e');
          setState(() {
            _status = 'ERROR';
            _message = 'Lỗi xử lý';
            _errorMessage = e.toString();
          });
          await NfcService.stopSession(errorMessage: e.toString());
        }
      },
      onError: (error) async {
        debugPrint('NfcWorkflow: Session error: $error');
        // If we were writing and it failed, we might already handled it in onTag,
        // but if the session itself failed...
        if (_status == 'WRITING' || _status == 'WRITING_RETRY') {
           // Keep the status as WRITING_RETRY, but restart session if needed
           debugPrint('NfcWorkflow: Session lost during write. Ready for retry.');
           return; 
        }
        
        setState(() {
          _status = 'ERROR';
          _message = 'Lỗi NFC';
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _onWriteSuccess() async {
    debugPrint('NfcWorkflow: Write operation completed successfully.');
    setState(() {
      _status = 'SUCCESS';
      _message = 'Kích hoạt thẻ thành công!';
      _errorMessage = null;
    });
    await NfcService.stopSession();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) widget.onSuccess();
  }

  @override
  void dispose() {
    NfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      height: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: 30),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          if (_status == 'ERROR' || _status == 'WRITING_RETRY')
            ElevatedButton(
              onPressed: () {
                if (_status == 'WRITING_RETRY') {
                  // Just restart scanning to catch the tag and write
                  _startActivation(); 
                } else {
                  setState(() {
                    _status = 'SCANNING_UID';
                    _message = 'Áp thẻ vào gần cảm biến NFC của điện thoại...';
                    _errorMessage = null;
                  });
                  _startActivation();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                _status == 'WRITING_RETRY' ? 'Quét lại để ghi thẻ' : 'Thử lại',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (_status) {
      case 'SCANNING_UID':
      case 'WRITING':
      case 'WRITING_RETRY':
        return const _PulseNfcIcon();
      case 'LINKING':
        return const CircularProgressIndicator(color: AppColors.primaryOrange);
      case 'SUCCESS':
        return const Icon(
          PhosphorIconsFill.checkCircle,
          size: 80,
          color: AppColors.primaryGreen,
        );
      case 'ERROR':
        return const Icon(
          PhosphorIconsFill.xCircle,
          size: 80,
          color: Colors.red,
        );
      default:
        return const SizedBox();
    }
  }
}

class _PulseNfcIcon extends StatefulWidget {
  const _PulseNfcIcon();

  @override
  State<_PulseNfcIcon> createState() => _PulseNfcIconState();
}

class _PulseNfcIconState extends State<_PulseNfcIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryOrange.withOpacity(
              0.1 + (_controller.value * 0.2),
            ),
          ),
          child: Icon(
            PhosphorIconsFill.rssSimple,
            size: 80,
            color: AppColors.primaryOrange,
          ),
        );
      },
    );
  }
}
