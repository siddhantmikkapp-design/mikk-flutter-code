import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/View/AvatarCreator/AvatarCreatorScreen.dart';
import 'package:mikk/View_Model/auth_view_model.dart';
import 'package:mikk/resources/CustomRaisedButton.dart';
import 'package:mikk/resources/CustomTextField.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/resources/TextWidget.dart';
import 'package:mikk/resources/loader.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:mikk/values/Color.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Demo/ModelService.dart';
import '../../services/local_storage_service.dart';



class SignUpScreen extends StatefulWidget {
  final String genderFilename;


  const SignUpScreen({super.key, required this.genderFilename});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "";
  final ModelService _modelService = ModelService();

  @override
  void initState() {
    super.initState();
  }


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<AuthViewModel>(
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
                    SizedBox(height: 60.h),
                    _buildNameField(viewModel),
                    SizedBox(height: 32.h),
                    _buildGenderField(
                      labelText: "Gender",
                      errorText: viewModel.errorList[5],
                      viewModel: viewModel,
                    ),
                    SizedBox(height: 32.h),
                    _buildBirthDateField(viewModel), // NEW
                    SizedBox(height: 32.h),
                    _buildLoginButton(viewModel),
                    SizedBox(height: 20.h),
                    _buildTermsAndPrivacy()
                  ],
                ),
              ),
              if (_isProcessing) Loader(),
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
          txt: "MiKK",
          fontSize: 32,
          fontWeight: FontSizeAndWidth.bold,
          color: Colors.white,
        ),
        SizedBox(height: 8.h),
        TextWidget(
          txt: "Enter your name to continue",
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white60,
        ),
      ],
    );
  }

  Widget _buildNameField(AuthViewModel viewModel) {
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
        hintText: "Enter your name",
        labelText: "Name",
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        controller: viewModel.nameController,
        errorText: viewModel.errorList[0],
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



  Widget _buildGenderField({
    required String labelText,
    String? errorText,
    required AuthViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wc_outlined, color: Colors.white.withOpacity(0.7), size: 22.r),
                  SizedBox(width: 12.w),
                  TextWidget(
                    txt: labelText,
                    fontSize: 14,
                    fontWeight: FontSizeAndWidth.medium,
                    color: Colors.white70,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _buildGenderOption("male", viewModel)),
                  SizedBox(width: 10.w),
                  Expanded(child: _buildGenderOption("female", viewModel)),

                ],
              ),
            ],
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 6.h),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, AuthViewModel viewModel) {
    final isSelected = viewModel.selectedGender == gender;
    return GestureDetector(
      onTap: () => viewModel.setGender(gender),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [primaryColor2, primaryColor2],
          )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBirthDateField(AuthViewModel viewModel) {
    final errorText = viewModel.errorList.length > 6 ? viewModel.errorList[6] : null;
    final selectedDate = viewModel.selectedBirthDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickBirthDate(viewModel),
          child: Container(
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: Colors.white.withOpacity(0.7), size: 22.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
                        : "Date of birth",
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedDate != null ? Colors.white : Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.5), size: 18.r),
              ],
            ),
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 6.h),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickBirthDate(AuthViewModel viewModel) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day), // sensible default
      firstDate: DateTime(now.year - 100),
      lastDate: now, // can't pick a future birthdate
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor2,
              surface: const Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.setBirthDate(picked);
    }
  }


  Widget _buildLoginButton(AuthViewModel viewModel) {
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
            if (viewModel.validateName() && viewModel.validateGender() &&  viewModel.validateAge()) {
          //    CommonMethods.goToNext(context, AvatarCreatorScreen(gender: viewModel.selectedGender ?? 'male', isProfile: false));
              _handleSignupFlow(viewModel);


            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Text(
              "Next",
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


  Future<void> _handleSignupFlow(AuthViewModel viewModel) async {
    if (_isProcessing) return;


    setState(() {
      _isProcessing = true;

      _progress = 0.0;
      _statusMessage = "Creating your account...";
    });

    try {
      // STEP 1: Sign in anonymously FIRST (we need UID for file name)
      setState(() {
        _isProcessing = true;

        _progress = 0.2;
        _statusMessage = "Creating your account...";
      });

      await viewModel.signInAnonymously();

      if (viewModel.user == null) {
        setState(() {
          _isProcessing = false;
          _progress = 0.0;
          _statusMessage = "Setting Up";
        });
        _showError("Failed to create account. Please try again.");
        return;
      }

      final uid = viewModel.user!.uid;
      print("Signed in with UID: $uid");

      // STEP 2: Save FCM token
      setState(() {
        _isProcessing = true;

        _progress = 0.4;
        _statusMessage = "Setting up notifications...";
      });
      await _saveFcmToken(uid);

      // STEP 3: Save user data to Firestore
      setState(() {
        _isProcessing = true;

        _progress = 0.55;
        _statusMessage = "Saving your FCM...";
      });

      final String modelURL = await _getUniqueModelURL();

      // STEP 4: Complete
      setState(() {
        _isProcessing = true;

        _progress = 0.75;
        _statusMessage = "Saving Your Information";
      });


      await _saveUserData(uid, viewModel, modelURL);

      setState(() {

        _progress = 1.0;
        _statusMessage = "All done!";
      });

      print("Signup complete!");

      // Navigate to next screen after a short delay
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // Navigate to Avatar Creator or Home Screen
      viewModel.checkForRedirect(context, clearStack: true);

      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _progress = 0.0;
        _statusMessage = "";
      });
      print("Signup flow error: $e");
      if (mounted) _showError("Failed to complete signup: $e");
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

  Future<String> _getUniqueModelURL() async {
    try {
      final String modelURL = await _modelService.getUniqueModelURL('${widget.genderFilename}.glb');

      print("✅ Model URL received: $modelURL");

      // Optional: Track model access
   //   await _modelService.trackModelAccess(modelName);

      return modelURL;
    } catch (e) {
      print("❌ Error getting model URL: $e");
      throw Exception("Failed to generate avatar: $e");
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint("FCM token save failed: $e");
    }
  }

  Future<void> _saveUserData(String uid, AuthViewModel viewModel, String modelURL) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'modelURL': modelURL, // Save the unique model URL
      }, SetOptions(merge: true));


      await LocalStorageService.saveModelURL(modelURL); // NEW


      print("✅ User data saved successfully");
    } catch (e) {
      print("❌ Error saving user data: $e");
      throw e; // This is critical, so we throw
    }
  }






  Widget _buildTermsAndPrivacy() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white60,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "By tapping Next, you agree to our ",
            ),
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: primaryColor2,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Replace with your Terms of Service URL
                  _launchURL("https://mikk.live/terms-of-service/");
                },
            ),
            TextSpan(
              text: " and ",
            ),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: primaryColor2,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {

                  _launchURL("https://mikk.live/privacy-policy/");
                },
            ),
          ],
        ),
      ),
    );
  }
}







