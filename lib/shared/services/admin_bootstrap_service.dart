import 'package:cloud_functions/cloud_functions.dart';

import 'backend_api_service.dart';

class AdminBootstrapService {
  AdminBootstrapService({
    FirebaseFunctions? functions,
    BackendApiService? backend,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _backend = backend ?? BackendApiService();

  final FirebaseFunctions _functions;
  final BackendApiService _backend;

  Future<Map<String, dynamic>> bootstrapAdminAccount() async {
    if (_backend.isEnabled) {
      final data = await _backend.postJson('/api/bootstrap-admin-account');
      final profile = data['profile'] as Map<String, dynamic>?;
      if (profile == null) {
        throw Exception('Admin bootstrap did not return a profile.');
      }
      return profile;
    }

    final result = await _functions
        .httpsCallable('bootstrapAdminAccount')
        .call<Map<Object?, Object?>>();
    final data = result.data.cast<Object?, Object?>();
    final profile = (data['profile'] as Map<Object?, Object?>?)
        ?.cast<String, dynamic>();
    if (profile == null) {
      throw Exception('Admin bootstrap did not return a profile.');
    }
    return profile;
  }
}
