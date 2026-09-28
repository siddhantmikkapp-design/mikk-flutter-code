
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/values/StaticText.dart';
import '../Model/auth/SignUpModel.dart';
import '../Model/auth/UserNameModel.dart';
import '../Repository/auth_repository.dart';
import '../View/BottomBar.dart';
import '../View/CustomBottomNavigationBar.dart';
import '../utils/CommonMethods.dart';
import '../utils/SessionManager.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthViewModel extends ChangeNotifier {
  // Controllers
  final TextEditingController nameController = TextEditingController();

  // State variables
  bool isLoader = false;
  User? user;

  List<String> errorList = List.filled(7, '');
  String? selectedGender;
  DateTime? selectedBirthDate; // NEW — only used for the 18+ check, never saved


  // Set loader state
  void setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  // Clear all errors
  void clearErrors() {
    errorList = List.filled(7, '');
    notifyListeners();
  }

  // Validate name
  bool validateName() {
    clearErrors();
    if (nameController.text.trim().isEmpty) {
      errorList[0] = 'Name is required';
      notifyListeners();
      return false;
    }
    if (nameController.text.trim().length < 2) {
      errorList[0] = 'Name must be at least 2 characters';
      notifyListeners();
      return false;
    }
    return true;
  }


  bool validateGender() {
    clearErrors();
    if (selectedGender == null || selectedGender!.isEmpty) {
      errorList[5] = 'Please select gender';
      notifyListeners();
      return false;
    }
    return true;
  }

  bool validateAge() {
    if (selectedBirthDate == null) {
      errorList[6] = 'Please select your date of birth';
      notifyListeners();
      return false;
    }

    final today = DateTime.now();
    int age = today.year - selectedBirthDate!.year;
    final hasHadBirthdayThisYear = (today.month > selectedBirthDate!.month) ||
        (today.month == selectedBirthDate!.month && today.day >= selectedBirthDate!.day);
    if (!hasHadBirthdayThisYear) age--;

    if (age < 18) {
      errorList[6] = 'You must be 18 or older to use MiKK';
      notifyListeners();
      return false;
    }

    errorList[6] = '';
    notifyListeners();
    return true;
  }




  void setGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }


  void setBirthDate(DateTime date) {
    selectedBirthDate = date;
    errorList[6] = ''; // clear any prior error once a valid date is picked
    notifyListeners();
  }


  // Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      setLoader(true);

      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;

      // Save user name to Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'uid': user!.uid,
          'name': nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'isAnonymous': true,
          'id': user!.uid.substring(0,5),
          'gender' : selectedGender
        });
      }

      setLoader(false);
    //  CommonMethods.showToast("Login successful");
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Login failed: ${e.toString()}");
    }
  }

  // Check user sign in status
  Future<User?> checkUserSignIn() async {
    user = FirebaseAuth.instance.currentUser;
    return user;
  }

  // Check for redirect after login
  void checkForRedirect(BuildContext context, {bool clearStack = false}) {
    CommonMethods.showToast("Login successful");
      if (clearStack) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => getRedirectScreen()),
              (route) => false,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => getRedirectScreen()),
        );
      }





      /*CommonMethods.showToast("Login successful");
      CommonMethods.goToNext(context, CustomBottomNavigationBar());*/

  }


  Widget getRedirectScreen() {
    // Return your home/dashboard screen
    return CustomBottomNavigationBar(); // Replace with your actual screen
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}











 /* class AuthViewModel extends ChangeNotifier {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController usernameOrPhoneController = TextEditingController();

  // OTP Controllers
  List<TextEditingController> otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );

  // State variables
  bool isLogin = true;
  bool isSignUpSecondHalf = false;
  bool isLoader = false;
  bool authWithEmail = true;
  User? user;

  // Registration step tracking
  int registrationStep = 0; // 0: Phone, 1: OTP, 2: Profile

  DateTime? selectedBirthDate;
  String? selectedGender;

  String verificationId = "";
  String otpCode = "";

  List<String> errorList = List.filled(9, '');

  // Toggle between login and signup
  void setIsLogin() {
    isLogin = !isLogin;
    resetRegistration();
    clearErrors();
    notifyListeners();
  }

  // Set loader state
  void setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  // Clear all errors
  void clearErrors() {
    errorList = List.filled(9, '');
    notifyListeners();
  }

  // Navigate between steps
  void goToNextStep() {
    if (registrationStep < 2) {
      registrationStep++;
      clearErrors();
      notifyListeners();
    }
  }

  void goToPreviousStep() {
    if (registrationStep > 0) {
      registrationStep--;
      clearErrors();
      notifyListeners();
    }
  }

  // Reset registration
  void resetRegistration() {
    registrationStep = 0;
    clearOTP();
    phoneController.clear();
    nameController.clear();
    userNameController.clear();
    emailController.clear();
    passController.clear();
    birthDateController.clear();
    selectedBirthDate = null;
    selectedGender = null;
    notifyListeners();
  }

  // Clear OTP
  void clearOTP() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    otpCode = "";
  }

  // Update OTP
  void updateOTP() {
    otpCode = otpControllers.map((c) => c.text).join();
    notifyListeners();
  }

  // Set birth date
  void setBirthDate(DateTime date) {
    selectedBirthDate = date;
    birthDateController.text = "${date.day}/${date.month}/${date.year}";
    notifyListeners();
  }

  // Set gender
  void setGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }

  // Check if input is email
  bool isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  // Validate Phone Number
  bool validatePhoneNumber() {
    clearErrors();
    if (phoneController.text.trim().isEmpty) {
      errorList[0] = 'Phone number is required';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneController.text.trim())) {
      errorList[0] = 'Enter a valid 10-digit phone number';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Validate OTP
  bool validateOTP() {
    if (otpCode.length != 6) {
      CommonMethods.showToast("Please enter complete OTP");
      return false;
    }
    return true;
  }

  // Send OTP
  Future<void> sendOTP(BuildContext context) async {
    try {
      setLoader(true);

      String phoneNumber = "+91${phoneController.text.trim()}"; // Adjust country code as needed

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await FirebaseAuth.instance.signInWithCredential(credential);
          setLoader(false);
          goToNextStep(); // Skip OTP step and go to profile
        },
        verificationFailed: (FirebaseAuthException e) {
          setLoader(false);
          CommonMethods.showToast("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId = verificationId;
          setLoader(false);
          goToNextStep(); // Move to OTP step
          CommonMethods.showToast("OTP sent successfully");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Error: ${e.toString()}");
    }
  }

  // Resend OTP
  Future<void> resendOTP(BuildContext context) async {
    clearOTP();
    await sendOTP(context);
  }

  // Verify OTP
  Future<void> verifyOTP(BuildContext context) async {
    try {
      setLoader(true);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      // Verify the OTP
      await FirebaseAuth.instance.signInWithCredential(credential);

      setLoader(false);
      goToNextStep(); // Move to profile completion
      CommonMethods.showToast("Phone verified successfully");
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Invalid OTP");
    }
  }

  // Validate Sign Up Fields (Step 2)
  bool checkSignUpField() {
    clearErrors();
    bool isValid = true;

    if (nameController.text.trim().isEmpty) {
      errorList[1] = 'Name is required';
      isValid = false;
    }

    if (userNameController.text.trim().isEmpty) {
      errorList[2] = 'Username is required';
      isValid = false;
    } else if (userNameController.text.trim().length < 3) {
      errorList[2] = 'Username must be at least 3 characters';
      isValid = false;
    }

    if (emailController.text.trim().isEmpty) {
      errorList[3] = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      errorList[3] = 'Enter a valid email';
      isValid = false;
    }

    if (birthDateController.text.trim().isEmpty) {
      errorList[4] = 'Birth date is required';
      isValid = false;
    }

    if (selectedGender == null || selectedGender!.isEmpty) {
      errorList[5] = 'Please select gender';
      isValid = false;
    }

    if (passController.text.trim().isEmpty) {
      errorList[6] = 'Password is required';
      isValid = false;
    } else if (passController.text.trim().length < 6) {
      errorList[6] = 'Password must be at least 6 characters';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  // Validate Login Fields
  bool checkLoginField() {
    clearErrors();
    bool isValid = true;

    if (usernameOrPhoneController.text.trim().isEmpty) {
      errorList[7] = 'Username or Email is required';
      isValid = false;
    }

    if (passController.text.trim().isEmpty) {
      errorList[8] = 'Password is required';
      isValid = false;
    } else if (passController.text.trim().length < 6) {
      errorList[8] = 'Password must be at least 6 characters';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  // Old validation method for backward compatibility
  bool checkAuthField() {
    if (isLogin) {
      return checkLoginField();
    } else {
      return checkSignUpField();
    }
  }

  // Sign in with username or email
  Future<void> signInWithUsernameOrPhone(BuildContext context) async {
    String input = usernameOrPhoneController.text.trim();

    if (isEmail(input)) {
      // Direct email login
      await signInDirectWithEmail(context, input);
    } else {
      // Username login
      await signInWithUsername(context, input);
    }
  }

  // Sign in directly with email
  Future<void> signInDirectWithEmail(BuildContext context, String email) async {
    try {
      setLoader(true);

      String password = passController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Login failed: ${e.toString()}");
    }
  }

  // Sign in with username
  Future<void> signInWithUsername(BuildContext context, String username) async {
    try {
      setLoader(true);

      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setLoader(false);
        CommonMethods.showToast("Username not found");
        return;
      }

      String email = userQuery.docs.first.get('email');
      String password = passController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Login failed: ${e.toString()}");
    }
  }

  // Sign up with email (After phone verification)
  Future<void> signUpWithEmail(BuildContext context) async {
    try {
      setLoader(true);

      // Check if username already exists
      QuerySnapshot usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: userNameController.text.trim())
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        setLoader(false);
        CommonMethods.showToast("Username already taken");
        return;
      }

      // Get current user (already authenticated with phone)
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Link email and password to existing phone auth
        AuthCredential credential = EmailAuthProvider.credential(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );

        await currentUser.linkWithCredential(credential);

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'name': nameController.text.trim(),
          'username': userNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'birthDate': selectedBirthDate?.toIso8601String(),
          'gender': selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        });

        user = currentUser;
        setLoader(false);
        CommonMethods.showToast("Account created successfully");
        notifyListeners();
      } else {
        // Fallback: Create new account with email/password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );

        user = userCredential.user;

        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
            'uid': user!.uid,
            'name': nameController.text.trim(),
            'username': userNameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
            'birthDate': selectedBirthDate?.toIso8601String(),
            'gender': selectedGender,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        setLoader(false);
        CommonMethods.showToast("Account created successfully");
        notifyListeners();
      }
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Sign up failed: ${e.toString()}");
    }
  }

  // Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      setLoader(true);
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Anonymous sign in failed: ${e.toString()}");
    }
  }

  // Check user sign in status
  Future<User?> checkUserSignIn() async {
    user = FirebaseAuth.instance.currentUser;
    return user;
  }

  // Check for redirect after login/signup
  void checkForRedirect(BuildContext context) {
    if (user != null) {
      // Navigate to home screen or wherever needed
      CommonMethods.goToNext(context, CustomBottomNavigationBar());
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    usernameOrPhoneController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}*/



