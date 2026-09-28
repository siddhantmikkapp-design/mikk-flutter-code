import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'AvatarUploadStatus.dart';
import 'avatar_sync_checker.dart';

class AvatarSyncIndicator extends StatefulWidget {
  final String uid;
  final bool showLabel;
  final bool compact;

  const AvatarSyncIndicator({
    super.key,
    required this.uid,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<AvatarSyncIndicator> createState() => _AvatarSyncIndicatorState();
}

class _AvatarSyncIndicatorState extends State<AvatarSyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onRetryTap() {
    AvatarUploadManager().retryPendingUploads();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Retrying avatar sync..."),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AvatarSyncChecker.watchAvatarStatus(widget.uid),
      builder: (context, firestoreSnapshot) {
        final avatarData = firestoreSnapshot.data;
        final isSynced = avatarData?['synced'] == true;
        final isFailed = avatarData?['failed'] == true;
        final hasFileName = avatarData?['fileName'] != null;

        // No avatar at all
        if (!hasFileName) {
          return const SizedBox.shrink();
        }

        // Synced successfully
        if (isSynced) {
          _pulseController.stop();
          return _buildSyncedIndicator();
        }

        // Use the upload manager stream for real-time upload status
        return StreamBuilder<AvatarUploadStatus>(
          stream: AvatarUploadManager().statusStream,
          builder: (context, uploadSnapshot) {
            final uploadStatus =
                uploadSnapshot.data ?? AvatarUploadManager().currentStatus;

            if (uploadStatus == AvatarUploadStatus.uploading) {
              _pulseController.repeat(reverse: true);
              return _buildUploadingIndicator();
            }

            if (isFailed ||
                uploadStatus == AvatarUploadStatus.failed) {
              _pulseController.stop();
              return _buildFailedIndicator();
            }

            // Pending
            if (uploadStatus == AvatarUploadStatus.pending) {
              _pulseController.repeat(reverse: true);
              return _buildPendingIndicator();
            }

            // Check SharedPreferences for pending uploads
            return FutureBuilder<bool>(
              future: AvatarUploadManager().hasPendingUploads(),
              builder: (context, pendingSnapshot) {
                if (pendingSnapshot.data == true) {
                  _pulseController.repeat(reverse: true);
                  return _buildPendingIndicator();
                }

                // Not synced but no pending uploads = failed silently
                if (!isSynced && hasFileName) {
                  return _buildFailedIndicator();
                }

                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSyncedIndicator() {
    if (widget.compact) {
      return Icon(Icons.cloud_done_rounded, color: Colors.green, size: 16.r);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done_rounded, color: Colors.green, size: 14.r),
          if (widget.showLabel) ...[
            SizedBox(width: 4.w),
            Text(
              "Synced",
              style: TextStyle(
                color: Colors.green,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    if (widget.compact) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: SizedBox(
              width: 14.r,
              height: 14.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                if (widget.showLabel) ...[
                  SizedBox(width: 6.w),
                  Text(
                    "Syncing...",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingIndicator() {
    return GestureDetector(
      onTap: _onRetryTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.orange, size: 14.r),
                  if (widget.showLabel) ...[
                    SizedBox(width: 4.w),
                    Text(
                      "Pending...",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFailedIndicator() {
    return GestureDetector(
      onTap: _onRetryTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.red, size: 14.r),
            if (widget.showLabel) ...[
              SizedBox(width: 4.w),
              Text(
                "Tap to retry",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}