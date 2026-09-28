import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/View/Notification.dart';
import 'package:mikk/View/SettingsScreen.dart';
import 'package:mikk/View/authScreen/sign_up.dart';
import 'package:mikk/View_Model/ProfileViewModel.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:provider/provider.dart';

import '../View_Model/auth_view_model.dart';
import '../services/local_storage_service.dart';
import 'ModelService.dart';


class AvatarDashBoard extends StatefulWidget {
  final  bool? isInitialScreen;

  const AvatarDashBoard({super.key, this.isInitialScreen});

  @override
  State<AvatarDashBoard> createState() => _AvatarDashBoardState();
}

class _AvatarDashBoardState extends State<AvatarDashBoard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Selected avatar index for each tab
  int? _selectedMaleIndex;
  int? _selectedFemaleIndex;


  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "";
  final ModelService _modelService = ModelService();

  // Replace these with your actual image paths
  final List<String> maleAvatars = [
    'assets/avatars/male_1.jpg',
    'assets/avatars/male_2.jpg',
    'assets/avatars/male_3.jpg',
    'assets/avatars/male_4.jpg',
    'assets/avatars/male_5.jpg',
  ];

  final List<String> femaleAvatars = [
    'assets/avatars/female_1.jpg',
    'assets/avatars/female_2.jpg',
    'assets/avatars/female_3.jpg',
    'assets/avatars/female_4.jpg',
    'assets/avatars/female_5.jpg',
  ];


  final List <String> maleFilename = [
    'male_1',
    'male_2',
    'male_3',
    'male_4',
    'male_5',
  ];


  final List <String> femaleFilename = [
    'female_1',
    'female_2',
    'female_3',
    'female_4',
    'female_5',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvatarGrid(
                      avatars: maleAvatars,
                      selectedIndex: _selectedMaleIndex,
                      onSelect: (index) {
                        setState(() {
                          _selectedMaleIndex = index;
                          _selectedFemaleIndex = null;
                        });
                      },
                      isMale: true,
                    ),
                    _buildAvatarGrid(
                      avatars: femaleAvatars,
                      selectedIndex: _selectedFemaleIndex,
                      onSelect: (index) {
                        setState(() {
                          _selectedFemaleIndex = index;
                          _selectedMaleIndex = null;
                        });
                      },
                      isMale: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progress overlay
          if (_isProcessing) _buildProgressOverlay(),
        ],
      ),
    );
  }




  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF0A0A0A).withOpacity(0.95),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.r,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Choose Avatar",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 36.w), // Balance for back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.09),
              Colors.white.withOpacity(0.09),
            ],
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.male, size: 22.r),
                SizedBox(width: 6.w),
                const Text('Male'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.female, size: 22.r),
                SizedBox(width: 6.w),
                const Text('Female'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid({
    required List<String> avatars,
    required int? selectedIndex,
    required Function(int) onSelect,
    required bool isMale,

  }) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMale ? "Select Male Avatar" : "Select Female Avatar",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                return _buildAvatarItem(
                  imagePath: avatars[index],
                  index: index,
                  isSelected: selectedIndex == index,
                  onTap: () => onSelect(index),
                  isMale: isMale,
                );
              },
            ),
          ),
          if (selectedIndex != null) ...[
            SizedBox(height: 16.h),
            _buildConfirmButton(
              isMale: isMale,
              selectedIndex: selectedIndex,


            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarItem({
    required String imagePath,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? (isMale ? Colors.blue : Colors.pink)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: (isMale ? Colors.blue : Colors.pink).withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Avatar Image
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isMale ? Icons.male : Icons.female,
                          size: 50.r,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Avatar ${index + 1}',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Gradient Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    'Avatar ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Selection Checkmark
              if (isSelected)
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: isMale ? Colors.blue : Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }





  Future<void> _handleAvatarSelection({
     required String selectedModel,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = "Processing your avatar...";
    });

    try {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      final uid = profileViewModel.currentUser?.userId;

      if (uid == null) {
        _showError("User not authenticated");
        return;
      }

      setState(() {
        _progress = 0.3;
        _statusMessage = "Generating your avatar...";
      });
      final String modelURL = await _getUniqueModelURL(selectedModel);
      print("✅ Model URL obtained: $modelURL");

      // STEP 2: Save user data with model info
      setState(() {
        _progress = 0.7;
        _statusMessage = "Saving your selection...";
      });
      await _saveAvatarData(
        uid: uid,
        modelURL: modelURL,

      );

      // STEP 3: Complete
      setState(() {
        _progress = 1.0;
        _statusMessage = "All done!";
      });

      print("🎉 Avatar selection complete!");

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context); // Or navigate to next screen
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _progress = 0.0;
        _statusMessage = "";
      });
      print("❌ Avatar selection error: $e");
      if (mounted) _showError("Failed to save avatar: $e");
    }
  }


  Future<String> _getUniqueModelURL(String selectedModel) async {
    try {
      final String modelURL = await _modelService.getUniqueModelURL('$selectedModel.glb');

      print("✅ Model URL received: $modelURL");

      // Optional: Track model access
      //   await _modelService.trackModelAccess(modelName);

      return modelURL;
    } catch (e) {
      print("❌ Error getting model URL: $e");
      throw Exception("Failed to generate avatar: $e");
    }
  }



  /// Save Avatar Data to Firestore
  Future<void> _saveAvatarData({
    required String uid,
    required String modelURL,

  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'modelURL': modelURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await LocalStorageService.saveModelURL(modelURL); // NEW


      print("✅ Avatar data saved successfully");
    } catch (e) {
      print("❌ Error saving avatar data: $e");
      throw e;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Progress Overlay Widget
  Widget _buildProgressOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60.r,
                height: 60.r,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _currentTabIndex == 0 ? Colors.blue : Colors.pink,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "${(_progress * 100).toInt()}%",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildConfirmButton({
    required bool isMale,
    required int selectedIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null
            : () {
          String selectedModel = isMale
              ? maleFilename[selectedIndex]
              : femaleFilename[selectedIndex];

          if (widget.isInitialScreen == false) {
            // Call the method for existing users (shows processing)
            _handleAvatarSelection(
                selectedModel: selectedModel
            );

          } else {
            // Navigate to signup for new users (NO processing, instant navigation)
            CommonMethods.goToNext(
              context,
              SignUpScreen(genderFilename: selectedModel),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isMale ? Colors.blue : Colors.pink,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 8,
          shadowColor: (isMale ? Colors.blue : Colors.pink).withOpacity(0.5),
        ),
        child: Text(
          _isProcessing
              ? 'Processing...'
              : 'Confirm Avatar ${selectedIndex + 1}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }







}