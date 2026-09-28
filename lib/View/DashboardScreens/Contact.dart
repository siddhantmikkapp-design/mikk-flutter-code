/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikk/resources/TextWidget.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:mikk/values/ImageUrl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../resources/CustomRaisedButton.dart';
import '../../utils/CommonMethods.dart';
import '../../utils/LogHelper.dart';
import '../../utils/SessionManager.dart';
import '../../values/Color.dart';



class ContactDemo extends StatefulWidget {
  const ContactDemo({Key? key}) : super(key: key);

  @override
  State<ContactDemo> createState() => _ContactDemoState();
}

class _ContactDemoState extends State<ContactDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Contact> _contacts = [];
  List<Contact> _searchContactList = [];

  bool isSearch = false;
  bool _isLoading = false;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  final TextEditingController _searchContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Give the UI a moment to render before checking permissions
    Future.delayed(Duration(milliseconds: 300), () {
      _askPermissions("");
    });
  }

  Future<void> _askPermissions(String routeName) async {
    LogHelper("Starting permission request process");
    try {
      // First try with permission_handler
      PermissionStatus permissionStatus = await _getContactPermission();
      LogHelper("Permission handler status: $permissionStatus");

      if (permissionStatus == PermissionStatus.granted) {
        setState(() {
          _isLoading = true;
        });
        refreshContacts();
      } else {
        // If permission_handler didn't work, try directly with flutter_contacts
        bool flutterContactsPermission = await FlutterContacts.requestPermission();
        LogHelper("Flutter contacts permission result: $flutterContactsPermission");

        if (flutterContactsPermission) {
          setState(() {
            _isLoading = true;
          });
          refreshContacts();
        } else {
          _handleInvalidPermissions(permissionStatus);
        }
      }
    } catch (e) {
      LogHelper("Error during permission request: $e");
      setState(() {
        _isLoading = false;
      });
      CommonMethods.showError(context, 'Error requesting contacts permission');
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    LogHelper("Current permission status: $permission");

    if (permission != PermissionStatus.granted) {
      LogHelper("Requesting contact permission...");
      PermissionStatus permissionStatus = await Permission.contacts.request();
      LogHelper("New permission status: $permissionStatus");
      return permissionStatus;
    } else {
      return permission;
    }
  }

  Future<void> _handleInvalidPermissions(PermissionStatus permissionStatus) async {
    LogHelper("Handling invalid permission: $permissionStatus");

    if (permissionStatus == PermissionStatus.denied) {
      PermissionStatus newStatus = await Permission.contacts.request();
      LogHelper("Requested again, new status: $newStatus");

      if (newStatus == PermissionStatus.granted) {
        setState(() {
          _isLoading = true;
        });
        refreshContacts();
        return;
      }

      CommonMethods.showError(context, 'Access to contact data denied');
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      CommonMethods.showError(
          context, 'Contact permission required. Please enable it in app settings.');

      // Show a dialog with an option to open app settings
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Permission Required"),
            content: Text("This app needs contacts permission to function properly. Please enable it in app settings."),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Open Settings"),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _contacts.isNotEmpty ? myContactListView() : fetchContactsTheme(),
            if (_isLoading && _contacts.isNotEmpty)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor1),
                ),
              ),
          ],
        ));
  }

  Future<void> refreshContacts() async {
    try {
      LogHelper("Starting contact permission check");
      bool hasPermission = await FlutterContacts.requestPermission();
      LogHelper("Permission check result: $hasPermission");

      if (!hasPermission) {
        LogHelper("Contact permission denied");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LogHelper("Starting to fetch contacts");

      // Get all contacts (without thumbnails for performance)
      List<Contact> contacts = [];
      try {
        contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        LogHelper("Successfully fetched ${contacts.length} contacts");
      } catch (e) {
        LogHelper("Error fetching contacts: $e");
        setState(() {
          _isLoading = false;
        });
        CommonMethods.showError(context, 'Error loading contacts: ${e.toString()}');
        return;
      }

      LogHelper("Processing contacts");
      List<Contact> filteredContacts = [];
      for (var contact in contacts) {
        if (contact.displayName.isNotEmpty && contact.phones.isNotEmpty) {
          if (contact.phones.first.number.isNotEmpty) {
            filteredContacts.add(contact);
          }
        }
      }

      LogHelper("Filtered to ${filteredContacts.length} valid contacts");

      setState(() {
        _contacts = filteredContacts;
        _isLoading = false;
      });

      // We'll load photos in batches to avoid UI freezing
      _loadContactPhotos();
    } catch (e) {
      LogHelper("Global error in refreshContacts: $e");
      setState(() {
        _isLoading = false;
      });
      CommonMethods.showError(context, 'Unexpected error loading contacts');
    }
  }

  Future<void> _loadContactPhotos() async {
    // Only load photos for the first 20 contacts initially for better performance
    final int initialBatchSize = 20;
    final int batchSize = _contacts.length > 100 ? 10 : 5;

    try {
      // Load first batch
      LogHelper("Loading first batch of contact photos");
      for (int i = 0; i < _contacts.length && i < initialBatchSize; i++) {
        try {
          final fullContact = await FlutterContacts.getContact(_contacts[i].id, withPhoto: true);
          if (fullContact != null && fullContact.photo != null && mounted) {
            setState(() {
              _contacts[i] = fullContact;
            });
          }
        } catch (e) {
          LogHelper("Error loading contact photo ${i}: $e");
        }
      }

      // Load remaining photos in batches
      if (_contacts.length > initialBatchSize) {
        LogHelper("Loading remaining contact photos in batches");
        for (int startIndex = initialBatchSize; startIndex < _contacts.length; startIndex += batchSize) {
          if (!mounted) return;

          for (int i = startIndex; i < _contacts.length && i < startIndex + batchSize; i++) {
            try {
              final fullContact = await FlutterContacts.getContact(_contacts[i].id, withPhoto: true);
              if (fullContact != null && fullContact.photo != null && mounted) {
                setState(() {
                  _contacts[i] = fullContact;
                });
              }
            } catch (e) {
              LogHelper("Error loading contact photo ${i}: $e");
            }
          }

          // Short delay between batches to keep UI responsive
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      LogHelper("Finished loading all contact photos");
    } catch (e) {
      LogHelper("Error in photo loading process: $e");
    }
  }

  switchToSearchBar() {
    setState(() {
      isSearch = true;
    });
  }

  fetchContactsTheme() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(10.0),
                child:
                CommonMethods.assetImage(img: ImageUrl.ic_app_logo, width: screenWidth / 1.2, height: screenWidth / 1.2, color: primaryColor1)),
            _isLoading
                ? Column(
              children: [
                CircularProgressIndicator(color: primaryColor1),
                const SizedBox(height: 16),
                TextWidget(txt: "Loading contacts...", fontSize: FontSizeAndWidth.descriptionText, fontWeight: FontSizeAndWidth.medium)
              ],
            )
                : CustomRaisedButton(
              width: 200,
              colors: [primaryColor1, primaryColor2],
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _askPermissions('/contactsList');
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_outlined, color: whiteColor),
                  const SizedBox(width: 10.0),
                  TextWidget(txt: "Get My Contacts", fontSize: FontSizeAndWidth.descriptionText, fontWeight: FontSizeAndWidth.medium)
                ],
              ),
            ),
            const SizedBox(height: 50.0)
          ],
        ),
      ),
    );
  }

  myContactListView() {
    return ListView.builder(
      itemCount: _searchContactList.isNotEmpty ? _searchContactList.length : _contacts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        Contact contactUserData = _searchContactList.isNotEmpty ? _searchContactList.elementAt(index) : _contacts.elementAt(index);
        return contactListItem(index, contactUserData);
      },
    );
  }

  String _getInitials(Contact contact) {
    if (contact.displayName.isNotEmpty) {
      List<String> nameParts = contact.displayName.split(' ');
      if (nameParts.length > 1) {
        return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else if (nameParts.isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    return '';
  }

  contactListItem(int index, Contact contactUserData) {
    return Column(
      children: [
        ListTile(
            onTap: () {
              String contactNumber = "";
              if (contactUserData.phones.isNotEmpty) {
                if (contactUserData.phones.first.number.isNotEmpty) {
                  if (contactUserData.phones.first.number.trim().startsWith("+91")) {
                    contactNumber = contactUserData.phones.first.number.trim().replaceAll("+91", "");
                  } else {
                    contactNumber = contactUserData.phones.first.number.trim();
                  }
                }
              }
              SessionManager.setStringData(SessionManager.FORM_PHONE_NO, contactNumber);
              SessionManager.setStringData(SessionManager.FORM_PHONE_NAME, contactUserData.displayName);
              Navigator.pop(context, true);
            },
            leading: (contactUserData.photo != null)
                ? CircleAvatar(backgroundImage: MemoryImage(contactUserData.photo!))
                : CircleAvatar(
                backgroundColor: greyColor,
                child: TextWidget(
                  txt: _getInitials(contactUserData),
                  fontSize: FontSizeAndWidth.subTitle,
                  fontWeight: FontSizeAndWidth.medium,
                )),
            title: TextWidget(
              txt: contactUserData.displayName,
              fontSize: FontSizeAndWidth.subTitle,
              fontWeight: FontSizeAndWidth.medium,
            ),
            subtitle: TextWidget(
                txt: contactUserData.phones.isNotEmpty ? contactUserData.phones.first.number : "",
                fontSize: FontSizeAndWidth.smallText,
                fontWeight: FontSizeAndWidth.regular,
                color: textColor)),
        const Divider(height: 1, color: Colors.black12, indent: 70.0, endIndent: 20.0)
      ],
    );
  }

  getAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      flexibleSpace: SafeArea(
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [whiteColor, whiteColor]), boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 0),
            ),
          ]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      if (isSearch) {
                        isSearch = false;
                      } else {
                        Navigator.pop(context);
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: blackColor)),
              Expanded(
                child: isSearch
                    ? TextField(
                    maxLines: 1,
                    minLines: 1,
                    autofocus: true,
                    controller: _searchContactController,
                    onChanged: (text) {
                      _searchContactList = [];
                      if (text.isNotEmpty) {
                        for (var contact in _contacts) {
                          if (contact.displayName.toLowerCase().contains(text.toLowerCase())) {
                            _searchContactList.add(contact);
                          }
                        }
                      }
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        hintText: "Search",
                        contentPadding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                        ),
                        counterText: '',
                        hintStyle: CommonMethods.setTextStyle(
                          FontSizeAndWidth.descriptionText,
                          FontSizeAndWidth.regular,
                          color: lightTextColor,
                        )),
                    style: CommonMethods.setTextStyle(FontSizeAndWidth.descriptionText, FontSizeAndWidth.medium))
                    : TextWidget(
                  txt: "  Contacts",
                  fontSize: FontSizeAndWidth.subTitle,
                  fontWeight: FontSizeAndWidth.medium,
                ),
              ),
              const SizedBox(width: 50.0)
            ],
          ),
        ),
      ),
      centerTitle: false,
      titleSpacing: 10,
      toolbarHeight: 65,
      elevation: 0,
      leading: Container(),
      title: Container(),
      actions: [
        IconButton(
            onPressed: () {
              setState(() {
                if (_searchContactController.text.isNotEmpty) {
                  _searchContactController.clear();
                } else {
                  isSearch = true;
                }
              });
            },
            icon: Icon(
              _searchContactController.text.isNotEmpty ? Icons.close : Icons.search,
              color: blackColor,
            ))
      ],
    );
  }
}*/




