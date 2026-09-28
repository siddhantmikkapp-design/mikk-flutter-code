import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikk/Model/auth/SignUpModel.dart';
import 'package:mikk/View/authScreen/sign_up.dart';
import 'package:mikk/View_Model/ProfileViewModel.dart';
import 'package:mikk/resources/CustomRaisedButton.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/resources/TextWidget.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:provider/provider.dart';
import 'package:mikk/resources/loader.dart';
import '../../View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';
import '../../View_Model/auth_view_model.dart';
import '../../resources/CustomTextField.dart';
import '../../utils/SessionManager.dart';
import '../../values/Color.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
 // AuthViewModel authVM = AuthViewModel();
 // late PersonalInformationViewModel personalInfoVM;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    fillData();
  }

  fillData() {
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
    _nameController.text = profileVM.currentUser?.name ?? '';

  //  personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
    /*personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
    personalInfoVM.updateController(isName: true, data: await SessionManager.getStringData(SessionManager.FULL_NAME));
    personalInfoVM.updateController(isMobileName: true, data: await SessionManager.getStringData(SessionManager.MOBILE));
    personalInfoVM.updateController(isEmailName: true, data: await SessionManager.getStringData(SessionManager.EMAIL));
    personalInfoVM.updateController(isUserName: true, data: await SessionManager.getStringData(SessionManager.USER_NAME));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonalInformationViewModel>(context, listen: false).setCurrentUserData();
    });*/
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _nameController.dispose();
  }


  void saveInfo(ProfileViewModel viewModel) async {

    final savedName = _nameController.text;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(viewModel.currentUser?.userId)
          .update({
        'name': savedName,
      });



      // --- Success Toast Message ---
      Fluttertoast.showToast(
        msg: "Profile name updated successfully!",
        toastLength: Toast.LENGTH_SHORT, // Duration (SHORT or LONG)
        gravity: ToastGravity.BOTTOM,    // Location on screen
        timeInSecForIosWeb: 1,           // Duration for iOS/Web
        backgroundColor: Colors.green,   // Background color
        textColor: Colors.white,         // Text color
        fontSize: 16.0,                  // Font size
      );

    } catch (e) {
      print("Error updating name in Firestore: $e");

      // --- Error Toast Message ---
      Fluttertoast.showToast(
        msg: "Failed to update profile: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 50.h),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 40.h),
                    _buildUserNameField(viewModel),
                    SizedBox(height: 20.h),
                    _buildNameField(viewModel),
                    SizedBox(height: 20.h),
                    _buildEmailField(viewModel),
                    SizedBox(height: 20.h),
                  //  _buildDOBField(viewModel),
                  //  SizedBox(height: 20.h),
                  //  _buildMobileField(viewModel),
                  //  SizedBox(height: 32.h),
                    _buildSaveButton(viewModel),
                    SizedBox(height: 16.h),
                   // _buildLogoutButton(),
                  ],
                ),
              ),
           //   if (viewModel.isLoader) Loader(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        TextWidget(
          txt: "Personal Information",
          fontSize: 26,
          fontWeight: FontSizeAndWidth.bold,
          color: Colors.white,
        ),
        SizedBox(height: 8.h),
        TextWidget(
          txt: "Update your profile details",
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white60,
        ),
      ],
    );
  }

  Widget _buildUserNameField(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CustomTextField(
        hintText: "Enter your ID",
        labelText: "ID",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: TextEditingController(text: viewModel.currentUser?.id),
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        readOnly: true,
        labelColor: Colors.white70,
        prefixIcon: Icon(
          Icons.alternate_email,
          color: Colors.white.withOpacity(0.7),
          size: 22.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      ),
    );
  }

  Widget _buildNameField(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CustomTextField(
        hintText: "Enter Name",
        labelText: "Name",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: _nameController,
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.white.withOpacity(0.7),
          size: 22.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      ),
    );
  }

  Widget _buildEmailField(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CustomTextField(
        hintText: "Enter Gender",
        labelText: "Gender",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: TextEditingController(text: viewModel.currentUser?.gender),
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        readOnly: true,
        prefixIcon: Icon(
          Icons.accessibility_rounded,
          color: Colors.white.withOpacity(0.7),
          size: 22.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      ),
    );
  }

  Widget _buildDOBField(PersonalInformationViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CustomTextField(
        hintText: "Enter BirthDate in DD-MM-YYYY",
        labelText: "BirthDate",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: viewModel.dobController,
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        prefixIcon: Icon(
          Icons.cake_outlined,
          color: Colors.white.withOpacity(0.7),
          size: 22.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      ),
    );
  }

  Widget _buildMobileField(PersonalInformationViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CustomTextField(
        hintText: "Enter Gender",
        labelText: "Gender",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: viewModel.mobileController,
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        prefixIcon: Icon(
          Icons.male,
          color: Colors.white.withOpacity(0.7),
          size: 22.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      ),
    );
  }

  Widget _buildSaveButton(ProfileViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor2, primaryColor2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {

            saveInfo(viewModel);

           /* SignUpModel userData = SignUpModel(
              userName: viewModel.userNameController.text,
              name: viewModel.nameController.text,
              doB: viewModel.dobController.text,
              email: viewModel.emailController.text,
              number: viewModel.mobileController.text,
            );
            viewModel.updateUserData(updatedFields: userData.toJson());*/
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Uncomment when needed
            // AuthViewModel().signOut().then((value) {
            //   CommonMethods.goToNextWithRemoveUntil(context, const SignUpScreen());
            // });
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.white70,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