/*class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<AuthViewModel>(
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
                    _buildHeader(viewModel),
                    SizedBox(height: 32.h),

                    // Show different UI based on registration step
                    if (viewModel.isLogin)
                      loginFields(viewModel)
                    else if (viewModel.registrationStep == 0)
                      phoneNumberStep(viewModel)
                    else if (viewModel.registrationStep == 1)
                        otpVerificationStep(viewModel)
                      else if (viewModel.registrationStep == 2)
                          signUpFields(viewModel),

                    SizedBox(height: 24.h),
                    actionButton(viewModel),
                    SizedBox(height: 20.h),
                    txtBtn(),
                  ],
                ),
              ),
              if (viewModel.isLoader) Loader(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthViewModel viewModel) {
    String title = "Welcome Back";
    String subtitle = "Sign in to continue";

    if (!viewModel.isLogin) {
      if (viewModel.registrationStep == 0) {
        title = "Get Started";
        subtitle = "Enter your phone number";
      } else if (viewModel.registrationStep == 1) {
        title = "Verify OTP";
        subtitle = "Enter the code sent to ${viewModel.phoneController.text}";
      } else {
        title = "Create Account";
        subtitle = "Complete your profile";
      }
    }

    return Column(
      children: [
        TextWidget(
          txt: title,
          fontSize: 28,
          fontWeight: FontSizeAndWidth.bold,
          color: Colors.white,
        ),
        SizedBox(height: 6.h),
        TextWidget(
          txt: subtitle,
          fontSize: 14,
          fontWeight: FontSizeAndWidth.regular,
          color: Colors.white60,),
      ],
    );
  }

  // Step 0: Phone Number Input
  Widget phoneNumberStep(AuthViewModel viewModel) {
    return Column(
      children: [
        _buildTextField(
          hintText: "Enter your phone number",
          labelText: "Phone Number",
          controller: viewModel.phoneController,
          errorText: viewModel.errorList[0],
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // Step 1: OTP Verification
  Widget otpVerificationStep(AuthViewModel viewModel) {
    return Column(
      children: [
        _buildOTPField(viewModel),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextWidget(
              txt: "Didn't receive code?",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.regular,
              color: Colors.white60,
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: () {
                viewModel.resendOTP(context);
              },
              child: TextWidget(
                txt: "Resend",
                fontSize: 14,
                fontWeight: FontSizeAndWidth.semiBold,
                color: primaryColor2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPField(AuthViewModel viewModel) {
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
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
              (index) => _buildOTPDigit(viewModel, index),
        ),
      ),
    );
  }

  Widget _buildOTPDigit(AuthViewModel viewModel, int index) {
    return Container(
      width: 45.w,
      height: 55.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: viewModel.otpControllers[index].text.isNotEmpty
              ? primaryColor2
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: TextField(
        controller: viewModel.otpControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
          viewModel.updateOTP();
        },
      ),
    );
  }

  // Step 2: Complete Profile
  Widget signUpFields(AuthViewModel viewModel) {
    return Column(
      children: [
        _buildTextField(
          hintText: "Enter your full name",
          labelText: "Name",
          controller: viewModel.nameController,
          errorText: viewModel.errorList[1],
          icon: Icons.person_outline,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          hintText: "Choose a username",
          labelText: "Username",
          controller: viewModel.userNameController,
          errorText: viewModel.errorList[2],
          icon: Icons.account_circle_outlined,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          hintText: "Enter your email",
          labelText: "Email",
          controller: viewModel.emailController,
          errorText: viewModel.errorList[3],
          icon: Icons.email_outlined,
        ),
        SizedBox(height: 12.h),
        _buildDateField(
          hintText: "Select your birth date",
          labelText: "Birth Date",
          controller: viewModel.birthDateController,
          errorText: viewModel.errorList[4],
          icon: Icons.cake_outlined,
          viewModel: viewModel,
        ),
        SizedBox(height: 12.h),
        _buildGenderField(
          labelText: "Gender",
          errorText: viewModel.errorList[5],
          viewModel: viewModel,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          hintText: "Enter your password",
          labelText: "Password",
          controller: viewModel.passController,
          errorText: viewModel.errorList[6],
          icon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
    );
  }

  // Login Fields
  Widget loginFields(AuthViewModel viewModel) {
    return Column(
      children: [
        _buildTextField(
          hintText: "Username or Email",
          labelText: "Username / Email",
          controller: viewModel.usernameOrPhoneController,
          errorText: viewModel.errorList[7],
          icon: Icons.person_outline,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          hintText: "Enter your password",
          labelText: "Password",
          controller: viewModel.passController,
          errorText: viewModel.errorList[8],
          icon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
    );
  }

  // Dynamic Action Button
  Widget actionButton(AuthViewModel viewModel) {
    String buttonText = "Login";
    VoidCallback onPressed = () {};

    if (viewModel.isLogin) {
      buttonText = "Login";
      onPressed = () {
        if (viewModel.checkLoginField()) {
          viewModel.signInWithUsernameOrPhone(context).then((value) {
            if (viewModel.user != null) {
              viewModel.checkForRedirect(context);
            }
          });
        }
      };
    } else {
      if (viewModel.registrationStep == 0) {
        buttonText = "Send OTP";
        onPressed = () {
          if (viewModel.validatePhoneNumber()) {
            viewModel.sendOTP(context);
          }
        };
      } else if (viewModel.registrationStep == 1) {
        buttonText = "Verify OTP";
        onPressed = () {
          if (viewModel.validateOTP()) {
            viewModel.verifyOTP(context);
          }
        };
      } else {
        buttonText = "Sign Up";
        onPressed = () {
          if (viewModel.checkSignUpField()) {
            SignUpAPI(context, viewModel: viewModel);
          }
        };
      }
    }

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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Text(
              buttonText,
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

  Widget txtBtn() {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        // Show back button during registration steps
        if (!viewModel.isLogin && viewModel.registrationStep > 0) {
          return GestureDetector(
            onTap: () {
              viewModel.goToPreviousStep();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, color: primaryColor2, size: 18),
                SizedBox(width: 6.w),
                TextWidget(
                  txt: "Go Back",
                  fontSize: 14,
                  fontWeight: FontSizeAndWidth.semiBold,
                  color: primaryColor2,
                ),
              ],
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextWidget(
              txt: viewModel.isLogin
                  ? "Don't have an account?"
                  : "Already have an account?",
              fontSize: 14,
              fontWeight: FontSizeAndWidth.regular,
              color: Colors.white60,
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: () {
                viewModel.setIsLogin();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: TextWidget(
                  txt: viewModel.isLogin ? "Register Now" : "Login Now",
                  fontSize: 14,
                  fontWeight: FontSizeAndWidth.semiBold,
                  color: primaryColor2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String hintText,
    required String labelText,
    required TextEditingController controller,
    String? errorText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
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
        hintText: hintText,
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        labelText: labelText,
        controller: controller,
        errorText: errorText,
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22.r),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        obscureText: isPassword,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDateField({
    required String hintText,
    required String labelText,
    required TextEditingController controller,
    String? errorText,
    required IconData icon,
    required AuthViewModel viewModel,
  }) {
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
        hintText: hintText,
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
        labelText: labelText,
        controller: controller,
        errorText: errorText,
        textFieldInputColor: Colors.white,
        hintColor: Colors.white.withOpacity(0.4),
        labelColor: Colors.white70,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22.r),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        readOnly: true,
        onTap: () => _selectDate(context, viewModel),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, AuthViewModel viewModel) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor2,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      viewModel.setBirthDate(picked);
    }
  }

  Widget _buildGenderField({
    required String labelText,
    String? errorText,
    required AuthViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wc_outlined, color: Colors.white.withOpacity(0.7), size: 22.r),
                  SizedBox(width: 12.w),
                  TextWidget(
                    txt: labelText,
                    fontSize: 14,
                    fontWeight: FontSizeAndWidth.medium,
                    color: Colors.white70,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _buildGenderOption("Male", viewModel)),
                  SizedBox(width: 10.w),
                  Expanded(child: _buildGenderOption("Female", viewModel)),
                  SizedBox(width: 10.w),
                  Expanded(child: _buildGenderOption("Other", viewModel)),
                ],
              ),
            ],
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 6.h),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, AuthViewModel viewModel) {
    final isSelected = viewModel.selectedGender == gender;
    return GestureDetector(
      onTap: () => viewModel.setGender(gender),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [primaryColor2, primaryColor2],
          )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  SignUpAPI(BuildContext context, {required AuthViewModel viewModel}) {
    viewModel.signUpWithEmail(context).then(
          (value) {
        if (viewModel.user != null) {
          viewModel.checkForRedirect(context);
        }
      },
    );
  }
}*/



