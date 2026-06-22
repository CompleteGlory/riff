// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Riff`
  String get appTitle {
    return Intl.message(
      'Riff',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Define Yourself\nin Your Unique Way.`
  String get defineYourself {
    return Intl.message(
      'Define Yourself\nin Your Unique Way.',
      name: 'defineYourself',
      desc: '',
      args: [],
    );
  }

  /// `Share your sound. Find your people.`
  String get shareYourSound {
    return Intl.message(
      'Share your sound. Find your people.',
      name: 'shareYourSound',
      desc: '',
      args: [],
    );
  }

  /// `Get Started`
  String get getStarted {
    return Intl.message(
      'Get Started',
      name: 'getStarted',
      desc: '',
      args: [],
    );
  }

  /// `Login To your account`
  String get loginTitle {
    return Intl.message(
      'Login To your account',
      name: 'loginTitle',
      desc: '',
      args: [],
    );
  }

  /// `It's great to see you again!`
  String get itsGreatToSeeYouAgain {
    return Intl.message(
      'It\'s great to see you again!',
      name: 'itsGreatToSeeYouAgain',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get emailLabel {
    return Intl.message(
      'Email',
      name: 'emailLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email address`
  String get enterYourEmailAddress {
    return Intl.message(
      'Enter your email address',
      name: 'enterYourEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get passwordLabel {
    return Intl.message(
      'Password',
      name: 'passwordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password`
  String get enterYourPassword {
    return Intl.message(
      'Enter your password',
      name: 'enterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid email address`
  String get pleaseEnterValidEmail {
    return Intl.message(
      'Please enter a valid email address',
      name: 'pleaseEnterValidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password is required`
  String get passwordIsRequired {
    return Intl.message(
      'Password is required',
      name: 'passwordIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 8 characters`
  String get passwordMinLength {
    return Intl.message(
      'Password must be at least 8 characters',
      name: 'passwordMinLength',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get loginBtn {
    return Intl.message(
      'Login',
      name: 'loginBtn',
      desc: '',
      args: [],
    );
  }

  /// `Forgot your Password?`
  String get forgotYourPassword {
    return Intl.message(
      'Forgot your Password?',
      name: 'forgotYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Reset your password`
  String get resetYourPassword {
    return Intl.message(
      'Reset your password',
      name: 'resetYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Or`
  String get orDivider {
    return Intl.message(
      'Or',
      name: 'orDivider',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Google`
  String get continueWithGoogle {
    return Intl.message(
      'Continue with Google',
      name: 'continueWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Signing in…`
  String get signingIn {
    return Intl.message(
      'Signing in…',
      name: 'signingIn',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get dontHaveAnAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Join`
  String get joinBtn {
    return Intl.message(
      'Join',
      name: 'joinBtn',
      desc: '',
      args: [],
    );
  }

  /// `Create an account`
  String get createAnAccount {
    return Intl.message(
      'Create an account',
      name: 'createAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `let's create your account.`
  String get letsCreateYourAccount {
    return Intl.message(
      'let\'s create your account.',
      name: 'letsCreateYourAccount',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message(
      'Full Name',
      name: 'fullName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your full name`
  String get enterYourFullName {
    return Intl.message(
      'Enter your full name',
      name: 'enterYourFullName',
      desc: '',
      args: [],
    );
  }

  /// `UserName`
  String get userName {
    return Intl.message(
      'UserName',
      name: 'userName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your user name`
  String get enterYourUserName {
    return Intl.message(
      'Enter your user name',
      name: 'enterYourUserName',
      desc: '',
      args: [],
    );
  }

  /// `This field is required`
  String get thisFieldIsRequired {
    return Intl.message(
      'This field is required',
      name: 'thisFieldIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Create An Account`
  String get createAnAccountBtn {
    return Intl.message(
      'Create An Account',
      name: 'createAnAccountBtn',
      desc: '',
      args: [],
    );
  }

  /// `By signing up you are accepting our`
  String get bySigningUpAccepting {
    return Intl.message(
      'By signing up you are accepting our',
      name: 'bySigningUpAccepting',
      desc: '',
      args: [],
    );
  }

  /// `Terms and conditions.`
  String get termsAndConditions {
    return Intl.message(
      'Terms and conditions.',
      name: 'termsAndConditions',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get alreadyHaveAnAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `login`
  String get loginLink {
    return Intl.message(
      'login',
      name: 'loginLink',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password`
  String get forgotPasswordTitle {
    return Intl.message(
      'Forgot Password',
      name: 'forgotPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email for the verification process. We will send 4 digits code to your email.`
  String get forgotPasswordSubtitle {
    return Intl.message(
      'Enter your email for the verification process. We will send 4 digits code to your email.',
      name: 'forgotPasswordSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Send Code`
  String get sendCodeBtn {
    return Intl.message(
      'Send Code',
      name: 'sendCodeBtn',
      desc: '',
      args: [],
    );
  }

  /// `Enter 6 digit code that you've received on your email address.`
  String get enterCodeSubtitle {
    return Intl.message(
      'Enter 6 digit code that you\'ve received on your email address.',
      name: 'enterCodeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continueBtn {
    return Intl.message(
      'Continue',
      name: 'continueBtn',
      desc: '',
      args: [],
    );
  }

  /// `Resend code`
  String get resendCode {
    return Intl.message(
      'Resend code',
      name: 'resendCode',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get resetPasswordTitle {
    return Intl.message(
      'Reset Password',
      name: 'resetPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Set the new password for your account so you can login and access all the features.`
  String get resetPasswordSubtitle {
    return Intl.message(
      'Set the new password for your account so you can login and access all the features.',
      name: 'resetPasswordSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get resetPasswordBtn {
    return Intl.message(
      'Reset Password',
      name: 'resetPasswordBtn',
      desc: '',
      args: [],
    );
  }

  /// `Enter your new password`
  String get enterNewPassword {
    return Intl.message(
      'Enter your new password',
      name: 'enterNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Confirm your new password`
  String get confirmNewPassword {
    return Intl.message(
      'Confirm your new password',
      name: 'confirmNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a password`
  String get pleaseEnterPassword {
    return Intl.message(
      'Please enter a password',
      name: 'pleaseEnterPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please confirm your password`
  String get pleaseConfirmPassword {
    return Intl.message(
      'Please confirm your password',
      name: 'pleaseConfirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match`
  String get passwordsDoNotMatch {
    return Intl.message(
      'Passwords do not match',
      name: 'passwordsDoNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `Success!`
  String get successTitle {
    return Intl.message(
      'Success!',
      name: 'successTitle',
      desc: '',
      args: [],
    );
  }

  /// `Password updated successfully.\nPlease login to continue.`
  String get passwordUpdatedSuccessfully {
    return Intl.message(
      'Password updated successfully.\nPlease login to continue.',
      name: 'passwordUpdatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Proceed to Login`
  String get proceedToLogin {
    return Intl.message(
      'Proceed to Login',
      name: 'proceedToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Try Again`
  String get tryAgainBtn {
    return Intl.message(
      'Try Again',
      name: 'tryAgainBtn',
      desc: '',
      args: [],
    );
  }

  /// `Step 1 of 2`
  String get step1Of2 {
    return Intl.message(
      'Step 1 of 2',
      name: 'step1Of2',
      desc: '',
      args: [],
    );
  }

  /// `Select the instruments you play.\nPick as many as you like.`
  String get selectInstruments {
    return Intl.message(
      'Select the instruments you play.\nPick as many as you like.',
      name: 'selectInstruments',
      desc: '',
      args: [],
    );
  }

  /// `Step 2 of 2`
  String get step2Of2 {
    return Intl.message(
      'Step 2 of 2',
      name: 'step2Of2',
      desc: '',
      args: [],
    );
  }

  /// `Select the genres you love.\nThis helps us find your people.`
  String get selectGenres {
    return Intl.message(
      'Select the genres you love.\nThis helps us find your people.',
      name: 'selectGenres',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get skipBtn {
    return Intl.message(
      'Skip',
      name: 'skipBtn',
      desc: '',
      args: [],
    );
  }

  /// `Verify your\nphone number`
  String get verifyYourPhoneNumber {
    return Intl.message(
      'Verify your\nphone number',
      name: 'verifyYourPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `We'll send a WhatsApp message with a 6-digit code.`
  String get wellSendWhatsApp {
    return Intl.message(
      'We\'ll send a WhatsApp message with a 6-digit code.',
      name: 'wellSendWhatsApp',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNumberLabel {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumberLabel',
      desc: '',
      args: [],
    );
  }

  /// `Send OTP via WhatsApp`
  String get sendOTPViaWhatsApp {
    return Intl.message(
      'Send OTP via WhatsApp',
      name: 'sendOTPViaWhatsApp',
      desc: '',
      args: [],
    );
  }

  /// `Sending…`
  String get sendingOTP {
    return Intl.message(
      'Sending…',
      name: 'sendingOTP',
      desc: '',
      args: [],
    );
  }

  /// `Code will be sent via WhatsApp`
  String get codeWillBeSentViaWhatsApp {
    return Intl.message(
      'Code will be sent via WhatsApp',
      name: 'codeWillBeSentViaWhatsApp',
      desc: '',
      args: [],
    );
  }

  /// `We sent a WhatsApp message to\n{phoneNumber}`
  String weSentWhatsAppTo(String phoneNumber) {
    return Intl.message(
      'We sent a WhatsApp message to\n$phoneNumber',
      name: 'weSentWhatsAppTo',
      desc: '',
      args: [phoneNumber],
    );
  }

  /// `Verify`
  String get verifyBtn {
    return Intl.message(
      'Verify',
      name: 'verifyBtn',
      desc: '',
      args: [],
    );
  }

  /// `Resend code in {seconds}s`
  String resendCodeIn(int seconds) {
    return Intl.message(
      'Resend code in ${seconds}s',
      name: 'resendCodeIn',
      desc: '',
      args: [seconds],
    );
  }

  /// `Resend via WhatsApp`
  String get resendViaWhatsApp {
    return Intl.message(
      'Resend via WhatsApp',
      name: 'resendViaWhatsApp',
      desc: '',
      args: [],
    );
  }

  /// `Skip for now`
  String get skipForNow {
    return Intl.message(
      'Skip for now',
      name: 'skipForNow',
      desc: '',
      args: [],
    );
  }

  /// `Help your friends recognise you.\nYou can always change this later.`
  String get helpFriendsRecogniseYou {
    return Intl.message(
      'Help your friends recognise you.\nYou can always change this later.',
      name: 'helpFriendsRecogniseYou',
      desc: '',
      args: [],
    );
  }

  /// `Change photo`
  String get changePhoto {
    return Intl.message(
      'Change photo',
      name: 'changePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get chooseFromGallery {
    return Intl.message(
      'Choose from gallery',
      name: 'chooseFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Saving…`
  String get savingBtn {
    return Intl.message(
      'Saving…',
      name: 'savingBtn',
      desc: '',
      args: [],
    );
  }

  /// `Save & Continue`
  String get saveAndContinue {
    return Intl.message(
      'Save & Continue',
      name: 'saveAndContinue',
      desc: '',
      args: [],
    );
  }

  /// `See which of your contacts are already on Riff.`
  String get seeWhichContactsOnRiff {
    return Intl.message(
      'See which of your contacts are already on Riff.',
      name: 'seeWhichContactsOnRiff',
      desc: '',
      args: [],
    );
  }

  /// `Sync Contacts`
  String get syncContactsBtn {
    return Intl.message(
      'Sync Contacts',
      name: 'syncContactsBtn',
      desc: '',
      args: [],
    );
  }

  /// `We'll match your contacts with Riff users.`
  String get wellMatchContacts {
    return Intl.message(
      'We\'ll match your contacts with Riff users.',
      name: 'wellMatchContacts',
      desc: '',
      args: [],
    );
  }

  /// `Contacts synced — none of your contacts are on Riff yet.`
  String get contactsSyncedNoneOnRiff {
    return Intl.message(
      'Contacts synced — none of your contacts are on Riff yet.',
      name: 'contactsSyncedNoneOnRiff',
      desc: '',
      args: [],
    );
  }

  /// `Follow artists and musicians to fill your feed.`
  String get followArtistsToFillFeed {
    return Intl.message(
      'Follow artists and musicians to fill your feed.',
      name: 'followArtistsToFillFeed',
      desc: '',
      args: [],
    );
  }

  /// `No suggestions yet`
  String get noSuggestionsYet {
    return Intl.message(
      'No suggestions yet',
      name: 'noSuggestionsYet',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get followingStatus {
    return Intl.message(
      'Following',
      name: 'followingStatus',
      desc: '',
      args: [],
    );
  }

  /// `Follow`
  String get followBtn {
    return Intl.message(
      'Follow',
      name: 'followBtn',
      desc: '',
      args: [],
    );
  }

  /// `Your music social feed`
  String get yourMusicSocialFeed {
    return Intl.message(
      'Your music social feed',
      name: 'yourMusicSocialFeed',
      desc: '',
      args: [],
    );
  }

  /// `App Settings`
  String get settingsDrawer {
    return Intl.message(
      'App Settings',
      name: 'settingsDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Appearance & language`
  String get privacyAppearance {
    return Intl.message(
      'Appearance & language',
      name: 'privacyAppearance',
      desc: '',
      args: [],
    );
  }

  /// `Account Settings`
  String get accountSettingsDrawer {
    return Intl.message(
      'Account Settings',
      name: 'accountSettingsDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Privacy, password & security`
  String get accountSettingsSub {
    return Intl.message(
      'Privacy, password & security',
      name: 'accountSettingsSub',
      desc: '',
      args: [],
    );
  }

  /// `Account Settings`
  String get accountSettingsTitle {
    return Intl.message(
      'Account Settings',
      name: 'accountSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get changePasswordTitle {
    return Intl.message(
      'Change Password',
      name: 'changePasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get changePasswordTile {
    return Intl.message(
      'Change Password',
      name: 'changePasswordTile',
      desc: '',
      args: [],
    );
  }

  /// `Update your account password`
  String get changePasswordSub {
    return Intl.message(
      'Update your account password',
      name: 'changePasswordSub',
      desc: '',
      args: [],
    );
  }

  /// `Current Password`
  String get currentPasswordLabel {
    return Intl.message(
      'Current Password',
      name: 'currentPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your current password`
  String get currentPasswordHint {
    return Intl.message(
      'Enter your current password',
      name: 'currentPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get newPasswordLabel {
    return Intl.message(
      'New Password',
      name: 'newPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your new password`
  String get newPasswordHint {
    return Intl.message(
      'Enter your new password',
      name: 'newPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm New Password`
  String get confirmNewPasswordLabel {
    return Intl.message(
      'Confirm New Password',
      name: 'confirmNewPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Re-enter your new password`
  String get confirmNewPasswordHint {
    return Intl.message(
      'Re-enter your new password',
      name: 'confirmNewPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get changePasswordBtn {
    return Intl.message(
      'Change Password',
      name: 'changePasswordBtn',
      desc: '',
      args: [],
    );
  }

  /// `Password changed successfully!`
  String get passwordChangedSuccess {
    return Intl.message(
      'Password changed successfully!',
      name: 'passwordChangedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to change password. Please try again.`
  String get passwordChangedFailure {
    return Intl.message(
      'Failed to change password. Please try again.',
      name: 'passwordChangedFailure',
      desc: '',
      args: [],
    );
  }

  /// `Current password is incorrect`
  String get wrongCurrentPassword {
    return Intl.message(
      'Current password is incorrect',
      name: 'wrongCurrentPassword',
      desc: '',
      args: [],
    );
  }

  /// `App Settings`
  String get appSettingsTitle {
    return Intl.message(
      'App Settings',
      name: 'appSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Report a Bug`
  String get reportABugDrawer {
    return Intl.message(
      'Report a Bug',
      name: 'reportABugDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Help us fix issues`
  String get helpUsFixIssues {
    return Intl.message(
      'Help us fix issues',
      name: 'helpUsFixIssues',
      desc: '',
      args: [],
    );
  }

  /// `Request a Feature`
  String get requestAFeatureDrawer {
    return Intl.message(
      'Request a Feature',
      name: 'requestAFeatureDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Share your ideas`
  String get shareYourIdeas {
    return Intl.message(
      'Share your ideas',
      name: 'shareYourIdeas',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get logOut {
    return Intl.message(
      'Log out',
      name: 'logOut',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settingsTitle {
    return Intl.message(
      'Settings',
      name: 'settingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get appearanceSection {
    return Intl.message(
      'Appearance',
      name: 'appearanceSection',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `On`
  String get darkModeOn {
    return Intl.message(
      'On',
      name: 'darkModeOn',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get darkModeOff {
    return Intl.message(
      'Off',
      name: 'darkModeOff',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacySection {
    return Intl.message(
      'Privacy',
      name: 'privacySection',
      desc: '',
      args: [],
    );
  }

  /// `Private Account`
  String get privateAccount {
    return Intl.message(
      'Private Account',
      name: 'privateAccount',
      desc: '',
      args: [],
    );
  }

  /// `Only approved followers can see your posts`
  String get onlyApprovedFollowers {
    return Intl.message(
      'Only approved followers can see your posts',
      name: 'onlyApprovedFollowers',
      desc: '',
      args: [],
    );
  }

  /// `Anyone can follow you and see your posts`
  String get anyoneCanFollow {
    return Intl.message(
      'Anyone can follow you and see your posts',
      name: 'anyoneCanFollow',
      desc: '',
      args: [],
    );
  }

  /// `When your account is private, only people you approve can follow you and see your posts and reels.`
  String get privateAccountDisclaimer {
    return Intl.message(
      'When your account is private, only people you approve can follow you and see your posts and reels.',
      name: 'privateAccountDisclaimer',
      desc: '',
      args: [],
    );
  }

  /// `Failed to update privacy setting`
  String get failedToUpdatePrivacy {
    return Intl.message(
      'Failed to update privacy setting',
      name: 'failedToUpdatePrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get languageSection {
    return Intl.message(
      'Language',
      name: 'languageSection',
      desc: '',
      args: [],
    );
  }

  /// `App Language`
  String get appLanguage {
    return Intl.message(
      'App Language',
      name: 'appLanguage',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get currentLanguageName {
    return Intl.message(
      'English',
      name: 'currentLanguageName',
      desc: '',
      args: [],
    );
  }

  /// `Exit App`
  String get exitAppTitle {
    return Intl.message(
      'Exit App',
      name: 'exitAppTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to exit the app?`
  String get doYouWantToExit {
    return Intl.message(
      'Do you want to exit the app?',
      name: 'doYouWantToExit',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancelBtn {
    return Intl.message(
      'Cancel',
      name: 'cancelBtn',
      desc: '',
      args: [],
    );
  }

  /// `Exit`
  String get exitBtn {
    return Intl.message(
      'Exit',
      name: 'exitBtn',
      desc: '',
      args: [],
    );
  }

  /// `No posts loaded`
  String get noPostsLoaded {
    return Intl.message(
      'No posts loaded',
      name: 'noPostsLoaded',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load more posts`
  String get failedToLoadMorePosts {
    return Intl.message(
      'Failed to load more posts',
      name: 'failedToLoadMorePosts',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retryBtn {
    return Intl.message(
      'Retry',
      name: 'retryBtn',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong`
  String get somethingWentWrong {
    return Intl.message(
      'Something went wrong',
      name: 'somethingWentWrong',
      desc: '',
      args: [],
    );
  }

  /// `No Connection`
  String get noConnection {
    return Intl.message(
      'No Connection',
      name: 'noConnection',
      desc: '',
      args: [],
    );
  }

  /// `Server Error`
  String get serverError {
    return Intl.message(
      'Server Error',
      name: 'serverError',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection, then pull down to refresh.`
  String get checkYourConnection {
    return Intl.message(
      'Check your connection, then pull down to refresh.',
      name: 'checkYourConnection',
      desc: '',
      args: [],
    );
  }

  /// `Got it`
  String get gotItBtn {
    return Intl.message(
      'Got it',
      name: 'gotItBtn',
      desc: '',
      args: [],
    );
  }

  /// `Edit Post`
  String get editPostOption {
    return Intl.message(
      'Edit Post',
      name: 'editPostOption',
      desc: '',
      args: [],
    );
  }

  /// `Delete Post`
  String get deletePostOption {
    return Intl.message(
      'Delete Post',
      name: 'deletePostOption',
      desc: '',
      args: [],
    );
  }

  /// `Report Post`
  String get reportPostOption {
    return Intl.message(
      'Report Post',
      name: 'reportPostOption',
      desc: '',
      args: [],
    );
  }

  /// `Comments`
  String get commentsLabel {
    return Intl.message(
      'Comments',
      name: 'commentsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load comments`
  String get failedToLoadComments {
    return Intl.message(
      'Failed to load comments',
      name: 'failedToLoadComments',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get postScreenTitle {
    return Intl.message(
      'Post',
      name: 'postScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete Post?`
  String get deletePostDialogTitle {
    return Intl.message(
      'Delete Post?',
      name: 'deletePostDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this post? This action cannot be undone.`
  String get deletePostDialogContent {
    return Intl.message(
      'Are you sure you want to delete this post? This action cannot be undone.',
      name: 'deletePostDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Post deleted successfully!`
  String get postDeletedSuccessfully {
    return Intl.message(
      'Post deleted successfully!',
      name: 'postDeletedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete post.`
  String get failedToDeletePost {
    return Intl.message(
      'Failed to delete post.',
      name: 'failedToDeletePost',
      desc: '',
      args: [],
    );
  }

  /// `Failed to update post.`
  String get failedToUpdatePost {
    return Intl.message(
      'Failed to update post.',
      name: 'failedToUpdatePost',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get deleteBtn {
    return Intl.message(
      'Delete',
      name: 'deleteBtn',
      desc: '',
      args: [],
    );
  }

  /// `What's on your mind?`
  String get whatsOnYourMind {
    return Intl.message(
      'What\'s on your mind?',
      name: 'whatsOnYourMind',
      desc: '',
      args: [],
    );
  }

  /// `Share your latest music riff, thoughts, or gear...`
  String get shareYourMusicRiff {
    return Intl.message(
      'Share your latest music riff, thoughts, or gear...',
      name: 'shareYourMusicRiff',
      desc: '',
      args: [],
    );
  }

  /// `Add a caption to your share…`
  String get addCaptionToShare {
    return Intl.message(
      'Add a caption to your share…',
      name: 'addCaptionToShare',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get postBtn {
    return Intl.message(
      'Post',
      name: 'postBtn',
      desc: '',
      args: [],
    );
  }

  /// `Choose Photos`
  String get choosePhotos {
    return Intl.message(
      'Choose Photos',
      name: 'choosePhotos',
      desc: '',
      args: [],
    );
  }

  /// `Take a Photo`
  String get takeAPhoto {
    return Intl.message(
      'Take a Photo',
      name: 'takeAPhoto',
      desc: '',
      args: [],
    );
  }

  /// `Choose Video`
  String get chooseVideo {
    return Intl.message(
      'Choose Video',
      name: 'chooseVideo',
      desc: '',
      args: [],
    );
  }

  /// `Record Video`
  String get recordVideo {
    return Intl.message(
      'Record Video',
      name: 'recordVideo',
      desc: '',
      args: [],
    );
  }

  /// `Add more`
  String get addMore {
    return Intl.message(
      'Add more',
      name: 'addMore',
      desc: '',
      args: [],
    );
  }

  /// `Tap to add photos or videos`
  String get tapToAddPhotosOrVideos {
    return Intl.message(
      'Tap to add photos or videos',
      name: 'tapToAddPhotosOrVideos',
      desc: '',
      args: [],
    );
  }

  /// `Please enter content before posting.`
  String get pleaseEnterContentBeforePosting {
    return Intl.message(
      'Please enter content before posting.',
      name: 'pleaseEnterContentBeforePosting',
      desc: '',
      args: [],
    );
  }

  /// `Maximum {max} files allowed.`
  String maximumFilesAllowed(int max) {
    return Intl.message(
      'Maximum $max files allowed.',
      name: 'maximumFilesAllowed',
      desc: '',
      args: [max],
    );
  }

  /// `Save Changes`
  String get saveChangesBtn {
    return Intl.message(
      'Save Changes',
      name: 'saveChangesBtn',
      desc: '',
      args: [],
    );
  }

  /// `Please enter content before updating.`
  String get pleaseEnterContentBeforeUpdating {
    return Intl.message(
      'Please enter content before updating.',
      name: 'pleaseEnterContentBeforeUpdating',
      desc: '',
      args: [],
    );
  }

  /// `Failed to create post.`
  String get failedToCreatePost {
    return Intl.message(
      'Failed to create post.',
      name: 'failedToCreatePost',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get youLabel {
    return Intl.message(
      'You',
      name: 'youLabel',
      desc: '',
      args: [],
    );
  }

  /// `Failed to send comment`
  String get failedToSendComment {
    return Intl.message(
      'Failed to send comment',
      name: 'failedToSendComment',
      desc: '',
      args: [],
    );
  }

  /// `Failed to update like`
  String get failedToUpdateLike {
    return Intl.message(
      'Failed to update like',
      name: 'failedToUpdateLike',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this comment?`
  String get areYouSureDeleteComment {
    return Intl.message(
      'Are you sure you want to delete this comment?',
      name: 'areYouSureDeleteComment',
      desc: '',
      args: [],
    );
  }

  /// `Comment deleted`
  String get commentDeleted {
    return Intl.message(
      'Comment deleted',
      name: 'commentDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete comment`
  String get failedToDeleteComment {
    return Intl.message(
      'Failed to delete comment',
      name: 'failedToDeleteComment',
      desc: '',
      args: [],
    );
  }

  /// `Comment updated`
  String get commentUpdated {
    return Intl.message(
      'Comment updated',
      name: 'commentUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Failed to update comment`
  String get failedToUpdateComment {
    return Intl.message(
      'Failed to update comment',
      name: 'failedToUpdateComment',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get editLabel {
    return Intl.message(
      'Edit',
      name: 'editLabel',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get reportLabel {
    return Intl.message(
      'Report',
      name: 'reportLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit your comment...`
  String get editYourComment {
    return Intl.message(
      'Edit your comment...',
      name: 'editYourComment',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get updateBtn {
    return Intl.message(
      'Update',
      name: 'updateBtn',
      desc: '',
      args: [],
    );
  }

  /// `Add a comment…`
  String get addAComment {
    return Intl.message(
      'Add a comment…',
      name: 'addAComment',
      desc: '',
      args: [],
    );
  }

  /// `Comment cannot be empty`
  String get commentCannotBeEmpty {
    return Intl.message(
      'Comment cannot be empty',
      name: 'commentCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No comments yet`
  String get noCommentsYet {
    return Intl.message(
      'No comments yet',
      name: 'noCommentsYet',
      desc: '',
      args: [],
    );
  }

  /// `Be the first to say something!`
  String get beFirstToSaySomething {
    return Intl.message(
      'Be the first to say something!',
      name: 'beFirstToSaySomething',
      desc: '',
      args: [],
    );
  }

  /// `Unlike`
  String get unlike {
    return Intl.message(
      'Unlike',
      name: 'unlike',
      desc: '',
      args: [],
    );
  }

  /// `Like`
  String get likeBtn {
    return Intl.message(
      'Like',
      name: 'likeBtn',
      desc: '',
      args: [],
    );
  }

  /// `Write a caption… (optional)`
  String get writeCaption {
    return Intl.message(
      'Write a caption… (optional)',
      name: 'writeCaption',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get shareBtn {
    return Intl.message(
      'Share',
      name: 'shareBtn',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get unknown {
    return Intl.message(
      'Unknown',
      name: 'unknown',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get videoLabel {
    return Intl.message(
      'Video',
      name: 'videoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Search people or posts…`
  String get searchHint {
    return Intl.message(
      'Search people or posts…',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Genres`
  String get genresFilter {
    return Intl.message(
      'Genres',
      name: 'genresFilter',
      desc: '',
      args: [],
    );
  }

  /// `Instruments`
  String get instrumentsFilter {
    return Intl.message(
      'Instruments',
      name: 'instrumentsFilter',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clearFilter {
    return Intl.message(
      'Clear',
      name: 'clearFilter',
      desc: '',
      args: [],
    );
  }

  /// `People`
  String get peopleSection {
    return Intl.message(
      'People',
      name: 'peopleSection',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get postsSection {
    return Intl.message(
      'Posts',
      name: 'postsSection',
      desc: '',
      args: [],
    );
  }

  /// `No posts in "{filterLabel}" yet`
  String noPostsInCategory(String filterLabel) {
    return Intl.message(
      'No posts in "$filterLabel" yet',
      name: 'noPostsInCategory',
      desc: '',
      args: [filterLabel],
    );
  }

  /// `Nothing to discover yet`
  String get nothingToDiscoverYet {
    return Intl.message(
      'Nothing to discover yet',
      name: 'nothingToDiscoverYet',
      desc: '',
      args: [],
    );
  }

  /// `Be the first to post something in this category.`
  String get beFirstToPostInCategory {
    return Intl.message(
      'Be the first to post something in this category.',
      name: 'beFirstToPostInCategory',
      desc: '',
      args: [],
    );
  }

  /// `Follow more people to grow\nyour discovery feed.`
  String get followMorePeople {
    return Intl.message(
      'Follow more people to grow\nyour discovery feed.',
      name: 'followMorePeople',
      desc: '',
      args: [],
    );
  }

  /// `No results for "{query}"`
  String noResultsForQuery(String query) {
    return Intl.message(
      'No results for "$query"',
      name: 'noResultsForQuery',
      desc: '',
      args: [query],
    );
  }

  /// `Try a different name\nor search term.`
  String get tryDifferentName {
    return Intl.message(
      'Try a different name\nor search term.',
      name: 'tryDifferentName',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notificationsTitle {
    return Intl.message(
      'Notifications',
      name: 'notificationsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Mark all read`
  String get markAllRead {
    return Intl.message(
      'Mark all read',
      name: 'markAllRead',
      desc: '',
      args: [],
    );
  }

  /// `No notifications yet`
  String get noNotificationsYet {
    return Intl.message(
      'No notifications yet',
      name: 'noNotificationsYet',
      desc: '',
      args: [],
    );
  }

  /// `started following you.`
  String get startedFollowingYou {
    return Intl.message(
      'started following you.',
      name: 'startedFollowingYou',
      desc: '',
      args: [],
    );
  }

  /// `requested to follow you.`
  String get requestedToFollowYou {
    return Intl.message(
      'requested to follow you.',
      name: 'requestedToFollowYou',
      desc: '',
      args: [],
    );
  }

  /// `accepted your follow request.`
  String get acceptedYourFollowRequest {
    return Intl.message(
      'accepted your follow request.',
      name: 'acceptedYourFollowRequest',
      desc: '',
      args: [],
    );
  }

  /// `Complete your profile to get discovered!`
  String get completeYourProfile {
    return Intl.message(
      'Complete your profile to get discovered!',
      name: 'completeYourProfile',
      desc: '',
      args: [],
    );
  }

  /// `liked your comment.`
  String get likedYourComment {
    return Intl.message(
      'liked your comment.',
      name: 'likedYourComment',
      desc: '',
      args: [],
    );
  }

  /// `liked your post.`
  String get likedYourPost {
    return Intl.message(
      'liked your post.',
      name: 'likedYourPost',
      desc: '',
      args: [],
    );
  }

  /// `commented on your post.`
  String get commentedOnYourPost {
    return Intl.message(
      'commented on your post.',
      name: 'commentedOnYourPost',
      desc: '',
      args: [],
    );
  }

  /// `Loading post…`
  String get loadingPost {
    return Intl.message(
      'Loading post…',
      name: 'loadingPost',
      desc: '',
      args: [],
    );
  }

  /// `Report Post`
  String get reportPostTitle {
    return Intl.message(
      'Report Post',
      name: 'reportPostTitle',
      desc: '',
      args: [],
    );
  }

  /// `Why are you reporting this post?`
  String get whyReportingPost {
    return Intl.message(
      'Why are you reporting this post?',
      name: 'whyReportingPost',
      desc: '',
      args: [],
    );
  }

  /// `Additional details (optional)`
  String get additionalDetails {
    return Intl.message(
      'Additional details (optional)',
      name: 'additionalDetails',
      desc: '',
      args: [],
    );
  }

  /// `Tell us more about the issue...`
  String get tellUsMoreAboutIssue {
    return Intl.message(
      'Tell us more about the issue...',
      name: 'tellUsMoreAboutIssue',
      desc: '',
      args: [],
    );
  }

  /// `Your report is anonymous. We review all reports carefully.`
  String get yourReportIsAnonymous {
    return Intl.message(
      'Your report is anonymous. We review all reports carefully.',
      name: 'yourReportIsAnonymous',
      desc: '',
      args: [],
    );
  }

  /// `Submit Report`
  String get submitReportBtn {
    return Intl.message(
      'Submit Report',
      name: 'submitReportBtn',
      desc: '',
      args: [],
    );
  }

  /// `Please select a reason`
  String get pleaseSelectAReason {
    return Intl.message(
      'Please select a reason',
      name: 'pleaseSelectAReason',
      desc: '',
      args: [],
    );
  }

  /// `Report submitted. Thank you.`
  String get reportSubmittedThankYou {
    return Intl.message(
      'Report submitted. Thank you.',
      name: 'reportSubmittedThankYou',
      desc: '',
      args: [],
    );
  }

  /// `Failed to submit report. Try again.`
  String get failedToSubmitReport {
    return Intl.message(
      'Failed to submit report. Try again.',
      name: 'failedToSubmitReport',
      desc: '',
      args: [],
    );
  }

  /// `Spam or misleading`
  String get spamOrMisleading {
    return Intl.message(
      'Spam or misleading',
      name: 'spamOrMisleading',
      desc: '',
      args: [],
    );
  }

  /// `Hate speech or discrimination`
  String get hateSpeechOrDiscrimination {
    return Intl.message(
      'Hate speech or discrimination',
      name: 'hateSpeechOrDiscrimination',
      desc: '',
      args: [],
    );
  }

  /// `Violence or dangerous content`
  String get violenceOrDangerous {
    return Intl.message(
      'Violence or dangerous content',
      name: 'violenceOrDangerous',
      desc: '',
      args: [],
    );
  }

  /// `Nudity or sexual content`
  String get nudityOrSexual {
    return Intl.message(
      'Nudity or sexual content',
      name: 'nudityOrSexual',
      desc: '',
      args: [],
    );
  }

  /// `Harassment or bullying`
  String get harassmentOrBullying {
    return Intl.message(
      'Harassment or bullying',
      name: 'harassmentOrBullying',
      desc: '',
      args: [],
    );
  }

  /// `False information`
  String get falseInformation {
    return Intl.message(
      'False information',
      name: 'falseInformation',
      desc: '',
      args: [],
    );
  }

  /// `Intellectual property violation`
  String get intellectualPropertyViolation {
    return Intl.message(
      'Intellectual property violation',
      name: 'intellectualPropertyViolation',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get otherReason {
    return Intl.message(
      'Other',
      name: 'otherReason',
      desc: '',
      args: [],
    );
  }

  /// `Report Comment`
  String get reportCommentTitle {
    return Intl.message(
      'Report Comment',
      name: 'reportCommentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Why are you reporting this comment?`
  String get whyReportingComment {
    return Intl.message(
      'Why are you reporting this comment?',
      name: 'whyReportingComment',
      desc: '',
      args: [],
    );
  }

  /// `Choose from Gallery`
  String get chooseFromGalleryProfile {
    return Intl.message(
      'Choose from Gallery',
      name: 'chooseFromGalleryProfile',
      desc: '',
      args: [],
    );
  }

  /// `Profile photo updated`
  String get profilePhotoUpdated {
    return Intl.message(
      'Profile photo updated',
      name: 'profilePhotoUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get postsLabel {
    return Intl.message(
      'Posts',
      name: 'postsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get postLabel {
    return Intl.message(
      'Post',
      name: 'postLabel',
      desc: '',
      args: [],
    );
  }

  /// `Followers`
  String get followersLabel {
    return Intl.message(
      'Followers',
      name: 'followersLabel',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get followingLabel {
    return Intl.message(
      'Following',
      name: 'followingLabel',
      desc: '',
      args: [],
    );
  }

  /// `No posts yet`
  String get noPostsYet {
    return Intl.message(
      'No posts yet',
      name: 'noPostsYet',
      desc: '',
      args: [],
    );
  }

  /// `Unfollow`
  String get unfollowBtn {
    return Intl.message(
      'Unfollow',
      name: 'unfollowBtn',
      desc: '',
      args: [],
    );
  }

  /// `Requested`
  String get requestedBtn {
    return Intl.message(
      'Requested',
      name: 'requestedBtn',
      desc: '',
      args: [],
    );
  }

  /// `Request`
  String get requestBtn {
    return Intl.message(
      'Request',
      name: 'requestBtn',
      desc: '',
      args: [],
    );
  }

  /// `Genres`
  String get genresSection {
    return Intl.message(
      'Genres',
      name: 'genresSection',
      desc: '',
      args: [],
    );
  }

  /// `Instruments`
  String get instrumentsSection {
    return Intl.message(
      'Instruments',
      name: 'instrumentsSection',
      desc: '',
      args: [],
    );
  }

  /// `Followers`
  String get followersTitle {
    return Intl.message(
      'Followers',
      name: 'followersTitle',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get followingTitle {
    return Intl.message(
      'Following',
      name: 'followingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load`
  String get failedToLoad {
    return Intl.message(
      'Failed to load',
      name: 'failedToLoad',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchHintFollow {
    return Intl.message(
      'Search',
      name: 'searchHintFollow',
      desc: '',
      args: [],
    );
  }

  /// `No results for "{query}"`
  String noResultsForQueryShort(String query) {
    return Intl.message(
      'No results for "$query"',
      name: 'noResultsForQueryShort',
      desc: '',
      args: [query],
    );
  }

  /// `No followers yet`
  String get noFollowersYet {
    return Intl.message(
      'No followers yet',
      name: 'noFollowersYet',
      desc: '',
      args: [],
    );
  }

  /// `Not following anyone`
  String get notFollowingAnyone {
    return Intl.message(
      'Not following anyone',
      name: 'notFollowingAnyone',
      desc: '',
      args: [],
    );
  }

  /// `When someone follows this account,\nthey'll appear here.`
  String get whenSomeonFollows {
    return Intl.message(
      'When someone follows this account,\nthey\'ll appear here.',
      name: 'whenSomeonFollows',
      desc: '',
      args: [],
    );
  }

  /// `Accounts followed\nwill appear here.`
  String get accountsFollowed {
    return Intl.message(
      'Accounts followed\nwill appear here.',
      name: 'accountsFollowed',
      desc: '',
      args: [],
    );
  }

  /// `No reels yet.\nPost a video to get started!`
  String get noReelsYet {
    return Intl.message(
      'No reels yet.\nPost a video to get started!',
      name: 'noReelsYet',
      desc: '',
      args: [],
    );
  }

  /// `Report a Bug`
  String get reportABugTitle {
    return Intl.message(
      'Report a Bug',
      name: 'reportABugTitle',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get bugTitleLabel {
    return Intl.message(
      'Title',
      name: 'bugTitleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Short summary of the bug`
  String get shortSummaryOfBug {
    return Intl.message(
      'Short summary of the bug',
      name: 'shortSummaryOfBug',
      desc: '',
      args: [],
    );
  }

  /// `What happened?`
  String get whatHappened {
    return Intl.message(
      'What happened?',
      name: 'whatHappened',
      desc: '',
      args: [],
    );
  }

  /// `Describe the bug in detail...`
  String get describeBugInDetail {
    return Intl.message(
      'Describe the bug in detail...',
      name: 'describeBugInDetail',
      desc: '',
      args: [],
    );
  }

  /// `Steps to reproduce (optional)`
  String get stepsToReproduce {
    return Intl.message(
      'Steps to reproduce (optional)',
      name: 'stepsToReproduce',
      desc: '',
      args: [],
    );
  }

  /// `1. Open app\n2. Tap on...`
  String get stepsHint {
    return Intl.message(
      '1. Open app\n2. Tap on...',
      name: 'stepsHint',
      desc: '',
      args: [],
    );
  }

  /// `Severity`
  String get severityLabel {
    return Intl.message(
      'Severity',
      name: 'severityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Low`
  String get lowSeverity {
    return Intl.message(
      'Low',
      name: 'lowSeverity',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get mediumSeverity {
    return Intl.message(
      'Medium',
      name: 'mediumSeverity',
      desc: '',
      args: [],
    );
  }

  /// `High`
  String get highSeverity {
    return Intl.message(
      'High',
      name: 'highSeverity',
      desc: '',
      args: [],
    );
  }

  /// `Critical`
  String get criticalSeverity {
    return Intl.message(
      'Critical',
      name: 'criticalSeverity',
      desc: '',
      args: [],
    );
  }

  /// `Submit Bug Report`
  String get submitBugReportBtn {
    return Intl.message(
      'Submit Bug Report',
      name: 'submitBugReportBtn',
      desc: '',
      args: [],
    );
  }

  /// `Bug report submitted. Thank you!`
  String get bugReportSubmitted {
    return Intl.message(
      'Bug report submitted. Thank you!',
      name: 'bugReportSubmitted',
      desc: '',
      args: [],
    );
  }

  /// `Failed to submit. Please try again.`
  String get failedToSubmit {
    return Intl.message(
      'Failed to submit. Please try again.',
      name: 'failedToSubmit',
      desc: '',
      args: [],
    );
  }

  /// `Please add a title`
  String get pleaseAddTitle {
    return Intl.message(
      'Please add a title',
      name: 'pleaseAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please describe the bug`
  String get pleaseDescribeBug {
    return Intl.message(
      'Please describe the bug',
      name: 'pleaseDescribeBug',
      desc: '',
      args: [],
    );
  }

  /// `Feature Request`
  String get featureRequestTitle {
    return Intl.message(
      'Feature Request',
      name: 'featureRequestTitle',
      desc: '',
      args: [],
    );
  }

  /// `Share your idea with the Riff team`
  String get shareYourIdeaWithRiff {
    return Intl.message(
      'Share your idea with the Riff team',
      name: 'shareYourIdeaWithRiff',
      desc: '',
      args: [],
    );
  }

  /// `Feature title`
  String get featureTitleLabel {
    return Intl.message(
      'Feature title',
      name: 'featureTitleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Describe the feature`
  String get describeTheFeature {
    return Intl.message(
      'Describe the feature',
      name: 'describeTheFeature',
      desc: '',
      args: [],
    );
  }

  /// `What should it do? How should it work?`
  String get whatShouldItDo {
    return Intl.message(
      'What should it do? How should it work?',
      name: 'whatShouldItDo',
      desc: '',
      args: [],
    );
  }

  /// `Why would this be useful? (optional)`
  String get whyWouldBeUseful {
    return Intl.message(
      'Why would this be useful? (optional)',
      name: 'whyWouldBeUseful',
      desc: '',
      args: [],
    );
  }

  /// `Who would benefit and how?`
  String get whoBenefitAndHow {
    return Intl.message(
      'Who would benefit and how?',
      name: 'whoBenefitAndHow',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Dark mode for comments`
  String get featureTitleHint {
    return Intl.message(
      'e.g. Dark mode for comments',
      name: 'featureTitleHint',
      desc: '',
      args: [],
    );
  }

  /// `Submit Request`
  String get submitRequestBtn {
    return Intl.message(
      'Submit Request',
      name: 'submitRequestBtn',
      desc: '',
      args: [],
    );
  }

  /// `Feature request submitted. Thank you!`
  String get featureRequestSubmitted {
    return Intl.message(
      'Feature request submitted. Thank you!',
      name: 'featureRequestSubmitted',
      desc: '',
      args: [],
    );
  }

  /// `Please describe your feature request`
  String get pleaseDescribeFeature {
    return Intl.message(
      'Please describe your feature request',
      name: 'pleaseDescribeFeature',
      desc: '',
      args: [],
    );
  }

  /// `Messages coming soon`
  String get messagesComingSoon {
    return Intl.message(
      'Messages coming soon',
      name: 'messagesComingSoon',
      desc: '',
      args: [],
    );
  }

  /// `Direct messaging is being built.\nCheck back in the next update.`
  String get directMessagingBeingBuilt {
    return Intl.message(
      'Direct messaging is being built.\nCheck back in the next update.',
      name: 'directMessagingBeingBuilt',
      desc: '',
      args: [],
    );
  }

  /// `Message…`
  String get messageHint {
    return Intl.message(
      'Message…',
      name: 'messageHint',
      desc: '',
      args: [],
    );
  }

  /// `Sponsored`
  String get sponsored {
    return Intl.message(
      'Sponsored',
      name: 'sponsored',
      desc: '',
      args: [],
    );
  }

  /// `Post updated successfully!`
  String get postUpdatedSuccessfully {
    return Intl.message(
      'Post updated successfully!',
      name: 'postUpdatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Post created successfully!`
  String get postCreatedSuccessfully {
    return Intl.message(
      'Post created successfully!',
      name: 'postCreatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Your caption`
  String get yourCaption {
    return Intl.message(
      'Your caption',
      name: 'yourCaption',
      desc: '',
      args: [],
    );
  }

  /// `Shared post`
  String get sharedPost {
    return Intl.message(
      'Shared post',
      name: 'sharedPost',
      desc: '',
      args: [],
    );
  }

  /// `Media`
  String get mediaLabel {
    return Intl.message(
      'Media',
      name: 'mediaLabel',
      desc: '',
      args: [],
    );
  }

  /// `Attach Media`
  String get attachMedia {
    return Intl.message(
      'Attach Media',
      name: 'attachMedia',
      desc: '',
      args: [],
    );
  }

  /// `Add genres & instruments to get discovered by other musicians.`
  String get addGenresInstruments {
    return Intl.message(
      'Add genres & instruments to get discovered by other musicians.',
      name: 'addGenresInstruments',
      desc: '',
      args: [],
    );
  }

  /// `Declined`
  String get declined {
    return Intl.message(
      'Declined',
      name: 'declined',
      desc: '',
      args: [],
    );
  }

  /// `Post not found or was deleted.`
  String get postNotFoundDeleted {
    return Intl.message(
      'Post not found or was deleted.',
      name: 'postNotFoundDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Flagged Comment`
  String get flaggedComment {
    return Intl.message(
      'Flagged Comment',
      name: 'flaggedComment',
      desc: '',
      args: [],
    );
  }

  /// `Flagged Post`
  String get flaggedPost {
    return Intl.message(
      'Flagged Post',
      name: 'flaggedPost',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code`
  String get enterTheCode {
    return Intl.message(
      'Enter the code',
      name: 'enterTheCode',
      desc: '',
      args: [],
    );
  }

  /// `Add a profile photo`
  String get addAProfilePhoto {
    return Intl.message(
      'Add a profile photo',
      name: 'addAProfilePhoto',
      desc: '',
      args: [],
    );
  }

  /// `What do you listen to?`
  String get whatDoYouListenTo {
    return Intl.message(
      'What do you listen to?',
      name: 'whatDoYouListenTo',
      desc: '',
      args: [],
    );
  }

  /// `What do you play?`
  String get whatDoYouPlay {
    return Intl.message(
      'What do you play?',
      name: 'whatDoYouPlay',
      desc: '',
      args: [],
    );
  }

  /// `Delete Comment`
  String get deleteCommentTitle {
    return Intl.message(
      'Delete Comment',
      name: 'deleteCommentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit Comment`
  String get editCommentTitle {
    return Intl.message(
      'Edit Comment',
      name: 'editCommentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Remove Follower?`
  String get removeFollowerTitle {
    return Intl.message(
      'Remove Follower?',
      name: 'removeFollowerTitle',
      desc: '',
      args: [],
    );
  }

  /// `Keep`
  String get keepBtn {
    return Intl.message(
      'Keep',
      name: 'keepBtn',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get removeBtn {
    return Intl.message(
      'Remove',
      name: 'removeBtn',
      desc: '',
      args: [],
    );
  }

  /// `Feed`
  String get feedTitle {
    return Intl.message(
      'Feed',
      name: 'feedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchTitle {
    return Intl.message(
      'Search',
      name: 'searchTitle',
      desc: '',
      args: [],
    );
  }

  /// `Reels`
  String get reelsTitle {
    return Intl.message(
      'Reels',
      name: 'reelsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Username must contain only English letters, numbers, underscores or dots`
  String get usernameEnglishOnly {
    return Intl.message(
      'Username must contain only English letters, numbers, underscores or dots',
      name: 'usernameEnglishOnly',
      desc: '',
      args: [],
    );
  }

  /// `This phone number is already linked to another account`
  String get phoneNumberAlreadyTaken {
    return Intl.message(
      'This phone number is already linked to another account',
      name: 'phoneNumberAlreadyTaken',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Password`
  String get confirmPassword {
    return Intl.message(
      'Confirm Password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Re-enter your password`
  String get enterConfirmPassword {
    return Intl.message(
      'Re-enter your password',
      name: 'enterConfirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Weak`
  String get passwordStrengthWeak {
    return Intl.message(
      'Weak',
      name: 'passwordStrengthWeak',
      desc: '',
      args: [],
    );
  }

  /// `Fair`
  String get passwordStrengthFair {
    return Intl.message(
      'Fair',
      name: 'passwordStrengthFair',
      desc: '',
      args: [],
    );
  }

  /// `Good`
  String get passwordStrengthGood {
    return Intl.message(
      'Good',
      name: 'passwordStrengthGood',
      desc: '',
      args: [],
    );
  }

  /// `Strong`
  String get passwordStrengthStrong {
    return Intl.message(
      'Strong',
      name: 'passwordStrengthStrong',
      desc: '',
      args: [],
    );
  }

  /// `At least 8 characters`
  String get passwordReqLength {
    return Intl.message(
      'At least 8 characters',
      name: 'passwordReqLength',
      desc: '',
      args: [],
    );
  }

  /// `One uppercase letter`
  String get passwordReqUppercase {
    return Intl.message(
      'One uppercase letter',
      name: 'passwordReqUppercase',
      desc: '',
      args: [],
    );
  }

  /// `One lowercase letter`
  String get passwordReqLowercase {
    return Intl.message(
      'One lowercase letter',
      name: 'passwordReqLowercase',
      desc: '',
      args: [],
    );
  }

  /// `One number`
  String get passwordReqNumber {
    return Intl.message(
      'One number',
      name: 'passwordReqNumber',
      desc: '',
      args: [],
    );
  }

  /// `One special character`
  String get passwordReqSpecial {
    return Intl.message(
      'One special character',
      name: 'passwordReqSpecial',
      desc: '',
      args: [],
    );
  }

  /// `Email or Username`
  String get emailOrUsername {
    return Intl.message(
      'Email or Username',
      name: 'emailOrUsername',
      desc: '',
      args: [],
    );
  }

  /// `Enter email or username`
  String get enterEmailOrUsername {
    return Intl.message(
      'Enter email or username',
      name: 'enterEmailOrUsername',
      desc: '',
      args: [],
    );
  }

  /// `This account uses Google Sign-In. Please use 'Continue with Google' to log in.`
  String get linkedToGoogleAccount {
    return Intl.message(
      'This account uses Google Sign-In. Please use \'Continue with Google\' to log in.',
      name: 'linkedToGoogleAccount',
      desc: '',
      args: [],
    );
  }

  /// `Google sign-in was cancelled or failed. Please try again.`
  String get googleSignInFailed {
    return Intl.message(
      'Google sign-in was cancelled or failed. Please try again.',
      name: 'googleSignInFailed',
      desc: '',
      args: [],
    );
  }

  /// `This Gmail is already linked to an account. Logging you in...`
  String get gmailAlreadyLinked {
    return Intl.message(
      'This Gmail is already linked to an account. Logging you in...',
      name: 'gmailAlreadyLinked',
      desc: '',
      args: [],
    );
  }

  /// `Account Found`
  String get gmailAlreadyLinkedTitle {
    return Intl.message(
      'Account Found',
      name: 'gmailAlreadyLinkedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get chatMessagesTitle {
    return Intl.message(
      'Messages',
      name: 'chatMessagesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Chats`
  String get chatTabChats {
    return Intl.message(
      'Chats',
      name: 'chatTabChats',
      desc: '',
      args: [],
    );
  }

  /// `Requests`
  String get chatTabRequests {
    return Intl.message(
      'Requests',
      name: 'chatTabRequests',
      desc: '',
      args: [],
    );
  }

  /// `Search people and conversations…`
  String get searchConversationsHint {
    return Intl.message(
      'Search people and conversations…',
      name: 'searchConversationsHint',
      desc: '',
      args: [],
    );
  }

  /// `No conversations yet.\nSearch for someone to start chatting.`
  String get noConversationsYet {
    return Intl.message(
      'No conversations yet.\nSearch for someone to start chatting.',
      name: 'noConversationsYet',
      desc: '',
      args: [],
    );
  }

  /// `No message requests`
  String get noMessageRequests {
    return Intl.message(
      'No message requests',
      name: 'noMessageRequests',
      desc: '',
      args: [],
    );
  }

  /// `Conversations`
  String get conversationsSectionLabel {
    return Intl.message(
      'Conversations',
      name: 'conversationsSectionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get messageBtn {
    return Intl.message(
      'Message',
      name: 'messageBtn',
      desc: '',
      args: [],
    );
  }

  /// `New Group`
  String get newGroupTitle {
    return Intl.message(
      'New Group',
      name: 'newGroupTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get createGroupBtn {
    return Intl.message(
      'Create',
      name: 'createGroupBtn',
      desc: '',
      args: [],
    );
  }

  /// `Group name`
  String get groupNameHint {
    return Intl.message(
      'Group name',
      name: 'groupNameHint',
      desc: '',
      args: [],
    );
  }

  /// `Description (optional)`
  String get groupDescriptionHint {
    return Intl.message(
      'Description (optional)',
      name: 'groupDescriptionHint',
      desc: '',
      args: [],
    );
  }

  /// `Search users…`
  String get searchUsersHint {
    return Intl.message(
      'Search users…',
      name: 'searchUsersHint',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a group name`
  String get groupNameRequired {
    return Intl.message(
      'Please enter a group name',
      name: 'groupNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Add at least one member`
  String get groupMemberRequired {
    return Intl.message(
      'Add at least one member',
      name: 'groupMemberRequired',
      desc: '',
      args: [],
    );
  }

  /// `Error: {message}`
  String groupCreationError(String message) {
    return Intl.message(
      'Error: $message',
      name: 'groupCreationError',
      desc: '',
      args: [message],
    );
  }

  /// `Group Info`
  String get groupDetailsTitle {
    return Intl.message(
      'Group Info',
      name: 'groupDetailsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Members`
  String get groupMembersSection {
    return Intl.message(
      'Members',
      name: 'groupMembersSection',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get groupAdminBadge {
    return Intl.message(
      'Admin',
      name: 'groupAdminBadge',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get groupDescriptionLabel {
    return Intl.message(
      'Description',
      name: 'groupDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `No description`
  String get groupNoDescription {
    return Intl.message(
      'No description',
      name: 'groupNoDescription',
      desc: '',
      args: [],
    );
  }

  /// `Delete for everyone`
  String get deleteForEveryoneBtn {
    return Intl.message(
      'Delete for everyone',
      name: 'deleteForEveryoneBtn',
      desc: '',
      args: [],
    );
  }

  /// `Delete conversation?`
  String get deleteConversationTitle {
    return Intl.message(
      'Delete conversation?',
      name: 'deleteConversationTitle',
      desc: '',
      args: [],
    );
  }

  /// `This will permanently delete all messages for everyone in this chat.`
  String get deleteConversationContent {
    return Intl.message(
      'This will permanently delete all messages for everyone in this chat.',
      name: 'deleteConversationContent',
      desc: '',
      args: [],
    );
  }

  /// `Conversation deleted`
  String get conversationDeleted {
    return Intl.message(
      'Conversation deleted',
      name: 'conversationDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Could not delete conversation.`
  String get couldNotDeleteConversation {
    return Intl.message(
      'Could not delete conversation.',
      name: 'couldNotDeleteConversation',
      desc: '',
      args: [],
    );
  }

  /// `Delete message`
  String get deleteMessageOption {
    return Intl.message(
      'Delete message',
      name: 'deleteMessageOption',
      desc: '',
      args: [],
    );
  }

  /// `Accept`
  String get acceptBtn {
    return Intl.message(
      'Accept',
      name: 'acceptBtn',
      desc: '',
      args: [],
    );
  }

  /// `Decline`
  String get declineBtn {
    return Intl.message(
      'Decline',
      name: 'declineBtn',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get presenceOnline {
    return Intl.message(
      'Online',
      name: 'presenceOnline',
      desc: '',
      args: [],
    );
  }

  /// `Last seen just now`
  String get presenceLastSeenJustNow {
    return Intl.message(
      'Last seen just now',
      name: 'presenceLastSeenJustNow',
      desc: '',
      args: [],
    );
  }

  /// `Last seen {n}m ago`
  String presenceLastSeenMinutes(int n) {
    return Intl.message(
      'Last seen ${n}m ago',
      name: 'presenceLastSeenMinutes',
      desc: '',
      args: [n],
    );
  }

  /// `Last seen today at {time}`
  String presenceLastSeenTodayAt(String time) {
    return Intl.message(
      'Last seen today at $time',
      name: 'presenceLastSeenTodayAt',
      desc: '',
      args: [time],
    );
  }

  /// `Last seen yesterday at {time}`
  String presenceLastSeenYesterdayAt(String time) {
    return Intl.message(
      'Last seen yesterday at $time',
      name: 'presenceLastSeenYesterdayAt',
      desc: '',
      args: [time],
    );
  }

  /// `Last seen {date}`
  String presenceLastSeenDate(String date) {
    return Intl.message(
      'Last seen $date',
      name: 'presenceLastSeenDate',
      desc: '',
      args: [date],
    );
  }

  /// `Sending photo…`
  String get sendingPhoto {
    return Intl.message(
      'Sending photo…',
      name: 'sendingPhoto',
      desc: '',
      args: [],
    );
  }

  /// `Sending video…`
  String get sendingVideo {
    return Intl.message(
      'Sending video…',
      name: 'sendingVideo',
      desc: '',
      args: [],
    );
  }

  /// `Sending voice…`
  String get sendingVoice {
    return Intl.message(
      'Sending voice…',
      name: 'sendingVoice',
      desc: '',
      args: [],
    );
  }

  /// `Sending file…`
  String get sendingFile {
    return Intl.message(
      'Sending file…',
      name: 'sendingFile',
      desc: '',
      args: [],
    );
  }

  /// `{name} wants to send you a message.\nThey can't see that you've viewed this request.`
  String requestInfoMessage(String name) {
    return Intl.message(
      '$name wants to send you a message.\nThey can\'t see that you\'ve viewed this request.',
      name: 'requestInfoMessage',
      desc: '',
      args: [name],
    );
  }

  /// `Blocked Users`
  String get blockedUsersDrawer {
    return Intl.message(
      'Blocked Users',
      name: 'blockedUsersDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Manage who you have blocked`
  String get manageBlockedUsers {
    return Intl.message(
      'Manage who you have blocked',
      name: 'manageBlockedUsers',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicyDrawer {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicyDrawer',
      desc: '',
      args: [],
    );
  }

  /// `How we handle your data`
  String get howWeHandleData {
    return Intl.message(
      'How we handle your data',
      name: 'howWeHandleData',
      desc: '',
      args: [],
    );
  }

  /// `I have read and agree to the `
  String get privacyPolicyConsentPrefix {
    return Intl.message(
      'I have read and agree to the ',
      name: 'privacyPolicyConsentPrefix',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicyLinkText {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicyLinkText',
      desc: '',
      args: [],
    );
  }

  /// `Please read and accept the Privacy Policy to continue.`
  String get privacyPolicyRequiredSnackbar {
    return Intl.message(
      'Please read and accept the Privacy Policy to continue.',
      name: 'privacyPolicyRequiredSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicyScreenTitle {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicyScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Riff Privacy Policy`
  String get privacyPolicyHeaderTitle {
    return Intl.message(
      'Riff Privacy Policy',
      name: 'privacyPolicyHeaderTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your privacy matters to us. Read how we collect, use, and protect your data.`
  String get privacyPolicyHeaderSubtitle {
    return Intl.message(
      'Your privacy matters to us. Read how we collect, use, and protect your data.',
      name: 'privacyPolicyHeaderSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `1. Introduction`
  String get ppSection1Title {
    return Intl.message(
      '1. Introduction',
      name: 'ppSection1Title',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Riff ("we", "our", or "us"). Riff is a music-focused social platform that lets you share your passion for music, connect with other musicians and fans, and communicate through direct and group messaging.\n\nThis Privacy Policy explains what information we collect, how we use it, and your rights regarding your data. By creating an account or using Riff, you agree to this policy.`
  String get ppSection1Body {
    return Intl.message(
      'Welcome to Riff ("we", "our", or "us"). Riff is a music-focused social platform that lets you share your passion for music, connect with other musicians and fans, and communicate through direct and group messaging.\n\nThis Privacy Policy explains what information we collect, how we use it, and your rights regarding your data. By creating an account or using Riff, you agree to this policy.',
      name: 'ppSection1Body',
      desc: '',
      args: [],
    );
  }

  /// `2. Information We Collect`
  String get ppSection2Title {
    return Intl.message(
      '2. Information We Collect',
      name: 'ppSection2Title',
      desc: '',
      args: [],
    );
  }

  /// `Account information — When you sign up, we collect your full name, username, email address, and password (stored as a one-way hash).\n\nProfile information — Profile picture, bio, and music preferences including instruments you play and genres you enjoy.\n\nContent you create — Posts, reels, comments, reactions, and any media you upload (photos, videos, audio recordings).\n\nMessages — Direct messages and group chat content are stored on our servers to deliver them to recipients and support message history.\n\nContacts (optional) — If you grant permission, we access your device contacts solely to help you find friends already on Riff. Contact data is never stored on our servers without your explicit action.\n\nDevice & usage data — Device model, OS version, app version, IP address, and in-app activity (screens visited, features used) for diagnostics and improvement.`
  String get ppSection2Body {
    return Intl.message(
      'Account information — When you sign up, we collect your full name, username, email address, and password (stored as a one-way hash).\n\nProfile information — Profile picture, bio, and music preferences including instruments you play and genres you enjoy.\n\nContent you create — Posts, reels, comments, reactions, and any media you upload (photos, videos, audio recordings).\n\nMessages — Direct messages and group chat content are stored on our servers to deliver them to recipients and support message history.\n\nContacts (optional) — If you grant permission, we access your device contacts solely to help you find friends already on Riff. Contact data is never stored on our servers without your explicit action.\n\nDevice & usage data — Device model, OS version, app version, IP address, and in-app activity (screens visited, features used) for diagnostics and improvement.',
      name: 'ppSection2Body',
      desc: '',
      args: [],
    );
  }

  /// `3. How We Use Your Information`
  String get ppSection3Title {
    return Intl.message(
      '3. How We Use Your Information',
      name: 'ppSection3Title',
      desc: '',
      args: [],
    );
  }

  /// `• Provide and operate the Riff service, including account management, messaging, and social features.\n• Personalise your feed and music recommendations based on your stated preferences.\n• Send push notifications about new messages, interactions, and platform updates (you can manage these in Settings → Notifications).\n• Detect and prevent fraud, abuse, and policy violations.\n• Analyse usage patterns to improve app performance and develop new features.\n• Respond to your support requests and bug reports.`
  String get ppSection3Body {
    return Intl.message(
      '• Provide and operate the Riff service, including account management, messaging, and social features.\n• Personalise your feed and music recommendations based on your stated preferences.\n• Send push notifications about new messages, interactions, and platform updates (you can manage these in Settings → Notifications).\n• Detect and prevent fraud, abuse, and policy violations.\n• Analyse usage patterns to improve app performance and develop new features.\n• Respond to your support requests and bug reports.',
      name: 'ppSection3Body',
      desc: '',
      args: [],
    );
  }

  /// `4. How We Share Your Information`
  String get ppSection4Title {
    return Intl.message(
      '4. How We Share Your Information',
      name: 'ppSection4Title',
      desc: '',
      args: [],
    );
  }

  /// `We do not sell your personal data to third parties.\n\nService providers — We share data with trusted third-party providers that help us operate Riff, including:\n• Firebase Cloud Messaging (FCM) — to deliver push notifications.\n• Cloud hosting providers — to store and serve app data securely.\n\nLegal requirements — We may disclose information if required by law, subpoena, or to protect the rights and safety of our users or the public.\n\nBusiness transfers — In the event of a merger, acquisition, or asset sale, user data may be transferred as part of that transaction.`
  String get ppSection4Body {
    return Intl.message(
      'We do not sell your personal data to third parties.\n\nService providers — We share data with trusted third-party providers that help us operate Riff, including:\n• Firebase Cloud Messaging (FCM) — to deliver push notifications.\n• Cloud hosting providers — to store and serve app data securely.\n\nLegal requirements — We may disclose information if required by law, subpoena, or to protect the rights and safety of our users or the public.\n\nBusiness transfers — In the event of a merger, acquisition, or asset sale, user data may be transferred as part of that transaction.',
      name: 'ppSection4Body',
      desc: '',
      args: [],
    );
  }

  /// `5. Data Security`
  String get ppSection5Title {
    return Intl.message(
      '5. Data Security',
      name: 'ppSection5Title',
      desc: '',
      args: [],
    );
  }

  /// `We use industry-standard security measures including encrypted connections (HTTPS/TLS), hashed passwords, JWT-based authentication with refresh tokens, and access controls to protect your data.\n\nNo method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.`
  String get ppSection5Body {
    return Intl.message(
      'We use industry-standard security measures including encrypted connections (HTTPS/TLS), hashed passwords, JWT-based authentication with refresh tokens, and access controls to protect your data.\n\nNo method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
      name: 'ppSection5Body',
      desc: '',
      args: [],
    );
  }

  /// `6. Messaging & Real-Time Features`
  String get ppSection6Title {
    return Intl.message(
      '6. Messaging & Real-Time Features',
      name: 'ppSection6Title',
      desc: '',
      args: [],
    );
  }

  /// `Messages sent through Riff are stored on our servers to ensure reliable delivery and support chat history. We do not read the content of your messages except where required by law or to investigate abuse reports you submit.\n\nOnline presence (e.g. "Online" / "Last seen") is shared with users you have a conversation with. You may restrict this in Settings.`
  String get ppSection6Body {
    return Intl.message(
      'Messages sent through Riff are stored on our servers to ensure reliable delivery and support chat history. We do not read the content of your messages except where required by law or to investigate abuse reports you submit.\n\nOnline presence (e.g. "Online" / "Last seen") is shared with users you have a conversation with. You may restrict this in Settings.',
      name: 'ppSection6Body',
      desc: '',
      args: [],
    );
  }

  /// `7. Children's Privacy`
  String get ppSection7Title {
    return Intl.message(
      '7. Children\'s Privacy',
      name: 'ppSection7Title',
      desc: '',
      args: [],
    );
  }

  /// `Riff is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will delete it immediately.`
  String get ppSection7Body {
    return Intl.message(
      'Riff is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will delete it immediately.',
      name: 'ppSection7Body',
      desc: '',
      args: [],
    );
  }

  /// `8. Your Rights & Choices`
  String get ppSection8Title {
    return Intl.message(
      '8. Your Rights & Choices',
      name: 'ppSection8Title',
      desc: '',
      args: [],
    );
  }

  /// `Access & correction — You can view and update your profile information at any time through Settings.\n\nAccount deletion — You can delete your account from Settings → Account. This permanently removes your profile, posts, and personal data within 30 days.\n\nNotifications — Manage push notification preferences in Settings → Notifications or through your device's system settings.\n\nContacts access — You can revoke contacts permission at any time in your device's app permissions settings.`
  String get ppSection8Body {
    return Intl.message(
      'Access & correction — You can view and update your profile information at any time through Settings.\n\nAccount deletion — You can delete your account from Settings → Account. This permanently removes your profile, posts, and personal data within 30 days.\n\nNotifications — Manage push notification preferences in Settings → Notifications or through your device\'s system settings.\n\nContacts access — You can revoke contacts permission at any time in your device\'s app permissions settings.',
      name: 'ppSection8Body',
      desc: '',
      args: [],
    );
  }

  /// `9. Cookies & Local Storage`
  String get ppSection9Title {
    return Intl.message(
      '9. Cookies & Local Storage',
      name: 'ppSection9Title',
      desc: '',
      args: [],
    );
  }

  /// `Riff uses local device storage (SharedPreferences) to securely store your authentication tokens and user preferences such as theme settings. This data is stored only on your device and is cleared when you log out.`
  String get ppSection9Body {
    return Intl.message(
      'Riff uses local device storage (SharedPreferences) to securely store your authentication tokens and user preferences such as theme settings. This data is stored only on your device and is cleared when you log out.',
      name: 'ppSection9Body',
      desc: '',
      args: [],
    );
  }

  /// `10. Changes to This Policy`
  String get ppSection10Title {
    return Intl.message(
      '10. Changes to This Policy',
      name: 'ppSection10Title',
      desc: '',
      args: [],
    );
  }

  /// `We may update this Privacy Policy from time to time. When we make significant changes, we will notify you via in-app notification or email. Continued use of Riff after changes are posted constitutes your acceptance of the updated policy.\n\nLast updated: June 2026.`
  String get ppSection10Body {
    return Intl.message(
      'We may update this Privacy Policy from time to time. When we make significant changes, we will notify you via in-app notification or email. Continued use of Riff after changes are posted constitutes your acceptance of the updated policy.\n\nLast updated: June 2026.',
      name: 'ppSection10Body',
      desc: '',
      args: [],
    );
  }

  /// `11. Contact Us`
  String get ppSection11Title {
    return Intl.message(
      '11. Contact Us',
      name: 'ppSection11Title',
      desc: '',
      args: [],
    );
  }

  /// `If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us at:\n\nEmail: magddevf@gmail.com\n`
  String get ppSection11Body {
    return Intl.message(
      'If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us at:\n\nEmail: magddevf@gmail.com\n',
      name: 'ppSection11Body',
      desc: '',
      args: [],
    );
  }

  /// `Profile Settings`
  String get profileSettingsDrawer {
    return Intl.message(
      'Profile Settings',
      name: 'profileSettingsDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Edit your profile info`
  String get editYourProfile {
    return Intl.message(
      'Edit your profile info',
      name: 'editYourProfile',
      desc: '',
      args: [],
    );
  }

  /// `Profile Settings`
  String get profileSettingsTitle {
    return Intl.message(
      'Profile Settings',
      name: 'profileSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Update your name, username, email, and music genres.`
  String get profileSettingsSubtitle {
    return Intl.message(
      'Update your name, username, email, and music genres.',
      name: 'profileSettingsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get usernameLabel {
    return Intl.message(
      'Username',
      name: 'usernameLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. john_doe`
  String get usernameHint {
    return Intl.message(
      'e.g. john_doe',
      name: 'usernameHint',
      desc: '',
      args: [],
    );
  }

  /// `Checking…`
  String get usernameChecking {
    return Intl.message(
      'Checking…',
      name: 'usernameChecking',
      desc: '',
      args: [],
    );
  }

  /// `Username is available`
  String get usernameAvailable {
    return Intl.message(
      'Username is available',
      name: 'usernameAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Username is already taken`
  String get usernameTaken {
    return Intl.message(
      'Username is already taken',
      name: 'usernameTaken',
      desc: '',
      args: [],
    );
  }

  /// `This is your current username`
  String get usernameUnchanged {
    return Intl.message(
      'This is your current username',
      name: 'usernameUnchanged',
      desc: '',
      args: [],
    );
  }

  /// `Email Address`
  String get emailSettingsLabel {
    return Intl.message(
      'Email Address',
      name: 'emailSettingsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get emailSettingsHint {
    return Intl.message(
      'Enter your email',
      name: 'emailSettingsHint',
      desc: '',
      args: [],
    );
  }

  /// `Music Genres`
  String get genresSettingsLabel {
    return Intl.message(
      'Music Genres',
      name: 'genresSettingsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Tap to select the genres you love`
  String get genresSettingsSubtitle {
    return Intl.message(
      'Tap to select the genres you love',
      name: 'genresSettingsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Save Changes`
  String get saveProfileBtn {
    return Intl.message(
      'Save Changes',
      name: 'saveProfileBtn',
      desc: '',
      args: [],
    );
  }

  /// `Profile updated successfully!`
  String get profileSavedSuccess {
    return Intl.message(
      'Profile updated successfully!',
      name: 'profileSavedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save profile. Please try again.`
  String get profileSavedFailure {
    return Intl.message(
      'Failed to save profile. Please try again.',
      name: 'profileSavedFailure',
      desc: '',
      args: [],
    );
  }

  /// `Username is required`
  String get usernameRequired {
    return Intl.message(
      'Username is required',
      name: 'usernameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Email is required`
  String get emailRequired {
    return Intl.message(
      'Email is required',
      name: 'emailRequired',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid email address`
  String get emailInvalid {
    return Intl.message(
      'Enter a valid email address',
      name: 'emailInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Email cannot be changed for Google accounts`
  String get googleAccountEmailNote {
    return Intl.message(
      'Email cannot be changed for Google accounts',
      name: 'googleAccountEmailNote',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one genre`
  String get noGenresSelected {
    return Intl.message(
      'Select at least one genre',
      name: 'noGenresSelected',
      desc: '',
      args: [],
    );
  }

  /// `Select Genres`
  String get selectGenresTitle {
    return Intl.message(
      'Select Genres',
      name: 'selectGenresTitle',
      desc: '',
      args: [],
    );
  }

  /// `About Riff`
  String get aboutUsDrawer {
    return Intl.message(
      'About Riff',
      name: 'aboutUsDrawer',
      desc: '',
      args: [],
    );
  }

  /// `Our story and the team`
  String get aboutUsDrawerSubtitle {
    return Intl.message(
      'Our story and the team',
      name: 'aboutUsDrawerSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `About Riff`
  String get aboutUsTitle {
    return Intl.message(
      'About Riff',
      name: 'aboutUsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your Music. Your People.`
  String get aboutUsTagline {
    return Intl.message(
      'Your Music. Your People.',
      name: 'aboutUsTagline',
      desc: '',
      args: [],
    );
  }

  /// `Riff is a music-first social platform built for musicians, producers, and passionate listeners. Share what you're playing, discover who's listening to the same tracks, connect with fellow artists, and grow your musical community — all in one place.`
  String get aboutUsDescription {
    return Intl.message(
      'Riff is a music-first social platform built for musicians, producers, and passionate listeners. Share what you\'re playing, discover who\'s listening to the same tracks, connect with fellow artists, and grow your musical community — all in one place.',
      name: 'aboutUsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Our Mission`
  String get aboutUsMission {
    return Intl.message(
      'Our Mission',
      name: 'aboutUsMission',
      desc: '',
      args: [],
    );
  }

  /// `Music is universal, but finding your people isn't always easy. Riff exists to close that gap — giving every musician and music lover a space to express themselves, share their sound, and connect authentically.`
  String get aboutUsMissionBody {
    return Intl.message(
      'Music is universal, but finding your people isn\'t always easy. Riff exists to close that gap — giving every musician and music lover a space to express themselves, share their sound, and connect authentically.',
      name: 'aboutUsMissionBody',
      desc: '',
      args: [],
    );
  }

  /// `Meet the Developer`
  String get aboutUsDeveloperTitle {
    return Intl.message(
      'Meet the Developer',
      name: 'aboutUsDeveloperTitle',
      desc: '',
      args: [],
    );
  }

  /// `Magd`
  String get aboutUsDeveloperName {
    return Intl.message(
      'Magd',
      name: 'aboutUsDeveloperName',
      desc: '',
      args: [],
    );
  }

  /// `Founder & Full-Stack Developer`
  String get aboutUsDeveloperRole {
    return Intl.message(
      'Founder & Full-Stack Developer',
      name: 'aboutUsDeveloperRole',
      desc: '',
      args: [],
    );
  }

  /// `Magd is a passionate Flutter developer who built Riff from the ground up — from backend architecture to pixel-perfect UI. A music lover himself, he created Riff to solve a real problem: there's no great social space designed purely for the music community.`
  String get aboutUsDeveloperBio {
    return Intl.message(
      'Magd is a passionate Flutter developer who built Riff from the ground up — from backend architecture to pixel-perfect UI. A music lover himself, he created Riff to solve a real problem: there\'s no great social space designed purely for the music community.',
      name: 'aboutUsDeveloperBio',
      desc: '',
      args: [],
    );
  }

  /// `Get in touch`
  String get aboutUsContactLabel {
    return Intl.message(
      'Get in touch',
      name: 'aboutUsContactLabel',
      desc: '',
      args: [],
    );
  }

  /// `magddevf@gmail.com`
  String get aboutUsContactEmail {
    return Intl.message(
      'magddevf@gmail.com',
      name: 'aboutUsContactEmail',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get aboutUsVersion {
    return Intl.message(
      'Version',
      name: 'aboutUsVersion',
      desc: '',
      args: [],
    );
  }

  /// `Made with ❤️ for the music community`
  String get aboutUsMadeWith {
    return Intl.message(
      'Made with ❤️ for the music community',
      name: 'aboutUsMadeWith',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
