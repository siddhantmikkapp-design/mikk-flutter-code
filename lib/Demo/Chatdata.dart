// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mikk/Demo/MessageClass.dart';
//
// import 'avatar_creator_page.dart';
// import 'avatar_viewer.dart';
//
// class Chatdata extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return MaterialApp(
//       title: 'Flutter Firebase Demo',
//       home: ChatdataPage(),
//     );
//   }
// }
//
// class ChatdataPage extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _ChatState();
// }
//
// class _ChatState extends State<ChatdataPage> {
//   final ScrollController _scrollController = ScrollController();
//   final int _pageSize = 10;
//   int? _lastTimestamp;
//   bool _hasMore = true;
//   bool _isLoadingMore = false;
//   final String uid = FirebaseAuth.instance.currentUser!.uid;
//   final String receiverUserId = "cbl";
//   final String senderRoom = "cbl${FirebaseAuth.instance.currentUser?.uid}";
//   final TextEditingController _controller = TextEditingController();
//   final DatabaseReference baseRef = FirebaseDatabase.instanceFor(
//     app: Firebase.app(),
//     databaseURL: 'https://random-eeeee-default-rtdb.asia-southeast1.firebasedatabase.app/',
//   ).ref();
//   List<MessageClass> messageList = [];
//   bool loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_scrollListener);
//     getOwnData();
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollListener() {
//     if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isLoadingMore) {
//       loadMore();
//     }
//   }
//
//   void loadMore() async {
//     if (!_hasMore || _isLoadingMore || _lastTimestamp == null) return;
//
//     setState(() => _isLoadingMore = true);
//
//     DatabaseReference ref = baseRef.child('SenderMessage').child(senderRoom);
//     Query query = ref.orderByChild('TimeStamp').startAt(_lastTimestamp! + 1).limitToFirst(_pageSize);
//
//     try {
//       DatabaseEvent event = await query.once();
//       List<MessageClass> newItems = [];
//
//       if (event.snapshot.value != null) {
//         Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         data.forEach((key, value) {
//           newItems.add(MessageClass.fromJson(Map<String, dynamic>.from(value)));
//         });
//       }
//
//       if (newItems.isNotEmpty) {
//         messageList.addAll(newItems);
//         _lastTimestamp = newItems.last.timeStamp;
//         _hasMore = newItems.length >= _pageSize;
//       } else {
//         _hasMore = false;
//       }
//     } catch (error) {
//       print("Error loading more: $error");
//     }
//
//     setState(() => _isLoadingMore = false);
//   }
//
//   void getOwnData() {
//     DatabaseReference ref = baseRef.child('SenderMessage').child(senderRoom);
//     Query query = ref.orderByChild('TimeStamp').limitToFirst(_pageSize);
//
//     query.onValue.listen((event) {
//       messageList.clear();
//       for (DataSnapshot child in event.snapshot.children) {
//         final value = child.value;
//         if (value != null) {
//           final michItem = MessageClass.fromJson(Map<String, dynamic>.from(value as Map));
//           messageList.add(michItem);
//         }
//       }
//
//       // Update pagination markers
//       if (messageList.isNotEmpty) {
//         _lastTimestamp = messageList.last.timeStamp;
//         _hasMore = messageList.length >= _pageSize;
//       } else {
//         _hasMore = false;
//       }
//
//       setState(() => loading = false);
//     }, onError: (error) {
//       setState(() => loading = false);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Expanded(
//         child: loading
//             ? const Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 controller: _scrollController,
//                 itemCount: messageList.length + (_isLoadingMore ? 1 : 0),
//                 itemBuilder: (context, index) {
//                   final item = messageList[index];
//                   return ListTile(
//                     title: Text(item.message ?? 'No Name'),
//                     subtitle: Text('Timestamp: ${item.timeStamp ?? 0}'),
//                     trailing: Text(item.message ?? 'N/A'),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

// final viewModel = Provider.of<DatabaseService>(context, listen: false);
//     viewModel.getOwnData();
//     _scrollController = ScrollController();
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
//           viewModel.hasMore &&
//           !viewModel.isLoadingMore) {
//         viewModel.loadMore();
//       }
//     });

 //  @override
 //  void dispose() {
 //    _scrollController.dispose();
 // //   DatabaseService().disposeController();
 //    super.dispose();
 //  }
 //
