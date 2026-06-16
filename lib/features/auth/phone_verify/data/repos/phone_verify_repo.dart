import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';

class PhoneVerifyRepo {
  final Dio _dio;
  PhoneVerifyRepo(this._dio);

  String _normalizePhoneNumber(String phoneNumber) =>
      phoneNumber.replaceAll(RegExp(r'\D'), '');

  Future<ApiResult<void>> sendOtp(String phoneNumber) async {
    try {
      final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
      debugPrint('PhoneVerifyRepo.sendOtp phone_number=$normalizedPhoneNumber');
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.sendPhoneOtp}',
        data: {'phone_number': normalizedPhoneNumber},
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<void>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
      debugPrint(
        'PhoneVerifyRepo.verifyOtp phone_number=$normalizedPhoneNumber',
      );
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.verifyPhoneOtp}',
        data: {'phone_number': normalizedPhoneNumber, 'otp': otp},
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
