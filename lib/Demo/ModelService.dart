
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModelService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get unique permanent URL for a model
  Future<String> getUniqueModelURL(String modelName) async {
    try {
      final callable = _functions.httpsCallable('getUniqueModelURL');
      final result = await callable.call({
        'modelName': modelName,
      });

      final downloadURL = result.data['downloadURL'] as String;
      final isNew = result.data['isNew'] as bool;

      print(isNew ? '✨ New URL created' : '✅ Using existing URL');

      return downloadURL;
    } on FirebaseFunctionsException catch (e) {
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      rethrow;
    }
  }

  /// Track model access (optional)
  Future<void> trackModelAccess(String modelName) async {
    try {
      await _functions.httpsCallable('incrementModelAccess').call({
        'modelName': modelName,
      });
    } catch (e) {
      print('Failed to track access: $e');
    }
  }

  /// Revoke access to a model (optional)
  Future<bool> revokeModelAccess(String modelName) async {
    try {
      final result = await _functions.httpsCallable('revokeModelAccess').call({
        'modelName': modelName,
      });
      return result.data['success'] as bool;
    } catch (e) {
      print('Failed to revoke access: $e');
      return false;
    }
  }
}