import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  String? get currentEmail => _auth.currentUser?.email;

  String? get currentPhoneNumber => _auth.currentUser?.phoneNumber;

  Future<void> sendPhoneOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    final completer = Completer<void>();
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final normalizedPhone = '${countryCode.trim()}$digits';

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            FirebaseAuthException(
              code: error.code,
              message: _friendlyAuthMessage(error),
            ),
          );
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyPhoneOtp(String otp) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Request a new OTP before verifying.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> refreshIdToken() async {
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => 'Enter a valid phone number with country code.',
      'too-many-requests' => 'Too many OTP requests. Please try again later.',
      'quota-exceeded' => 'OTP quota exceeded for now. Please try again later.',
      'captcha-check-failed' => 'Phone verification failed. Please try again.',
      _ => error.message ?? 'Phone verification failed. Please try again.',
    };
  }
}
