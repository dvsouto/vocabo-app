import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class SubscriptionsDataSource {
  final Dio _dio;

  SubscriptionsDataSource(this._dio);

  Future<PlanStatus> getStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/subscriptions/status',
    );
    return PlanStatus.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<PlanStatus> confirmAppStore(String signedTransaction) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions/app-store',
      data: {'signed_transaction': signedTransaction},
    );
    return PlanStatus.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<PlanStatus> confirmGooglePlay(String purchaseToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions/google-play',
      data: {'purchase_token': purchaseToken},
    );
    return PlanStatus.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