/*
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikk/resources/TextWidget.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:mikk/values/ImageUrl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../resources/CustomRaisedButton.dart';
import '../../utils/CommonMethods.dart';
import '../../utils/LogHelper.dart';
import '../../utils/SessionManager.dart';
import '../../values/Color.dart';

class ContactDemo extends StatefulWidget {
  const ContactDemo({Key? key}) : super(key: key);

  @override
  State<ContactDemo> createState() => _ContactDemoState();
}

class _ContactDemoState extends State<ContactDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Contact> _contacts = [];
  List<Contact> _searchContactList = [];

  bool isSearch = false;
  bool _isLoading = false;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  final TextEditingController _searchContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _askPermissions("");
  }

  Future<void> _askPermissions(String routeName) async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      setState(() {
        _isLoading = true;
      });
      refreshContacts();
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  Future<void> _handleInvalidPermissions(PermissionStatus permissionStatus) async {
    if (permissionStatus == PermissionStatus.denied) {
      await Permission.contacts.request();
      CommonMethods.showError(context, 'Access to contact data denied');
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      CommonMethods.showError(context, 'Allow contact permission to fetch your contacts!');
      Future.delayed(Duration(seconds: 2), () {
        openAppSettings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: getAppBar(),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _contacts.isNotEmpty ? myContactListView() : fetchContactsTheme(),
            if (_isLoading && _contacts.isNotEmpty)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor1),
                ),
              ),
          ],
        ));
  }

  Future<void> refreshContacts() async {
    try {
      LogHelper("Starting contact permission check");
      bool hasPermission = await FlutterContacts.requestPermission();
      LogHelper("Permission check result: $hasPermission");

      if (!hasPermission) {
        LogHelper("Contact permission denied");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LogHelper("Starting to fetch contacts");
      // First try to get just a count to see if we can access contacts at all
      try {
        int contactCount = await FlutterContacts.getContacts().then((list) => list.length);
        LogHelper("Found $contactCount contacts in total");
      } catch (e) {
        LogHelper("Error counting contacts: $e");
      }

      // Get all contacts (without thumbnails for performance)
      List<Contact> contacts = [];
      try {
        contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        LogHelper("Successfully fetched ${contacts.length} contacts");
      } catch (e) {
        LogHelper("Error fetching contacts: $e");
        setState(() {
          _isLoading = false;
        });
        CommonMethods.showError(context, 'Error loading contacts: ${e.toString()}');
        return;
      }

      LogHelper("Processing contacts");
      List<Contact> filteredContacts = [];
      for (var contact in contacts) {
        if (contact.displayName.isNotEmpty && contact.phones.isNotEmpty) {
          if (contact.phones.first.number.isNotEmpty) {
            filteredContacts.add(contact);
          }
        }
      }

      LogHelper("Filtered to ${filteredContacts.length} valid contacts");

      setState(() {
        _contacts = filteredContacts;
        _isLoading = false;
      });

      // We'll load photos in batches to avoid UI freezing
      _loadContactPhotos();
    } catch (e) {
      LogHelper("Global error in refreshContacts: $e");
      setState(() {
        _isLoading = false;
      });
      CommonMethods.showError(context, 'Unexpected error loading contacts');
    }
  }

  Future<void> _loadContactPhotos() async {
    // Only load photos for the first 20 contacts initially for better performance
    final int initialBatchSize = 20;
    final int batchSize = _contacts.length > 100 ? 10 : 5;

    try {
      // Load first batch
      LogHelper("Loading first batch of contact photos");
      for (int i = 0; i < _contacts.length && i < initialBatchSize; i++) {
        try {
          final fullContact = await FlutterContacts.getContact(_contacts[i].id, withPhoto: true);
          if (fullContact != null && fullContact.photo != null && mounted) {
            setState(() {
              _contacts[i] = fullContact;
            });
          }
        } catch (e) {
          LogHelper("Error loading contact photo ${i}: $e");
        }
      }

      // Load remaining photos in batches
      if (_contacts.length > initialBatchSize) {
        LogHelper("Loading remaining contact photos in batches");
        for (int startIndex = initialBatchSize; startIndex < _contacts.length; startIndex += batchSize) {
          if (!mounted) return;

          for (int i = startIndex; i < _contacts.length && i < startIndex + batchSize; i++) {
            try {
              final fullContact = await FlutterContacts.getContact(_contacts[i].id, withPhoto: true);
              if (fullContact != null && fullContact.photo != null && mounted) {
                setState(() {
                  _contacts[i] = fullContact;
                });
              }
            } catch (e) {
              LogHelper("Error loading contact photo ${i}: $e");
            }
          }

          // Short delay between batches to keep UI responsive
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      LogHelper("Finished loading all contact photos");
    } catch (e) {
      LogHelper("Error in photo loading process: $e");
    }
  }

  _openContactForm() async {
    try {
      // This functionality is not directly available in flutter_contacts
      // You might need to use platform-specific code or a different approach
      LogHelper("Opening contact form not implemented with flutter_contacts");
    } catch (e) {
      LogHelper("Error opening contact form: $e");
    }
  }

  switchToSearchBar() {
    setState(() {
      isSearch = true;
    });
  }

  fetchContactsTheme() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(10.0),
                child:
                    CommonMethods.assetImage(img: ImageUrl.ic_app_logo, width: screenWidth / 1.2, height: screenWidth / 1.2, color: primaryColor1)),
            _isLoading
                ? Column(
                    children: [
                      CircularProgressIndicator(color: primaryColor1),
                      const SizedBox(height: 16),
                      TextWidget(txt: "Loading contacts...", fontSize: FontSizeAndWidth.descriptionText, fontWeight: FontSizeAndWidth.medium)
                    ],
                  )
                : CustomRaisedButton(
                    width: 200,
                    colors: [primaryColor1, primaryColor2],
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _askPermissions('/contactsList');
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_alt_outlined, color: whiteColor),
                        const SizedBox(width: 10.0),
                        TextWidget(txt: "Get My Contacts", fontSize: FontSizeAndWidth.descriptionText, fontWeight: FontSizeAndWidth.medium)
                      ],
                    ),
                  ),
            const SizedBox(height: 50.0)
          ],
        ),
      ),
    );
  }

  myContactListView() {
    return ListView.builder(
      itemCount: _searchContactList.isNotEmpty ? _searchContactList.length : _contacts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        Contact contactUserData = _searchContactList.isNotEmpty ? _searchContactList.elementAt(index) : _contacts.elementAt(index);
        return contactListItem(index, contactUserData);
      },
    );
  }

  String _getInitials(Contact contact) {
    if (contact.displayName.isNotEmpty) {
      List<String> nameParts = contact.displayName.split(' ');
      if (nameParts.length > 1) {
        return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else if (nameParts.isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    return '';
  }

  contactListItem(int index, Contact contactUserData) {
    return Column(
      children: [
        ListTile(
            onTap: () {
              String contactNumber = "";
              if (contactUserData.phones.isNotEmpty) {
                if (contactUserData.phones.first.number.isNotEmpty) {
                  if (contactUserData.phones.first.number.trim().startsWith("+91")) {
                    contactNumber = contactUserData.phones.first.number.trim().replaceAll("+91", "");
                  } else {
                    contactNumber = contactUserData.phones.first.number.trim();
                  }
                }
              }
              SessionManager.setStringData(SessionManager.FORM_PHONE_NO, contactNumber);
              SessionManager.setStringData(SessionManager.FORM_PHONE_NAME, contactUserData.displayName);
              Navigator.pop(context, true);
            },
            leading: (contactUserData.photo != null)
                ? CircleAvatar(backgroundImage: MemoryImage(contactUserData.photo!))
                : CircleAvatar(
                    backgroundColor: greyColor,
                    child: TextWidget(
                      txt: _getInitials(contactUserData),
                      fontSize: FontSizeAndWidth.subTitle,
                      fontWeight: FontSizeAndWidth.medium,
                    )),
            title: TextWidget(
              txt: contactUserData.displayName,
              fontSize: FontSizeAndWidth.subTitle,
              fontWeight: FontSizeAndWidth.medium,
            ),
            subtitle: TextWidget(
                txt: contactUserData.phones.isNotEmpty ? contactUserData.phones.first.number : "",
                fontSize: FontSizeAndWidth.smallText,
                fontWeight: FontSizeAndWidth.regular,
                color: textColor)),
        const Divider(height: 1, color: Colors.black12, indent: 70.0, endIndent: 20.0)
      ],
    );
  }

  _addManuallyBtn() {
    return Container(
      alignment: Alignment.bottomCenter,
      margin: const EdgeInsets.only(bottom: 32.0),
      child: CustomRaisedButton(
        width: 200,
        colors: [primaryColor1, primaryColor2],
        onPressed: () {
          // CommonMethods.goToNext(context, AddKhataScreen());
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_outlined, color: whiteColor),
            const SizedBox(width: 20.0),
            TextWidget(txt: "Add Manually", fontSize: FontSizeAndWidth.descriptionText, fontWeight: FontSizeAndWidth.medium, color: Colors.white),
          ],
        ),
      ),
    );
  }

  getAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      flexibleSpace: SafeArea(
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [whiteColor, whiteColor]), boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 0),
            ),
          ]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      if (isSearch) {
                        isSearch = false;
                      } else {
                        Navigator.pop(context);
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: blackColor)),
              Expanded(
                child: isSearch
                    ? TextField(
                        maxLines: 1,
                        minLines: 1,
                        autofocus: true,
                        controller: _searchContactController,
                        onChanged: (text) {
                          _searchContactList = [];
                          if (text.isNotEmpty) {
                            for (var contact in _contacts) {
                              if (contact.displayName.toLowerCase().contains(text.toLowerCase())) {
                                _searchContactList.add(contact);
                              }
                            }
                          }
                          setState(() {});
                        },
                        decoration: InputDecoration(
                            hintText: "Search",
                            contentPadding: const EdgeInsets.only(
                              left: 12.0,
                              right: 12.0,
                            ),
                            counterText: '',
                            hintStyle: CommonMethods.setTextStyle(
                              FontSizeAndWidth.descriptionText,
                              FontSizeAndWidth.regular,
                              color: lightTextColor,
                            )),
                        style: CommonMethods.setTextStyle(FontSizeAndWidth.descriptionText, FontSizeAndWidth.medium))
                    : TextWidget(
                        txt: "  Contacts",
                        fontSize: FontSizeAndWidth.subTitle,
                        fontWeight: FontSizeAndWidth.medium,
                      ),
              ),
              const SizedBox(width: 50.0)
            ],
          ),
        ),
      ),
      centerTitle: false,
      titleSpacing: 10,
      toolbarHeight: 65,
      elevation: 0,
      leading: Container(),
      title: Container(),
      actions: [
        IconButton(
            onPressed: () {
              setState(() {
                if (_searchContactController.text.isNotEmpty) {
                  _searchContactController.clear();
                } else {
                  isSearch = true;
                }
              });
            },
            icon: Icon(
              _searchContactController.text.isNotEmpty ? Icons.close : Icons.search,
              color: blackColor,
            ))
      ],
    );
  }
}
*/