/*class AuthViewModel extends ChangeNotifier {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController usernameOrPhoneController = TextEditingController();

  // State variables
  bool isLogin = true;
  bool isSignUpSecondHalf = false;
  bool isLoader = false;
  bool authWithEmail = true;
  User? user;

  DateTime? selectedBirthDate;
  String? selectedGender;

  List<String> errorList = List.filled(8, '');

  // Toggle between login and signup
  void setIsLogin() {
    isLogin = !isLogin;
    clearErrors();
    notifyListeners();
  }

  // Set loader state
  void setLoader(bool value) {
    isLoader = value;
    notifyListeners();
  }

  // Clear all errors
  void clearErrors() {
    errorList = List.filled(8, '');
    notifyListeners();
  }

  // Set birth date
  void setBirthDate(DateTime date) {
    selectedBirthDate = date;
    birthDateController.text = "${date.day}/${date.month}/${date.year}";
    notifyListeners();
  }

  // Set gender
  void setGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }

  // Check if input is email
  bool isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  // Validation
  bool checkAuthField() {
    errorList = List.filled(8, '');
    bool isValid = true;

    if (!isLogin) {
      // Sign up validation
      if (nameController.text.trim().isEmpty) {
        errorList[0] = 'Name is required';
        isValid = false;
      }

      if (emailController.text.trim().isEmpty) {
        errorList[2] = 'Email is required';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(emailController.text.trim())) {
        errorList[2] = 'Enter a valid email';
        isValid = false;
      }

      if (userNameController.text.trim().isEmpty) {
        errorList[4] = 'Username is required';
        isValid = false;
      } else if (userNameController.text.trim().length < 3) {
        errorList[4] = 'Username must be at least 3 characters';
        isValid = false;
      }

      if (selectedGender == null || selectedGender!.isEmpty) {
        errorList[5] = 'Please select gender';
        isValid = false;
      }

      if (birthDateController.text.trim().isEmpty) {
        errorList[6] = 'Birth date is required';
        isValid = false;
      }
    } else {
      // Login validation
      if (usernameOrPhoneController.text.trim().isEmpty) {
        errorList[7] = 'Username or Email is required';
        isValid = false;
      }
    }

    // Password validation (common for both)
    if (passController.text.trim().isEmpty) {
      errorList[3] = 'Password is required';
      isValid = false;
    } else if (passController.text.trim().length < 6) {
      errorList[3] = 'Password must be at least 6 characters';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  // Sign in with username or email
  Future<void> signInWithUsernameOrPhone(BuildContext context) async {
    String input = usernameOrPhoneController.text.trim();

    if (isEmail(input)) {
      // Direct email login
      await signInDirectWithEmail(context, input);
    } else {
      // Username login
      await signInWithUsername(context, input);
    }
  }

  // Sign in directly with email
  Future<void> signInDirectWithEmail(BuildContext context, String email) async {
    try {
      setLoader(true);

      String password = passController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Login failed: ${e.toString()}");
    }
  }

  // Sign in with username
  Future<void> signInWithUsername(BuildContext context, String username) async {
    try {
      setLoader(true);

      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setLoader(false);
        CommonMethods.showToast("Username not found");
        return;
      }

      String email = userQuery.docs.first.get('email');
      String password = passController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Login failed: ${e.toString()}");
    }
  }

  // Sign up with email
  Future<void> signUpWithEmail(BuildContext context) async {
    try {
      setLoader(true);

      // Check if username already exists
      QuerySnapshot usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: userNameController.text.trim())
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        setLoader(false);
        CommonMethods.showToast("Username already taken");
        return;
      }

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      user = userCredential.user;

      // Save user data to Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'uid': user!.uid,
          'name': nameController.text.trim(),
          'username': userNameController.text.trim(),
          'email': emailController.text.trim(),
          'birthDate': selectedBirthDate?.toIso8601String(),
          'gender': selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setLoader(false);
      CommonMethods.showToast("Account created successfully");
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Sign up failed: ${e.toString()}");
    }
  }

  // Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      setLoader(true);
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      setLoader(false);
      notifyListeners();
    } catch (e) {
      setLoader(false);
      CommonMethods.showToast("Anonymous sign in failed: ${e.toString()}");
    }
  }

  // Check user sign in status
  Future<User?> checkUserSignIn() async {
    user = FirebaseAuth.instance.currentUser;
    return user;
  }

  // Check for redirect after login/signup
  void checkForRedirect(BuildContext context) {
    if (user != null) {
      // Navigate to home screen or wherever needed
      CommonMethods.goToNext(context, CustomBottomNavigationBar());
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passController.dispose();
    birthDateController.dispose();
    usernameOrPhoneController.dispose();
    super.dispose();
  }
}*/


/*

  Future<void> SaveSignUpData(context,{String phoneNumber = ""}) async {
    if (await isEmailNumberUnique(context,phoneNumber: phoneNumber)) {
      await signUpDataFirebase(context);
      LogHelper('Phone number added successfully.');
    } else {
      CommonMethods.showFlushBar(context,msg_: "Phone number already exists",icon_: Icons.error);
    }
  }

  Future<bool> isEmailNumberUnique(context,{String phoneNumber = "", String email = ""}) async {
    CollectionReference phoneNumbers = FirebaseFirestore.instance.collection('SignUp');
    if(phoneNumber.isNotEmpty) {
      QuerySnapshot query = await phoneNumbers.where('Number', isEqualTo: phoneNumber).get();
      return query.docs.isEmpty;
    }else if(email.isNotEmpty){
      QuerySnapshot query = await phoneNumbers.where(ConstantLabels.userEmail, isEqualTo: email).get();
        if(query.docs.isNotEmpty){
          isEmailVerified = false;
          CommonMethods.showFlushBar(context, msg_: "ID Already Exist", icon_: Icons.error);
        }else{
          isEmailUnique = true;
        }
      return query.docs.isEmpty;
    }else{
      return false;
    }
  }

  signUpDataFirebase(context) async {
    CollectionReference collRef = FirebaseFirestore.instance.collection("SignUp");
    try {
      SignUpModel model = SignUpModel(
          name: nameController.text,
          number: mobileController.text,
          city: cityController.text,
          password: passController.text, //.isNotEmpty ? CommonMethods.encryptPassword(passController.text) : "",
          email: emailController.text,
          isEmailVerified: isEmailVerified && isEmailUnique,
          isPhoneVerified: false,
      );
      var userProfile = await collRef.add(model.toJson());
      SessionManager.setStringData(SessionManager.USER_ID, userProfile.id);
      SessionManager.setStringData(SessionManager.FULL_NAME, nameController.text.toString());
      SessionManager.setStringData(SessionManager.MOBILE, mobileController.text.toString());
      SessionManager.setStringData(SessionManager.CITY, cityController.text.toString());
      SessionManager.setStringData(SessionManager.EMAIL, emailController.text.toString());
      SessionManager.setBooleanData(SessionManager.IS_EMAIL_VERIFIED , (isEmailVerified && isEmailUnique));
      SessionManager.setBooleanData(SessionManager.IS_PHONE_VERIFIED , false);
      // SessionManager.setBooleanData(SessionManager.IS_ADMIN, false);
      // SessionManager.setBooleanData(SessionManager.IS_MANAGER, false);
      LogHelper(nameController.text);
      LogHelper(nameController.text.toString());
      LogHelper("Data Added Successfully");
      LogHelper("userProfile.id ${userProfile.id}");
      // CommonMethods.goToNext(context, const Dashboard());
      CommonMethods.goToNext(context,  CustomBottomNavigationBar());
    } catch (e) {
      LogHelper('Error adding document: $e');
      CommonMethods.showFlushBar(context, msg_: "Server Issue", icon_: Icons.error, status_: "error");
    }
    // collRef.add({'Name': nameController.text, 'Email': emailController.text, 'Password': passController.text});
  }

  signInWithGoogleEvent(context) async {
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    if (gUser != null) {
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      LogHelper("gAuth!.accessToken ${gAuth.accessToken}");
      LogHelper("gAuth!.idToken ${gAuth.idToken}");

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      LogHelper(" name -> ${userCredential.user!.displayName}");
      emailController.text = userCredential.user!.email.toString();
      passController.text = userCredential.user!.email.toString();

      // return CommonMethods.goToNext(context, const Dashboard());
      return CommonMethods.goToNext(context,  CustomBottomNavigationBar());
    } else {
      return LogHelper("Google Id Not Selected");
    }
  }
*/

