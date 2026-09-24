// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family OS';

  @override
  String get galleryTitle => 'Component gallery';

  @override
  String get galleryHint =>
      'Design tokens and core components — parent / child UI modes';

  @override
  String get galleryColors => 'Colors';

  @override
  String get galleryShadows => 'Shadows';

  @override
  String get galleryGradients => 'Gradients';

  @override
  String get galleryRadii => 'Radii';

  @override
  String get galleryTypography => 'Typography';

  @override
  String get galleryUiMode => 'UI mode';

  @override
  String get galleryModeParent => 'Parent';

  @override
  String get galleryModeChild => 'Child';

  @override
  String get galleryButtons => 'Buttons';

  @override
  String get galleryCards => 'Cards';

  @override
  String get galleryRows => 'Rows';

  @override
  String get galleryTags => 'Tags';

  @override
  String get galleryBanners => 'Banners';

  @override
  String get galleryProgress => 'Progress';

  @override
  String get gallerySheet => 'Bottom sheet';

  @override
  String get galleryToast => 'Toast';

  @override
  String get settingsPersistError => 'Could not save — try again';

  @override
  String get galleryTabs => 'Tabs';

  @override
  String get galleryHub => 'Hub grid';

  @override
  String get galleryBtnPrimary => 'Primary action';

  @override
  String get galleryBtnTeal => 'Teal action';

  @override
  String get galleryBtnSec => 'Secondary';

  @override
  String get galleryBtnGhost => 'Ghost';

  @override
  String get galleryBtnCoral => 'Danger';

  @override
  String get galleryBtnDisabled => 'Disabled';

  @override
  String get galleryCardTitle => 'Sample card';

  @override
  String get galleryCardBody =>
      'Card body matches prototype surface, shadow, and radius.';

  @override
  String get galleryCardLink => 'View all';

  @override
  String get galleryRowTitle1 => 'Morning check-in';

  @override
  String get galleryRowSub1 => 'Completed at 7:30';

  @override
  String get galleryRowTitle2 => 'Family chat';

  @override
  String get galleryRowSub2 => '2 new messages';

  @override
  String get galleryRowTitle3 => 'Study time';

  @override
  String get galleryRowSub3 => '45 minutes left';

  @override
  String get galleryTagG => 'Done';

  @override
  String get galleryTagT => 'Teal';

  @override
  String get galleryTagP => 'Brand';

  @override
  String get galleryTagA => 'Attention';

  @override
  String get galleryBannerT => 'Teal note — calm guidance for the family.';

  @override
  String get galleryBannerP => 'Brand note — purple tinted information.';

  @override
  String get galleryBannerA => 'Warm attention — never use coral for warnings.';

  @override
  String get galleryOpenSheet => 'Open sheet';

  @override
  String get gallerySheetTitle => 'Sample sheet';

  @override
  String get gallerySheetClose => 'Close';

  @override
  String get galleryShowToast => 'Show toast';

  @override
  String get galleryToastMessage => 'Action completed successfully';

  @override
  String get galleryToastAction => 'Undo';

  @override
  String get galleryToastUndone => 'Undone';

  @override
  String get tabParentToday => 'Today';

  @override
  String get tabParentKids => 'Kids';

  @override
  String get tabParentFamily => 'Family';

  @override
  String get tabParentStudio => 'Learn';

  @override
  String get tabParentSettings => 'Settings';

  @override
  String get tabChildMyDay => 'My day';

  @override
  String get tabChildLearn => 'Learn';

  @override
  String get tabChildFamily => 'Family';

  @override
  String get tabChildMe => 'Me';

  @override
  String get shellMoreToolsHeading => 'More tools';

  @override
  String get shellKidsPerChildNote =>
      'Screen time, apps, filters, and supervision are set per child from their profile — open a child from the list above.';

  @override
  String get shellSettingsOtherHeading => 'Other';

  @override
  String get shellShortcutDeviceSwitch => 'Switch user';

  @override
  String get shellShortcutAcceptInvite => 'Join with invite';

  @override
  String get shellShortcutSosAlert => 'SOS alert board';

  @override
  String get shellAiFabSemantics => 'Open Family Advisor';

  @override
  String get shellSosFabSemantics => 'Open SOS';

  @override
  String get galleryHubItem1 => 'Tasks';

  @override
  String get galleryHubItem2 => 'Wallet';

  @override
  String get galleryHubItem3 => 'Modes';

  @override
  String get galleryHubItem4 => 'Reports';

  @override
  String get galleryHubItem5 => 'Devices';

  @override
  String get galleryHubItem6 => 'Advisor';

  @override
  String get welcomeSlide0Emoji => '🦁';

  @override
  String get welcomeSlide0Title => 'My Family';

  @override
  String get welcomeSlide0Body =>
      'One app that brings your family together: parent peace of mind · warm connection · joyful learning';

  @override
  String get welcomeSlide1Emoji => '🗺️';

  @override
  String get welcomeSlide1Title => 'Peace of mind at a glance';

  @override
  String get welcomeSlide1Body =>
      'Where are your kids now? Did they arrive safely? All the reassurance in eight morning seconds';

  @override
  String get welcomeSlide2Emoji => '📚';

  @override
  String get welcomeSlide2Title => 'They learn and love it';

  @override
  String get welcomeSlide2Body =>
      'Learning time is not counted against play time — so the device turns from rival into teacher';

  @override
  String get welcomeDotsHint => 'Tap the dots for the next slide';

  @override
  String get welcomeDotsDone => '👍';

  @override
  String get welcomeStartCta => 'Get started';

  @override
  String get welcomeLoginCta => 'I have an account — Sign in';

  @override
  String get welcomeLegal =>
      'By continuing you agree to the Terms and Privacy Policy';

  @override
  String get welcomeDotsSemantics => 'Slide dots — tap for next';

  @override
  String welcomeSlideSemantics(int index, int total) {
    return 'Slide $index of $total';
  }

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get createAccountStep => 'Step 1 of 2';

  @override
  String get createAccountEmailLabel => 'Email';

  @override
  String get createAccountEmailHint => 'abdullah@example.com';

  @override
  String get createAccountPasswordLabel => 'Password';

  @override
  String get createAccountPasswordHint => 'At least 8 characters';

  @override
  String get createAccountConfirmLabel => 'Confirm password';

  @override
  String get createAccountConfirmHint => 'Type it again';

  @override
  String get createAccountStrengthWeak => 'Too short — add more';

  @override
  String get createAccountStrengthGood => 'Good';

  @override
  String get createAccountStrengthStrong => 'Strong 💪';

  @override
  String get createAccountTerms =>
      'I agree to the Terms and Privacy Policy — no ads and no data selling, ever.';

  @override
  String get createAccountSubmit => 'Create account';

  @override
  String get createAccountNoPhoneNote =>
      'We never ask for a phone number — email is enough (ADR-003)';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Welcome back';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'abdullah@example.com';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => '••••••••';

  @override
  String get loginForgotLink => 'Forgot password?';

  @override
  String get loginForgotToast =>
      'Opening local account recovery. No reset email is sent in this prototype.';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginBiometric => '🔒 Sign in with fingerprint';

  @override
  String get loginBiometricToast => 'Signed in with fingerprint';

  @override
  String get loginInvitePrompt => 'Got a family invite?';

  @override
  String get loginInviteLink => 'Join via invite link ‹';

  @override
  String get deviceModeTitle => 'Who will use this device?';

  @override
  String get deviceModeSubtitle => 'Neutral screen';

  @override
  String get deviceModeIntro =>
      'Choose carefully — this sets the app mode on this device.';

  @override
  String get deviceModeGuardianEmoji => '👑';

  @override
  String get deviceModeGuardianTitle => 'Me — guardian';

  @override
  String get deviceModeGuardianBody =>
      'I watch my children from here and manage the family';

  @override
  String get deviceModeGuardianSemantics =>
      'Me — guardian. I watch my children from here and manage the family';

  @override
  String get deviceModeChildEmoji => '🧒';

  @override
  String get deviceModeChildTitle => 'My child';

  @override
  String get deviceModeChildBody =>
      'This is their device, and it will link to their guardian’s account';

  @override
  String get deviceModeChildSemantics =>
      'My child. This is their device, and it will link to their guardian’s account';

  @override
  String get deviceModeBannerLeading => 'ℹ️';

  @override
  String get deviceModeNoMotherBanner =>
      'There is no “mother” option here — mother joins via an invite from the father’s board at a permission level he sets. Anyone who taps “guardian” without an invite creates a new family.';

  @override
  String get createFamilyTitle => 'Create family';

  @override
  String get createFamilySubtitle => 'You are the owner';

  @override
  String get createFamilyNameLabel => 'Family name';

  @override
  String get createFamilyNameHint => 'e.g. The Ahmed family';

  @override
  String get createFamilyChildCountLabel =>
      'How many children will you follow?';

  @override
  String get createFamilyChildCountOne => 'One child';

  @override
  String get createFamilyChildCountTwo => 'Two children';

  @override
  String get createFamilyChildCountThree => '3 children';

  @override
  String get createFamilyChildCountFourPlus => '4 or more';

  @override
  String get createFamilyBannerLeading => '🎁';

  @override
  String get createFamilyTrialBanner =>
      'Your full free trial starts now — SOS and safety are never blocked on any plan.';

  @override
  String get createFamilySubmit => 'Create family';

  @override
  String get errorNetworkTitle => 'Couldn\'t connect';

  @override
  String get errorNetworkMessage =>
      'We couldn\'t reach the server. Your saved data is still here — retry when you\'re back online.';

  @override
  String get errorTimeoutTitle => 'Connection timed out';

  @override
  String get errorTimeoutMessage =>
      'The server took longer than expected. Try creating the family again.';

  @override
  String get errorValidationTitle => 'Couldn\'t create family';

  @override
  String get errorValidationMessage =>
      'Check the family name and try again. If it keeps failing, try a different name.';

  @override
  String get errorOfflineTitle => 'Network required';

  @override
  String get errorOfflineMessage =>
      'Creating a family needs an active connection — the request cannot be saved offline.';

  @override
  String get errorRetryCta => 'Retry';

  @override
  String get setupWizardTitle => 'Set up your family';

  @override
  String get setupWizardSubtitle => '4 minutes';

  @override
  String setupWizardProgressHero(int percent) {
    return '$percent%';
  }

  @override
  String get setupWizardProgressCaption => 'of suggested setup';

  @override
  String setupWizardProgressSemantics(int percent) {
    return 'Suggested setup progress $percent percent';
  }

  @override
  String get setupWizardStepAccountTitle => 'Create account and family';

  @override
  String get setupWizardStepAccountSubtitle => 'Done';

  @override
  String get setupWizardStepSuggestedPending => 'Suggested when you are ready';

  @override
  String get setupWizardStepAddChildTitle =>
      'Add first child and link their device';

  @override
  String get setupWizardStepAddChildSubtitle => 'Suggested · ~2 minutes';

  @override
  String get setupWizardStepAddChildTag => 'Most important now';

  @override
  String get setupWizardStepInviteTitle => 'Invite mother';

  @override
  String get setupWizardStepInviteSubtitle =>
      'Suggested so she can feel at ease — optional';

  @override
  String get setupWizardStepSosTitle => 'Set up emergency contacts';

  @override
  String get setupWizardStepSosSubtitle => 'Suggested · 1 minute';

  @override
  String get setupWizardSkipLater => 'Continue later — to today’s board';

  @override
  String get addChildTitle => 'Add a child';

  @override
  String get addChildStep => '1 of 3';

  @override
  String get addChildNameLabel => 'Name';

  @override
  String get addChildNameHint => 'First name';

  @override
  String get addChildAgeLabel => 'Age';

  @override
  String addChildAgeYears(String years) {
    return '$years years';
  }

  @override
  String get addChildCharacterLabel => 'Favorite character';

  @override
  String get addChildColorLabel => 'Color in the app';

  @override
  String addChildColorSwatchSemantics(int index) {
    return 'Family member color $index';
  }

  @override
  String get addChildContinue => 'Continue — link code';

  @override
  String get addChildAliasPrefix => 'Analytics identity: ';

  @override
  String get addChildAliasSuffix => ' — their name never leaves the family';

  @override
  String addChildAliasSemantics(String alias) {
    return 'Analytics identity $alias — their name never leaves the family';
  }

  @override
  String get linkQrTitle => 'Link their device';

  @override
  String get linkQrStep => '2 of 3';

  @override
  String get linkQrInstructionPrefix => 'On their device: ';

  @override
  String get linkQrInstructionBold =>
      'Install the same «عائلتي» app, choose «ابني», and scan this code.';

  @override
  String get linkQrSemantics => 'Pairing QR code';

  @override
  String get linkQrTimerLead => '⏱ Code valid ';

  @override
  String get linkQrTimerTrail => ' · single use only';

  @override
  String get linkQrExpired => '⛔ Code expired — renew it';

  @override
  String get linkQrContinue => 'Scanned on their device ← Continue';

  @override
  String get linkQrRenew => 'Renew code';

  @override
  String get linkQrRenewToast =>
      '✓ New code generated — previous voided and timer restarted';

  @override
  String get linkQrTrial => 'Their device isn’t with me — try the app first';

  @override
  String get permissionsExplainerTitle => 'Why these permissions?';

  @override
  String get permissionsExplainerStep => '3 of 3';

  @override
  String get permissionsExplainerVideoTitle =>
      'Video: What will their device ask for? (90 seconds)';

  @override
  String get permissionsExplainerVideoSemantics =>
      'Play permissions explainer video';

  @override
  String get permissionsExplainerVideoToast =>
      'Video coming soon — mock preview';

  @override
  String get permissionsExplainerLocationTitle => 'Location «Always»';

  @override
  String get permissionsExplainerLocationWhy =>
      'So you get their place and safe-zone alerts — we ask after first value, not immediately';

  @override
  String get permissionsExplainerA11yTitle => 'Accessibility service';

  @override
  String get permissionsExplainerA11yWhy =>
      'For instant blocking only — time tracking doesn’t need it at all';

  @override
  String get permissionsExplainerBatteryTitle => 'Battery exemption';

  @override
  String get permissionsExplainerBatteryWhy =>
      'So battery saver doesn’t kill our link to their device';

  @override
  String get permissionsExplainerBanner =>
      '✋ If any permission is refused, no screen locks — a fallback runs and we show a recovery card. (Rule 3)';

  @override
  String get permissionsExplainerContinue => 'Got it — finish linking';

  @override
  String get linkSuccessTitle => 'Linked!';

  @override
  String get linkSuccessStep => '1 of 3 children';

  @override
  String get linkSuccessHeroTitle => 'Your child\'s device is connected now';

  @override
  String linkSuccessHeroTitleNamed(String name) {
    return '$name\'s device is connected now';
  }

  @override
  String get linkSuccessFirstFruit =>
      'And this is the first payoff — their location now:';

  @override
  String get linkSuccessMapSemantics => 'Current location preview';

  @override
  String get linkSuccessLocationTitle =>
      '📍 Al-Noor Secondary — Al-Narjis district';

  @override
  String get linkSuccessLocationMeta => 'Last update: now · Battery 84%';

  @override
  String get linkSuccessTemplateTitle => '⚡ Shortcut — age template ready';

  @override
  String get linkSuccessTemplateBody =>
      'Template «14–17» sets: 4 hours, balanced filtering, bedtime 10:30. Refine anytime.';

  @override
  String get linkSuccessApplyTemplate => 'Apply template (recommended)';

  @override
  String get linkSuccessManual => 'I\'ll set everything manually';

  @override
  String get linkSuccessApplyToast => '✓ Applied the 14–17 template';

  @override
  String get linkSuccessManualToast =>
      'OK — you\'ll tune each tool from their profile';

  @override
  String get linkSuccessTemplateApplied =>
      '✓ Template «14–17» applied: 4 hours · balanced filter · bedtime 10:30';

  @override
  String get linkSuccessTemplateUndo => 'Undo';

  @override
  String get linkSuccessNextChildTitle => '👦 Two of your children remain';

  @override
  String get linkSuccessNextChildBody =>
      'You said you\'d follow 3 children — add the next with their device ready, or defer without worry.';

  @override
  String get linkSuccessAddNext => '+ Add the next child (2 of 3)';

  @override
  String get linkSuccessAddNextToast => 'Starting your next child 👦';

  @override
  String get linkSuccessDayBoard => 'To today\'s board — finish the rest later';

  @override
  String get trialModeTitle => 'Trial mode';

  @override
  String get trialModeSubtitle => 'Demo data';

  @override
  String get trialModeBanner =>
      '🧪 This is demo data for a virtual child named «Demo» — everything works, nothing is real. Link a real device whenever you want.';

  @override
  String get trialModeAvatarLetter => 'D';

  @override
  String get trialModeChildTitle => 'Demo — 12 years';

  @override
  String get trialModeChildMeta => '📍 Virtual school · 🔋 77%';

  @override
  String get trialModeRemaining => '⏱ Remaining: 2 h 15 m';

  @override
  String get trialModeMinutes => '⏱ 180 minutes';

  @override
  String get trialModeTryTitle => 'What can you try?';

  @override
  String get trialModeMapRow => 'Map and safe zones';

  @override
  String get trialModeAdvisorRow => 'Family advisor suggestions';

  @override
  String get trialModeLinkCta => 'Link a real device now';

  @override
  String get inviteMotherTitle => '🤍 Invite mom';

  @override
  String get inviteMotherIntro =>
      'She stays close with you on the kids — you set her level and can change it anytime.';

  @override
  String get inviteMotherEmailLabel => 'Her email';

  @override
  String get inviteMotherEmailHint => 'email@example.com';

  @override
  String get inviteMotherLevelObserverTitle => 'Observer';

  @override
  String get inviteMotherLevelObserverDesc =>
      'Sees everything, stays reassured, and notifies you';

  @override
  String get inviteMotherLevelPartnerTitle => 'Partner';

  @override
  String get inviteMotherLevelPartnerDesc =>
      'Also approves kids\' requests and can grant extra time';

  @override
  String get inviteMotherLevelFullTitle => 'Full';

  @override
  String get inviteMotherLevelFullDesc =>
      'Also edits rules and limits with you';

  @override
  String get inviteMotherRecommendedTag => 'Recommended';

  @override
  String get inviteMotherBannerLeading => '🔴';

  @override
  String get inviteMotherBanner =>
      'At any level: she receives SOS, can call the kids, and sees their locations — rights that never tier.';

  @override
  String get inviteMotherSubmit => 'Send invite';

  @override
  String inviteMotherToast(String localPart, String level) {
    return 'Invite sent to $localPart at «$level» level ✓';
  }

  @override
  String get acceptMotherInviteTitle => 'Join invite';

  @override
  String get acceptMotherInviteSubtitle => 'What mom sees';

  @override
  String get acceptMotherInviteHeart => '🤍';

  @override
  String get acceptMotherInviteHeartSemantics => 'Family join invite';

  @override
  String acceptMotherInviteHeadline(String inviter, String family) {
    return '$inviter invites you to join «$family»';
  }

  @override
  String get acceptMotherInviteInviterFallback => 'the guardian';

  @override
  String get acceptMotherInviteFamilyFallback => 'the family';

  @override
  String get acceptMotherInviteLevelEmoji => '🎚️';

  @override
  String acceptMotherInviteLevelTitle(String level) {
    return 'Your level: $level';
  }

  @override
  String get acceptMotherInviteLevelObserverMeaning =>
      'See everything · stay reassured · get notified';

  @override
  String get acceptMotherInviteLevelPartnerMeaning =>
      'See everything · approve requests · grant extra time';

  @override
  String get acceptMotherInviteLevelFullMeaning =>
      'See everything · approve · edit rules with dad';

  @override
  String get acceptMotherInviteRightsEmoji => '🔴';

  @override
  String get acceptMotherInviteRightsTitle => 'Your fixed rights';

  @override
  String get acceptMotherInviteRightsSubtitle =>
      'SOS reaches you · you can call the kids · you see their locations — always';

  @override
  String get acceptMotherInviteAccept => 'Accept and join';

  @override
  String get acceptMotherInviteDecline => 'Not now';

  @override
  String acceptMotherInviteWelcomeToast(String invitee, String level) {
    return '🌸 Welcome, $invitee — you\'re now a guidance partner at «$level»';
  }

  @override
  String acceptMotherInviteWelcomeToastGeneric(String level) {
    return '🌸 Welcome — you\'re now a guidance partner at «$level»';
  }

  @override
  String acceptMotherInviteDeclineToast(String inviter) {
    return 'No worries — the invite stays valid for a week, and $inviter can remind you';
  }

  @override
  String get galleryBannerG => 'Mint note — free trial and safety never gated.';

  @override
  String get dayBoardTitle => 'Today\'s board';

  @override
  String get dayBoardShellNote => 'Bare shell — no bottom tabs (Stage 1)';

  @override
  String dayBoardSyncLine(String time) {
    return '☁️ Last sync: $time — works offline, updates when connected';
  }

  @override
  String get dayBoardSyncMockTime => 'a minute ago';

  @override
  String dayBoardGreeting(String name) {
    return 'Good morning $name 👋';
  }

  @override
  String get dayBoardGuardianFallback => 'Guardian';

  @override
  String get dayBoardGreetingSub => 'Your children are safe and well today';

  @override
  String get dayBoardPulseLabel => 'Family pulse';

  @override
  String dayBoardChildTitle(String name, int age) {
    return '$name ($age yrs)';
  }

  @override
  String dayBoardLocationBattery(String location, String battery) {
    return '📍 $location · 🔋 $battery online';
  }

  @override
  String get dayBoardActiveTag => 'Active now';

  @override
  String dayBoardStatTimeLeft(String value) {
    return '⏱️ Left: $value';
  }

  @override
  String dayBoardStatQuran(String value) {
    return '📖 Quran: $value';
  }

  @override
  String dayBoardStatWallet(String value) {
    return '⏱ Wallet: $value';
  }

  @override
  String get dayBoardQuickTitle => 'Quick follow-up';

  @override
  String get dayBoardAllChildren => 'All children ←';

  @override
  String get dayBoardQuickQuran => 'Quran';

  @override
  String get dayBoardQuickTasks => 'Tasks';

  @override
  String get dayBoardQuickLock => 'Lock';

  @override
  String get dayBoardQuickMap => 'Map';

  @override
  String get dayBoardPrioritySection => 'Most important now';

  @override
  String get dayBoardPriorityTitle => 'Pending request';

  @override
  String get dayBoardPrioritySubtitle => 'Open the inbox to decide';

  @override
  String get dayBoardPriorityTag => 'Your decision ←';

  @override
  String get dayBoardAdvisorBanner =>
      'Family advisor suggests — you decide. Nothing applies on its own.';

  @override
  String get dayBoardAdvisorCta => 'View suggestions';

  @override
  String get childScreenTimeTitle => 'Screen time';

  @override
  String get childScreenTimeSubtitle =>
      'Time-range windows for sleep, prayer, and study — not decorative toggles';

  @override
  String get childScreenTimeSleep => 'Sleep';

  @override
  String get childScreenTimePrayer => 'Prayer';

  @override
  String get childScreenTimeStudy => 'Study';

  @override
  String get childScreenTimeStart => 'Start';

  @override
  String get childScreenTimeEnd => 'End';

  @override
  String get childScreenTimeSave => 'Save schedules';

  @override
  String get childScreenTimeValidation =>
      'End must be after start on the same day';

  @override
  String get childScreenTimeReadOnly => 'View only — father can edit';

  @override
  String get childScreenTimeCapsSection => 'Daily caps & wallets';

  @override
  String get childScreenTimeDailyCap => 'Daily cap (minutes)';

  @override
  String get childScreenTimeAllowOverflow => 'Allow wallet past daily cap';

  @override
  String get childScreenTimeAllowOverflowHelp =>
      'Off by default (Ruling B): earned minutes stay inside the daily cap unless you allow overflow';

  @override
  String get childScreenTimeWalletsHeading => 'Per-app wallets';

  @override
  String childScreenTimeWalletMinutes(int minutes) {
    return '$minutes min earned';
  }

  @override
  String get childScreenTimeWalletGames => 'Games';

  @override
  String get childScreenTimeWalletYoutube => 'YouTube';

  @override
  String get childScreenTimeWalletQuran => 'Quran (education)';

  @override
  String get childScreenTimeSaveToast => 'Schedules and caps saved';

  @override
  String get childScreenTimeSyncPending => 'Pending device sync';

  @override
  String get childScreenTimeSyncDelivered => 'Delivered to child';

  @override
  String get childTimeMirrorTitle => 'My screen time';

  @override
  String get childTimeMirrorRemainingLabel => 'Minutes remaining today';

  @override
  String childTimeMirrorRemainingMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String get childTimeMirrorSleepNotice => 'Quiet time is on — rest well';

  @override
  String get childTimeMirrorExemptBanner =>
      'Chat, Quran, and SOS stay available when time runs out';

  @override
  String get childAppsTitle => 'Child apps';

  @override
  String get childAppsTipBanner =>
      'Tap any app to allow, block, or review its limit — changes apply on the child device.';

  @override
  String get childAppsOsInterceptHonesty =>
      'Package access policy is stored locally. Device intercept remains mock-remote — we never claim OS blocking here.';

  @override
  String get childAppsObserverHint =>
      'View only — partner decides install tickets; configure access needs full level or father';

  @override
  String get childAppsPartnerTicketsHint =>
      'You can approve new installs. Permanent allow/block needs father or full level.';

  @override
  String get childAppsProtectedBadge => 'Protected';

  @override
  String get childAppsProtectedCannotBlock =>
      'Protected apps (SOS, Family OS, Chat, Quran) cannot be blocked.';

  @override
  String get childAppsPreviewDenyCta => 'Preview child deny';

  @override
  String get appDenyTitle => 'This app isn\'t available';

  @override
  String get appDenyReasonBlocked => 'Your family blocked this app.';

  @override
  String get appDenyReasonLockNow => 'This app is temporarily locked.';

  @override
  String get appDenyReasonPending =>
      'Waiting for a parent to approve this app.';

  @override
  String get appDenyReasonGeneric => 'This app isn\'t available right now.';

  @override
  String get appDenyDisclosure => 'Family protection is active.';

  @override
  String get appDenyExceptionCta => 'Ask for temporary access';

  @override
  String get appDenyExceptionNotMinutes =>
      'This is not extra Minutes — it does not remove a permanent block.';

  @override
  String get appDenyExceptionPending =>
      'Your request was sent — waiting for a parent.';

  @override
  String get appDenyChatCta => 'Family Chat';

  @override
  String get appDenyQuranCta => 'Quran';

  @override
  String get appDenySosCta => 'SOS';

  @override
  String get newAppApprovalChildScopedHonesty =>
      'Approval applies to this child only — never silent family-wide.';

  @override
  String childAppsPendingCta(int count) {
    return 'Review $count new app request';
  }

  @override
  String get childAppsSharedNote =>
      'App allow/block is shared between father and mother so care stays aligned.';

  @override
  String get childAppsEmptyTitle => 'No apps synced yet';

  @override
  String get childAppsEmptyMessage =>
      'When this child\'s device reports installed apps, they will appear here by category.';

  @override
  String get childAppsChildLeanTitle => 'Parent tools';

  @override
  String get childAppsChildLeanMessage =>
      'App allow and block controls are for parents.';

  @override
  String get childAppsSosCta => 'SOS';

  @override
  String get childAppsCatGames => 'Games & entertainment';

  @override
  String get childAppsCatGamesRule => 'Allowed within daily screen time';

  @override
  String get childAppsCatSocial => 'Social';

  @override
  String get childAppsCatSocialRule => 'Each app needs prior approval';

  @override
  String get childAppsCatEdu => 'Education & Quran';

  @override
  String get childAppsCatEduRule => 'Always open — not counted as play time';

  @override
  String get childAppsCatTools => 'System tools';

  @override
  String get childAppsCatToolsRule => 'Always available for tasks';

  @override
  String childAppsCount(int count) {
    return '$count apps';
  }

  @override
  String childAppsRemaining(int remaining, int limit) {
    return '$remaining of $limit min left';
  }

  @override
  String get childAppsStatusFree => 'Always open';

  @override
  String get childAppsStatusBlocked => 'Blocked';

  @override
  String get childAppsStatusPending => 'Needs decision';

  @override
  String childAppsWallet(int minutes) {
    return 'Wallet $minutes min';
  }

  @override
  String get childAppsInstantLocked => 'Instant locked';

  @override
  String get childAppsAllow => 'Allow';

  @override
  String get childAppsBlock => 'Block';

  @override
  String get childAppsSheetHint =>
      'This change applies on the child device right away.';

  @override
  String get childAppsUnlimitedToggle => 'Unlimited (bypass daily cap)';

  @override
  String get childAppsUnlimitedHint =>
      'Does not bypass block, lock, or mode rules.';

  @override
  String get childAppsStatusUnlimited => 'Unlimited today';

  @override
  String childAppsStatusUpdated(String name) {
    return 'Updated $name';
  }

  @override
  String get newAppApprovalTitle => 'New app approval';

  @override
  String get newAppApprovalRequestHint =>
      'Install request pending your decision — applies on the child device when you allow or deny.';

  @override
  String get newAppApprovalInfoHeading => 'Info & risk card';

  @override
  String get newAppApprovalAgeLabel => 'Age rating';

  @override
  String get newAppApprovalStrangersLabel => 'Chat with strangers';

  @override
  String get newAppApprovalStrangersValue => 'Possible if unchecked';

  @override
  String get newAppApprovalVanishLabel => 'Disappearing messages';

  @override
  String get newAppApprovalVanishValue => 'Yes';

  @override
  String newAppApprovalAdvisorTip(int minutes) {
    return 'Family advisor tip: age-appropriate with a daily cap of $minutes minutes and private-circle safety on.';
  }

  @override
  String newAppApprovalApprove(int minutes) {
    return 'Allow · $minutes min/day';
  }

  @override
  String get newAppApprovalDeny => 'Block with alternative';

  @override
  String get newAppApprovalToneNote =>
      'Tone for the child: guide toward what is better — dialogue, not confrontation.';

  @override
  String get newAppApprovalObserverHint =>
      'View only — deciding needs partner level or higher';

  @override
  String get newAppApprovalEmptyTitle => 'No pending install requests';

  @override
  String get newAppApprovalEmptyMessage =>
      'When the child asks to install a new app, it appears here to allow or deny.';

  @override
  String get newAppApprovalChildLeanTitle => 'Parent tools';

  @override
  String get newAppApprovalChildLeanMessage =>
      'New app approval is for parents only.';

  @override
  String get newAppApprovalSosCta => 'SOS';

  @override
  String newAppApprovalApprovedToast(String name, int minutes) {
    return 'Allowed $name with a $minutes min/day cap — applied on the child device';
  }

  @override
  String newAppApprovalDeniedToast(String name) {
    return 'Blocked $name gently — the child was told this time was not approved';
  }

  @override
  String newAppApprovalDoneAllowed(String name, int minutes) {
    return 'Allowed $name with a $minutes-minute daily cap — the child got the good news';
  }

  @override
  String newAppApprovalDoneBlocked(String name) {
    return 'Blocked $name — the child was notified gently with a helpful alternative';
  }

  @override
  String get newAppApprovalBackToApps => 'Back to child apps';

  @override
  String get tamperAlertsTitle => 'Tamper alerts';

  @override
  String get tamperAlertsPedagogyBanner =>
      'An attempt is not a crime — it is educational information. The goal is dialogue, not punishment.';

  @override
  String get tamperAlertsHonestyBanner =>
      'We flag bypass attempts as dialogue signals — not a courtroom transcript (Bark).';

  @override
  String get tamperAlertsActiveHeading => 'Active alerts';

  @override
  String get tamperAlertsHistoryHeading => 'History';

  @override
  String get tamperAlertsStatusActive => 'Active';

  @override
  String get tamperAlertsStatusHandled => 'Handled';

  @override
  String get tamperAlertsKindVpn => 'VPN app on the child device';

  @override
  String get tamperAlertsKindVpnDetail => 'Detected and disabled automatically';

  @override
  String get tamperAlertsKindPermission => 'Protection permission turned off';

  @override
  String get tamperAlertsKindPermissionDetail =>
      'A required protection permission was revoked';

  @override
  String get tamperAlertsKindClock => 'Device clock changed';

  @override
  String get tamperAlertsKindClockDetail =>
      'Clock was corrected automatically and logged';

  @override
  String get tamperAlertsKindSafeMode => 'Safe mode or bypass boot';

  @override
  String get tamperAlertsKindSafeModeDetail =>
      'A bypass boot path was detected on the child device';

  @override
  String get tamperAlertsKindBypass => 'Bypass attempt';

  @override
  String get tamperAlertsKindBypassDetail =>
      'A technical workaround attempt was flagged';

  @override
  String get tamperAlertsKindSim => 'SIM removed or swapped';

  @override
  String get tamperAlertsKindSimDetail =>
      'SIM change was recorded on the child device';

  @override
  String get tamperAlertsTipVpn =>
      'Suggestion: curiosity about networks is common. Open a calm dialogue: what were you trying to reach?';

  @override
  String get tamperAlertsTipPermission =>
      'Suggestion: ask together why protection was turned off — listen first, then restore settings.';

  @override
  String get tamperAlertsTipClock =>
      'Suggestion: clock tricks often mean more time was wanted — talk about limits before resetting rules.';

  @override
  String get tamperAlertsTipSafeMode =>
      'Suggestion: treat safe-mode boots as a signal to review defenses together, not as a verdict.';

  @override
  String get tamperAlertsTipBypass =>
      'Suggestion: a bypass attempt is information for dialogue — stay curious, not accusatory.';

  @override
  String get tamperAlertsTipSim =>
      'Suggestion: confirm the device is with the child, then review SIM-alert defenses if needed.';

  @override
  String get tamperAlertsSettingsCta => 'Open anti-tamper defenses';

  @override
  String get tamperAlertsEmptyTitle => 'No tamper alerts';

  @override
  String get tamperAlertsEmptyMessage =>
      'When a bypass attempt is detected, it appears here as a dialogue signal — not a judgment.';

  @override
  String get tamperAlertsChildLeanTitle => 'Parent surface';

  @override
  String get tamperAlertsChildLeanMessage =>
      'Tamper alerts are for parents. SOS stays available.';

  @override
  String get tamperAlertsObserverHint =>
      'View only — anti-tamper defenses are configured by the father.';

  @override
  String get tamperAlertsSosCta => 'SOS';

  @override
  String get tamperAlertsLoadingSemantics => 'Loading tamper alerts';

  @override
  String get studioBoardTitle => 'Studio';

  @override
  String get studioBoardCreateTitle => '+ Create content now';

  @override
  String get studioBoardCreateSubtitle =>
      'Photograph a textbook page — Family Advisor prepares a lesson and quiz in 90 seconds';

  @override
  String get studioBoardSuggestionsHeading =>
      'Family Advisor suggestions today';

  @override
  String get studioBoardSugFractionsTitle =>
      'Child is struggling with fractions';

  @override
  String get studioBoardSugFractionsSub => 'Create focused practice?';

  @override
  String get studioBoardSugWirdTitle => 'Memorization wird reached Al-Mulk';

  @override
  String get studioBoardSugWirdSub => 'Prepare this week’s wird?';

  @override
  String get studioBoardRecentHeading => 'My recent content';

  @override
  String get studioBoardRecentAll => 'All';

  @override
  String get studioBoardContentQuizTitle => 'Fractions quiz — Math';

  @override
  String get studioBoardContentQuizSub => 'Assigned · awaiting answers';

  @override
  String get studioBoardContentCardsTitle => 'English flashcards';

  @override
  String get studioBoardContentCardsSub => 'Mastered 18 of 24';

  @override
  String get studioBoardContentWirdTitle => 'Al-Mulk wird 1–10';

  @override
  String get studioBoardContentWirdSub => '3 days in a row';

  @override
  String get studioBoardStatusActive => 'Active';

  @override
  String get studioBoardStatusProgress => '75%';

  @override
  String get studioBoardStatusExcellent => 'Excellent';

  @override
  String get studioBoardQuickCamera => 'Photograph a book';

  @override
  String get studioBoardQuickLibrary => 'Library';

  @override
  String get studioBoardQuickResults => 'Results';

  @override
  String get studioBoardEmptyTitle => 'No content yet';

  @override
  String get studioBoardEmptyMessage =>
      'Start by creating a lesson or quiz from any source — the camera is the shortest path.';

  @override
  String get studioBoardChildLeanTitle => 'Studio is for parents';

  @override
  String get studioBoardChildLeanMessage =>
      'Educational content creation is for parents. SOS stays available.';

  @override
  String get studioBoardObserverHint =>
      'View only — content creation is for the father or a partner/full mother.';

  @override
  String get studioBoardSosCta => 'SOS';

  @override
  String get studioBoardLoadingSemantics => 'Loading studio board';

  @override
  String get addFromSourceTitle => 'Add from any source';

  @override
  String get addFromSourceTip =>
      'Upload any book or notes, or pick the right assignment path for your child.';

  @override
  String get addFromSourcePdfTitle => 'Upload a PDF (textbook / summary)';

  @override
  String get addFromSourcePdfSubtitle =>
      'Family Advisor analyzes the file and builds interactive cards plus a graded quiz in one tap';

  @override
  String get addFromSourcePdfTag => 'Smart generate';

  @override
  String get addFromSourceOptionsHeading => 'Direct assignment options';

  @override
  String get addFromSourceAssignmentTitle =>
      'Assign homework or a skills challenge';

  @override
  String get addFromSourceAssignmentSub =>
      'School notebook task · skill gap · family challenge question';

  @override
  String get addFromSourceCameraTitle => 'Photograph a textbook page';

  @override
  String get addFromSourceCameraSub => 'Quick capture and analysis';

  @override
  String get addFromSourceLinkTitle => 'Educational video link';

  @override
  String get addFromSourceLinkSub => 'YouTube · learning platforms';

  @override
  String get addFromSourceLinkToast =>
      'Paste an educational video link — Family Advisor extracts a summary and exercises';

  @override
  String get addFromSourceTopicTitle => 'Start from a topic only';

  @override
  String get addFromSourceTopicSub =>
      'Name the concept — Advisor drafts a lesson pack';

  @override
  String get addFromSourceTopicToast =>
      'Topic-only create is ready in mock — type a concept next';

  @override
  String get addFromSourceVoiceTitle => 'Voice explanation';

  @override
  String get addFromSourceVoiceSub => 'Record a short parent explanation';

  @override
  String get addFromSourceVoiceToast =>
      'Voice explanation capture is coming (P1) — mock acknowledged';

  @override
  String get addFromSourceLibraryTitle => 'Import from community library';

  @override
  String get addFromSourceLibrarySub =>
      'Trusted shared packs from other families';

  @override
  String get addFromSourcePdfSheetTitle =>
      'Upload a learning PDF and generate content';

  @override
  String get addFromSourcePdfSheetBody =>
      'Pick a textbook or notes PDF — Family Advisor analyzes it and builds cards plus a graded quiz for your child.';

  @override
  String get addFromSourcePdfMathTitle =>
      'Math book — term 2 (fractions & operations)';

  @override
  String get addFromSourcePdfMathSub =>
      'Official PDF · 14.2 MB · middle school';

  @override
  String get addFromSourcePdfScienceTitle =>
      'Science notes — unit 3 (matter & energy)';

  @override
  String get addFromSourcePdfScienceSub =>
      'School PDF · 8.5 MB · summary and questions';

  @override
  String get addFromSourcePdfDeviceTitle =>
      '+ Choose another PDF from this device…';

  @override
  String get addFromSourcePdfDeviceToast =>
      'You can pick any PDF from phone or computer';

  @override
  String get addFromSourcePdfSelectedToast => 'Science notes selected (mock)';

  @override
  String get addFromSourcePdfGenerateCta => 'Analyze and generate';

  @override
  String get addFromSourcePdfProcessingToast =>
      'Family Advisor is analyzing the PDF…';

  @override
  String get addFromSourceChildLeanTitle => 'Adding sources is for parents';

  @override
  String get addFromSourceChildLeanMessage =>
      'Content creation gates are for parents. SOS stays available.';

  @override
  String get addFromSourceObserverHint =>
      'View only — creating from sources is for the father or a partner/full mother.';

  @override
  String get addFromSourceObserverBlocked =>
      'View only — ask the father or a partner mother to create';

  @override
  String get addFromSourceSosCta => 'SOS';

  @override
  String get studioCameraTitle => 'Capture from camera';

  @override
  String get studioCameraInstruction =>
      'Point the camera at a textbook page — fractions, for example';

  @override
  String get studioCameraFrameLabel => 'Page 47 — Fractions';

  @override
  String get studioCameraFrameMeta => 'Math · Grade 9';

  @override
  String get studioCameraFrameSemantics =>
      'Mock camera viewfinder aimed at a textbook page';

  @override
  String get studioCameraCaptureCta => 'Capture and analyze';

  @override
  String get studioCameraAnalyzedToast =>
      'Page analyzed: \"Adding like fractions\" — 3 examples and 6 exercises';

  @override
  String get studioCameraRepairTitle => 'Camera permission needed';

  @override
  String get studioCameraRepairBody =>
      'Capturing a textbook page needs the camera once. Open system settings and enable camera for this app — you are not stuck.';

  @override
  String get studioCameraOpenSettings => 'Open camera settings';

  @override
  String get studioCameraOpenSettingsToast =>
      'Opening system settings (demo) — enable camera, then return.';

  @override
  String get studioCameraRetryPermission => 'Try requesting permission again';

  @override
  String get studioCameraPermanentTitle => 'Camera blocked for this app';

  @override
  String get studioCameraPermanentBody =>
      'Enable camera in system settings for this app, then return to capture a textbook page.';

  @override
  String get studioCameraChildLeanTitle => 'Camera capture is for parents';

  @override
  String get studioCameraChildLeanMessage =>
      'Textbook page capture is a parent studio tool. SOS stays available.';

  @override
  String get studioCameraObserverHint =>
      'View only — capturing pages is for the father or a partner/full mother.';

  @override
  String get studioCameraObserverBlocked =>
      'View only — ask the father or a partner mother to capture';

  @override
  String get studioCameraSosCta => 'SOS';

  @override
  String get studioCameraLoadingSemantics => 'Checking camera permission';

  @override
  String get generationOutputsTitle => 'Generation outputs';

  @override
  String get generationOutputsHeading => 'What should we generate?';

  @override
  String get generationOutputsSourceFractions =>
      'Source: \"Adding like fractions\" — p.47 Math';

  @override
  String get generationOutputsLessonTitle => 'Simplified lesson';

  @override
  String get generationOutputsLessonSub =>
      'Interactive explanation in your child\'s language';

  @override
  String get generationOutputsHomeworkTitle => 'Homework';

  @override
  String get generationOutputsHomeworkSub => '6 graded exercises';

  @override
  String get generationOutputsQuizTitle => 'Short quiz';

  @override
  String get generationOutputsQuizSub => '10 auto-graded questions';

  @override
  String get generationOutputsFlashcardsTitle => 'Memory cards';

  @override
  String get generationOutputsFlashcardsSub => 'Fraction rules';

  @override
  String get generationOutputsChallengeTitle => 'Reward challenge';

  @override
  String get generationOutputsChallengeSub =>
      'Solve 5 with no errors = 20 minutes';

  @override
  String get generationOutputsReviewGameTitle => 'Review game';

  @override
  String get generationOutputsReviewGameSub => 'Match · order · true/false';

  @override
  String get generationOutputsPhaseTag => 'P1';

  @override
  String get generationOutputsPhaseLockedToast =>
      'Review game ships in a later phase — not selectable yet';

  @override
  String get generationOutputsReligiousLock =>
      'Religious content (Qur\'an · Hadith · Fiqh) is never auto-generated — only trusted sources, and the father reviews. Owner decision; no exception.';

  @override
  String generationOutputsGenerateCta(int count) {
    return 'Generate selected ($count)';
  }

  @override
  String get generationOutputsGeneratingToast =>
      'Family Advisor is generating now…';

  @override
  String get generationOutputsNoneSelectedToast =>
      'Select at least one output to generate';

  @override
  String get generationOutputsEmptyTitle => 'No outputs yet';

  @override
  String get generationOutputsEmptyMessage =>
      'Capture or upload a source first — then choose which forms to generate.';

  @override
  String get generationOutputsLoadingSemantics => 'Loading generation outputs';

  @override
  String get generationOutputsChildLeanTitle =>
      'Generation outputs are for parents';

  @override
  String get generationOutputsChildLeanMessage =>
      'Choosing studio outputs is a parent tool. SOS stays available.';

  @override
  String get generationOutputsObserverHint =>
      'View only — selecting and generating is for the father or a partner/full mother.';

  @override
  String get generationOutputsObserverBlocked =>
      'View only — ask the father or a partner mother to generate';

  @override
  String get generationOutputsSosCta => 'SOS';

  @override
  String get previewApproveTitle => 'Preview and approve';

  @override
  String get previewApproveRuleBanner =>
      '90-second rule — parents approve, they do not author · light edits only';

  @override
  String get previewApproveQuizTitle => 'Quiz';

  @override
  String get previewApproveLessonTitle => 'Lesson';

  @override
  String get previewApproveReadyTag => 'Ready';

  @override
  String get previewApproveQ1Prompt => 'Q1: 2/7 + 3/7 = ?';

  @override
  String get previewApproveQ1OptA => 'A) 5/7 ✓';

  @override
  String get previewApproveQ1OptB => 'B) 5/14';

  @override
  String get previewApproveQ1OptC => 'C) 6/7';

  @override
  String get previewApproveQ2Prompt => 'Q2: 1/5 + 2/5 = ?';

  @override
  String get previewApproveQ2OptA => 'A) 3/5 ✓';

  @override
  String get previewApproveQ2OptB => 'B) 3/10';

  @override
  String get previewApproveQ2OptC => 'C) 2/5';

  @override
  String get previewApproveQ3Prompt => 'Q3: 4/9 + 2/9 = ?';

  @override
  String get previewApproveQ3OptA => 'A) 6/9 ✓';

  @override
  String get previewApproveQ3OptB => 'B) 6/18';

  @override
  String get previewApproveQ3OptC => 'C) 8/9';

  @override
  String get previewApproveLessonSummary =>
      '\"Imagine a pizza cut into 7 slices…\" — visual examples';

  @override
  String get previewApproveSwapCta => 'Swap a question';

  @override
  String get previewApproveEditCta => 'Edit a question';

  @override
  String get previewApproveDeleteCta => 'Delete';

  @override
  String get previewApproveDifficultyCta => 'Easier / harder';

  @override
  String get previewApproveSwapToast => 'Q3 replaced with an easier question';

  @override
  String get previewApproveEditToast =>
      'Open any question and edit its text and choices before sending';

  @override
  String get previewApproveDeleteToast =>
      'Question deleted — only what you approve reaches the child';

  @override
  String get previewApproveDifficultyToast => 'Difficulty level adjusted';

  @override
  String get previewApproveApproveCta => 'Approve all — assign now';

  @override
  String get previewApproveRejectCta => 'Reject content';

  @override
  String get previewApproveRejectToast =>
      'Content rejected — will not be assigned to the child';

  @override
  String get previewApproveCannotApproveToast =>
      'No approved content to assign';

  @override
  String previewApproveTimingNote(int seconds) {
    return 'Capture to here: ~${seconds}s — within the 90s rule ✓';
  }

  @override
  String get previewApproveEmptyTitle => 'No preview yet';

  @override
  String get previewApproveEmptyMessage =>
      'Generate studio outputs first — then review and approve here.';

  @override
  String get previewApproveLoadingSemantics => 'Loading preview';

  @override
  String get previewApproveChildLeanTitle =>
      'Preview and approve are for parents';

  @override
  String get previewApproveChildLeanMessage =>
      'Approving studio outputs is a parent tool. SOS stays available.';

  @override
  String get previewApproveObserverHint =>
      'View only — approve and reject are for the father or a partner/full mother.';

  @override
  String get previewApproveObserverBlocked =>
      'View only — ask the father or a partner mother to approve';

  @override
  String get previewApproveSosCta => 'SOS';

  @override
  String get attributionRewardTitle => 'Attribution and reward';

  @override
  String attributionRewardMasteryBanner(int percent) {
    return 'Screen-time minutes on mastery (≥$percent%) — parents set minutes only';
  }

  @override
  String get attributionRewardWhoHeading => 'Who?';

  @override
  String get attributionRewardChildOne => 'Child 1';

  @override
  String get attributionRewardChildTwo => 'Child 2';

  @override
  String get attributionRewardChildThree => 'Child 3';

  @override
  String get attributionRewardScheduleLabel => 'When';

  @override
  String get attributionRewardScheduleTomorrow => 'Tomorrow — after school';

  @override
  String get attributionRewardScheduleToday => 'Today';

  @override
  String get attributionRewardScheduleWeekend => 'Weekend';

  @override
  String attributionRewardRewardsHeading(int percent) {
    return 'Reward on mastery (≥$percent%)';
  }

  @override
  String attributionRewardWalletMinutes(int minutes) {
    return '$minutes minutes to their wallet';
  }

  @override
  String attributionRewardPlayMinutes(int minutes) {
    return '+$minutes play minutes';
  }

  @override
  String get attributionRewardAutoAdded => 'Added automatically';

  @override
  String get attributionRewardAssignCta => 'Assign ✓';

  @override
  String get attributionRewardLibraryCta => 'Community library';

  @override
  String attributionRewardAssignedToast(String name, int minutes) {
    return 'Assigned to $name — they see: \"Your parent prepared a challenge — $minutes minutes waiting!\"';
  }

  @override
  String get attributionRewardCannotAssignToast =>
      'Pick a child and enable at least one minutes reward';

  @override
  String get attributionRewardEmptyTitle => 'No children to assign';

  @override
  String get attributionRewardEmptyMessage =>
      'Link a child device first — then assign content with a minutes reward.';

  @override
  String get attributionRewardLoadingSemantics => 'Loading attribution';

  @override
  String get attributionRewardChildLeanTitle =>
      'Attribution and reward are for parents';

  @override
  String get attributionRewardChildLeanMessage =>
      'Assigning studio content is a parent tool. SOS stays available.';

  @override
  String get attributionRewardObserverHint =>
      'View only — assign is for the father or a partner/full mother.';

  @override
  String get attributionRewardObserverBlocked =>
      'View only — ask the father or a partner mother to assign';

  @override
  String get attributionRewardSosCta => 'SOS';

  @override
  String get communityLibraryTitle => 'Community library';

  @override
  String get communityLibrarySearchHint =>
      'Search: fractions · tajweed · English…';

  @override
  String get communityLibrarySearchNoResults => 'No packs match this search';

  @override
  String get communityLibraryTopRatedHeading => 'Top rated this week';

  @override
  String get communityLibraryPackFractions => 'Complete fractions series';

  @override
  String get communityLibraryPackJuzAmma => 'Juz Amma review';

  @override
  String get communityLibraryPackEnglish => 'English flashcards — middle 1';

  @override
  String get communityLibraryAuthorFatherRiyadh => 'Father from Riyadh';

  @override
  String get communityLibraryAuthorMotherJeddah => 'Mother from Jeddah';

  @override
  String get communityLibraryAuthorFatherDammam => 'Father from Dammam';

  @override
  String communityLibraryPackMeta(String author, String rating, int count) {
    return '$author · ⭐ $rating ($count)';
  }

  @override
  String communityLibraryPackDetail(int lessons, int quizzes, String author) {
    return '$lessons lessons + $quizzes quizzes · shared by $author · passed community review ✓';
  }

  @override
  String get communityLibraryTrustedTag => 'Trusted ✓';

  @override
  String get communityLibraryImportCta => 'Import free';

  @override
  String get communityLibraryImportedToast =>
      'Imported to your studio — edit freely';

  @override
  String get communityLibraryPublishHeading => 'Share yours too';

  @override
  String get communityLibraryPublishMessage =>
      'The fractions quiz you made delighted your children — publish it so others benefit.';

  @override
  String get communityLibraryPublishPackFractionsQuiz => 'fractions quiz';

  @override
  String communityLibraryPublishCta(String name) {
    return 'Publish «$name»';
  }

  @override
  String get communityLibraryPublishSubmittedToast =>
      'Sent for review — publishes under your anonymous name after the six controls';

  @override
  String get communityLibraryPublishPendingFatherToast =>
      'Sent for father approval — then the six community controls';

  @override
  String get communityLibrarySixControlsNote =>
      'Every published pack passes six controls: review · age rating · no personal data · ratings · reports · instant removal';

  @override
  String get communityLibraryPathCta => 'Open learning path';

  @override
  String get communityLibraryEmptyTitle => 'Community library is quiet';

  @override
  String get communityLibraryEmptyMessage =>
      'Create a pack in the studio first — then browse and share with other families.';

  @override
  String get communityLibraryEmptyCta => 'Add from any source';

  @override
  String get communityLibraryLoadingSemantics => 'Loading community library';

  @override
  String get communityLibraryChildLeanTitle =>
      'Community library is for parents';

  @override
  String get communityLibraryChildLeanMessage =>
      'Importing and publishing community packs is a parent tool. SOS stays available.';

  @override
  String get communityLibraryObserverHint =>
      'View only — import and publish are for the father or a partner/full mother.';

  @override
  String get communityLibraryObserverBlocked =>
      'View only — ask the father or a partner mother to import';

  @override
  String get communityLibrarySosCta => 'SOS';

  @override
  String get learningPathTitle => 'Learning path';

  @override
  String learningPathHeading(String child, String subject) {
    return '$child\'s path — $subject';
  }

  @override
  String get learningPathChildOne => 'Child 1';

  @override
  String get learningPathChildTwo => 'Child 2';

  @override
  String get learningPathChildThree => 'Child 3';

  @override
  String get learningPathSubjectFractions => 'Fractions';

  @override
  String learningPathProgressLabel(int percent, int done, int total) {
    return '$percent% — $done of $total lessons';
  }

  @override
  String get learningPathStopConcept => 'Fraction concept';

  @override
  String get learningPathStopSimilar => 'Like fractions';

  @override
  String get learningPathStopAdding => 'Adding fractions';

  @override
  String get learningPathStopSubtract => 'Subtracting fractions';

  @override
  String get learningPathStopFinalQuiz => 'Comprehensive quiz';

  @override
  String learningPathStopMastered(int percent) {
    return 'Mastered $percent%';
  }

  @override
  String get learningPathStopQuizPending => 'Quiz pending — assigned today';

  @override
  String get learningPathStopLocked => 'Opens after mastery';

  @override
  String learningPathStopReward(int minutes) {
    return 'Big reward: $minutes minutes';
  }

  @override
  String get learningPathAdvisorBanner =>
      'Family advisor suggests the next step from mastery — no advance without understanding.';

  @override
  String get learningPathMaterialsCta => 'Materials and lessons';

  @override
  String get learningPathLockedToast => 'This step opens after mastery';

  @override
  String get learningPathMasteredToast =>
      'Already mastered — keep the path moving';

  @override
  String get learningPathEmptyTitle => 'No learning path yet';

  @override
  String get learningPathEmptyMessage =>
      'Create content in the studio first — then track mastery along a path.';

  @override
  String get learningPathEmptyCta => 'Add from any source';

  @override
  String get learningPathLoadingSemantics => 'Loading learning path';

  @override
  String get learningPathChildLeanTitle => 'Learning path is for parents';

  @override
  String get learningPathChildLeanMessage =>
      'Tracking the mastery path is a parent tool. SOS stays available.';

  @override
  String get learningPathObserverHint =>
      'View only — opening materials is for the father or a partner/full mother.';

  @override
  String get learningPathObserverBlocked =>
      'View only — ask the father or a partner mother to open materials';

  @override
  String get learningPathSosCta => 'SOS';

  @override
  String get materialsLessonsTitle => 'Materials and lessons';

  @override
  String get materialsLessonsSubjectMath => 'Math';

  @override
  String get materialsLessonsSubjectQuran => 'Quran and tajweed';

  @override
  String get materialsLessonsSubjectEnglish => 'English';

  @override
  String get materialsLessonsSubjectScience => 'Science';

  @override
  String materialsLessonsMetaMathActive(int lessons, int quizzes) {
    return '$lessons lessons · $quizzes quizzes · active path';
  }

  @override
  String get materialsLessonsMetaQuranWeekly =>
      'Weekly wird · from trusted sources';

  @override
  String materialsLessonsMetaEnglishCards(int count) {
    return '$count flashcards';
  }

  @override
  String get materialsLessonsMetaScienceImported =>
      'Lesson imported from the library';

  @override
  String get materialsLessonsAddSubjectCta => '+ Subject';

  @override
  String get materialsLessonsAddLessonCta => '+ Lesson';

  @override
  String get materialsLessonsAssignmentCta => 'Create assignment';

  @override
  String get materialsLessonsAddSubjectToast =>
      'New subject with its own color';

  @override
  String get materialsLessonsSubjectToast =>
      'Open lessons for this subject soon';

  @override
  String get materialsLessonsEmptyTitle => 'No subjects yet';

  @override
  String get materialsLessonsEmptyMessage =>
      'Add a subject or import a lesson — then organize courses and assignments.';

  @override
  String get materialsLessonsEmptyCta => 'Add from any source';

  @override
  String get materialsLessonsLoadingSemantics =>
      'Loading materials and lessons';

  @override
  String get materialsLessonsChildLeanTitle => 'Materials are for parents';

  @override
  String get materialsLessonsChildLeanMessage =>
      'Managing subjects and lessons is a parent tool. SOS stays available.';

  @override
  String get materialsLessonsObserverHint =>
      'View only — adding subjects, lessons, and assignments is for the father or a partner/full mother.';

  @override
  String get materialsLessonsObserverBlocked =>
      'View only — ask the father or a partner mother to manage materials';

  @override
  String get materialsLessonsSosCta => 'SOS';

  @override
  String get createAssignmentTitle => 'Create assignment and quiz';

  @override
  String createAssignmentHeading(String name) {
    return 'What do you want to assign to $name?';
  }

  @override
  String createAssignmentIntroBanner(String name) {
    return 'Pick the assignment type that fits $name\'s day — the system routes it to the right child screen.';
  }

  @override
  String get createAssignmentChildOne => 'Child one';

  @override
  String get createAssignmentChildTwo => 'Child two';

  @override
  String get createAssignmentChildThree => 'Child three';

  @override
  String get createAssignmentHomeworkTitle =>
      '1. School homework (notebook / platform)';

  @override
  String get createAssignmentHomeworkSubtitle =>
      'Solved in the school notebook — photo proof uploaded';

  @override
  String get createAssignmentHomeworkHint => 'Example: Solve page 45 in math';

  @override
  String createAssignmentHomeworkReward(int minutes) {
    return 'Reward: +$minutes play minutes to wallet';
  }

  @override
  String get createAssignmentHomeworkProofTag => 'Photo proof';

  @override
  String get createAssignmentHomeworkCta => 'Assign school homework →';

  @override
  String get createAssignmentHomeworkEmptyToast =>
      'Enter a homework title first';

  @override
  String createAssignmentHomeworkAssignedToast(String name) {
    return 'School homework assigned to $name';
  }

  @override
  String get createAssignmentSkillTitle => '2. Fix a skill gap (remediation)';

  @override
  String get createAssignmentSkillSubtitle =>
      'Pulled directly from the results report';

  @override
  String get createAssignmentSkillRecommendedTag => 'Recommended';

  @override
  String get createAssignmentSkillGapLabel => 'Skill gap found in the report:';

  @override
  String get createAssignmentSkillFractionDivision =>
      'Dividing proper fractions';

  @override
  String createAssignmentSkillGapLine(String title, String detail) {
    return '➗ $title ($detail)';
  }

  @override
  String createAssignmentSkillMissed(int missed, int total) {
    return 'missed $missed of $total';
  }

  @override
  String createAssignmentSkillQuizReady(int count) {
    return 'Ready interactive quiz — $count graded questions';
  }

  @override
  String createAssignmentSkillCta(String name, int minutes) {
    return 'Assign skill challenge quiz to $name (+$minutes min) →';
  }

  @override
  String get createAssignmentSkillEmptyMessage =>
      'No open skill gap yet — check results follow-up after a quiz.';

  @override
  String createAssignmentSkillAssignedToast(String name, int minutes) {
    return 'Skill challenge assigned to $name (+$minutes minutes)';
  }

  @override
  String get createAssignmentFamilyTitle =>
      '3. Family challenge question from parent';

  @override
  String get createAssignmentFamilySubtitle =>
      'Riddle, brain teaser, or a friendly fact';

  @override
  String get createAssignmentFamilyHint => 'Write your question here…';

  @override
  String createAssignmentFamilyReward(int minutes) {
    return 'Reward: +$minutes courage minutes';
  }

  @override
  String get createAssignmentFamilyGoldTag => 'Gold card';

  @override
  String get createAssignmentFamilyCta => 'Send challenge as a premium card →';

  @override
  String get createAssignmentFamilyEmptyToast =>
      'Write a challenge question first';

  @override
  String createAssignmentFamilyAssignedToast(String name) {
    return 'Family challenge sent to $name';
  }

  @override
  String get createAssignmentResultsCta => 'Follow results';

  @override
  String get createAssignmentEmptyTitle => 'No child to assign';

  @override
  String get createAssignmentEmptyMessage =>
      'Link a child first — then assign homework, a skill quiz, or a family challenge.';

  @override
  String get createAssignmentEmptyCta => 'Add a child';

  @override
  String get createAssignmentLoadingSemantics => 'Loading create assignment';

  @override
  String get createAssignmentChildLeanTitle => 'Assignments are for parents';

  @override
  String get createAssignmentChildLeanMessage =>
      'Creating homework and quizzes is a parent tool. SOS stays available.';

  @override
  String get createAssignmentObserverHint =>
      'View only — assigning homework, skill quizzes, and family challenges is for the father or a partner/full mother.';

  @override
  String get createAssignmentObserverBlocked =>
      'View only — ask the father or a partner mother to assign';

  @override
  String get createAssignmentSosCta => 'SOS';

  @override
  String get resultsFollowupTitle => 'Results & mastery';

  @override
  String resultsFollowupHeading(String name) {
    return 'Results & mastery for $name';
  }

  @override
  String get resultsFollowupChildOne => 'First child';

  @override
  String get resultsFollowupChildTwo => 'Second child';

  @override
  String get resultsFollowupChildThree => 'Third child';

  @override
  String resultsFollowupMasteryCaption(String subject) {
    return '$subject mastery level';
  }

  @override
  String get resultsFollowupMasterySubjectMath => 'Math';

  @override
  String resultsFollowupMasteryAverageTag(int percent) {
    return '$percent% average';
  }

  @override
  String resultsFollowupMasteryImprovedTag(int percent) {
    return 'Rose to $percent% ↗';
  }

  @override
  String resultsFollowupMasteryHero(int percent) {
    return '$percent%';
  }

  @override
  String get resultsFollowupGapSectionTitle => 'Skill gaps & remediation';

  @override
  String get resultsFollowupGapNeedsFixTag => 'Needs reinforcement';

  @override
  String get resultsFollowupGapMasteredTag => 'Reinforced ✓';

  @override
  String get resultsFollowupSkillFractionDivision =>
      'Dividing proper fractions';

  @override
  String resultsFollowupGapPendingDetail(int missed, int total) {
    return 'Missed $missed of $total — needs a remedial drill';
  }

  @override
  String resultsFollowupGapMasteredDetail(int percent) {
    return 'Passed the quiz and locked the skill at $percent%';
  }

  @override
  String get resultsFollowupGapCta => 'Remediate gap ⚡';

  @override
  String get resultsFollowupGapMasteredLabel => 'Mastered ⭐';

  @override
  String get resultsFollowupActivitySectionTitle => 'Homework & activity log';

  @override
  String get resultsFollowupActivitySchoolFractionsTitle =>
      'School fractions homework';

  @override
  String get resultsFollowupActivityDailyChallengeTitle =>
      'Today\'s challenge from dad';

  @override
  String get resultsFollowupActivityOnTimePhoto =>
      'Submitted on time · graded by photo 📸';

  @override
  String resultsFollowupActivityEarnedMinutes(int minutes) {
    return 'Answered accurately and earned +$minutes minutes';
  }

  @override
  String get resultsFollowupActivityStatusComplete => 'Complete';

  @override
  String get resultsFollowupActivityStatusApproved => 'Approved';

  @override
  String get resultsFollowupFocusCta => 'Focus sessions report';

  @override
  String get resultsFollowupEmptyTitle => 'No child to follow';

  @override
  String get resultsFollowupEmptyMessage =>
      'Link a child first — then track mastery, skill gaps, and homework outcomes.';

  @override
  String get resultsFollowupEmptyCta => 'Add a child';

  @override
  String get resultsFollowupLoadingSemantics => 'Loading results follow-up';

  @override
  String get resultsFollowupChildLeanTitle => 'Results are for parents';

  @override
  String get resultsFollowupChildLeanMessage =>
      'Tracking results and mastery is a parent tool. SOS stays available.';

  @override
  String get resultsFollowupObserverHint =>
      'View only — remediating skill gaps is for the father or a partner/full mother.';

  @override
  String get resultsFollowupObserverBlocked =>
      'View only — ask the father or a partner mother to remediate gaps';

  @override
  String get resultsFollowupSosCta => 'SOS';

  @override
  String get webFilterTitle => 'Web filter';

  @override
  String get webFilterSubtitle =>
      'Category blocks persist and enforce browsing — not decorative switches';

  @override
  String get webFilterLevelHeading => 'Filter level';

  @override
  String get webFilterLevelStrict => 'Strict';

  @override
  String get webFilterLevelBalanced => 'Balanced';

  @override
  String get webFilterLevelOpen => 'Open';

  @override
  String get webFilterCategoriesHeading => 'Blocked categories';

  @override
  String get webFilterCategoryAdults => 'Adult content';

  @override
  String get webFilterCategoryGambling => 'Gambling';

  @override
  String get webFilterCategoryViolence => 'Violence';

  @override
  String get webFilterCategorySocial => 'Social media';

  @override
  String get webFilterCategoryGames => 'Games';

  @override
  String get webFilterCategoryStreaming => 'Streaming';

  @override
  String get webFilterSave => 'Save filter';

  @override
  String get webFilterSaveToast => 'Web filter saved';

  @override
  String get webFilterReadOnly => 'View only — father can edit';

  @override
  String get webFilterPreviewHeading => 'Preview what the child sees';

  @override
  String get webFilterPreviewHint =>
      'Same block decision the child sees — reopen preview after changing policy';

  @override
  String get webFilterPreviewUrlHint => 'https://adult.example/…';

  @override
  String get webFilterPreviewUseFixture => 'Use adult-content fixture';

  @override
  String get webFilterPreviewButton => 'Preview what the child sees';

  @override
  String get webFilterListsHeading => 'Allow · Block · Dictionary';

  @override
  String get webFilterAllowListHeading => 'Allowlist';

  @override
  String get webFilterBlockListHeading => 'Blocklist';

  @override
  String get webFilterDictionaryHeading => 'Keyword dictionary';

  @override
  String get webFilterListAddHint => 'Add host or keyword';

  @override
  String get webFilterListAdd => 'Add';

  @override
  String get webFilterListEmpty => 'No entries yet';

  @override
  String get webFilterPrecedenceNote =>
      'Precedence: blocklist → temporary allow → allowlist → dictionary → category';

  @override
  String get webFilterTaxonomyTbdHonesty =>
      'Category labels are provisional — full taxonomy TBD';

  @override
  String get webFilterNativeBlockHonesty =>
      'Device block plane is mock-remote — policy is real; VPN/DNS not claimed';

  @override
  String get webFilterPreviewSheetTitle => 'How the child sees it';

  @override
  String get webBlockTitle => 'This site is blocked for now';

  @override
  String get webBlockAllowedTitle => 'This site is allowed';

  @override
  String get webBlockAllowedBody =>
      'No block page for this link under the current policy.';

  @override
  String get webBlockUnlockCta => 'Ask your father to unlock this site';

  @override
  String get webBlockReasonAdults =>
      'This content is for adults and is not suitable for you right now. If it matters for school, you can gently ask to unlock it.';

  @override
  String get webBlockReasonGambling =>
      'This site is related to gambling and is not suitable for you right now.';

  @override
  String get webBlockReasonViolence =>
      'This content includes violence and is not suitable for you right now.';

  @override
  String get webBlockReasonSocial =>
      'Social sites are temporarily blocked under your family policy.';

  @override
  String get webBlockReasonGames =>
      'Online games are temporarily blocked under your family policy.';

  @override
  String get webBlockReasonStreaming =>
      'Streaming and entertainment sites are temporarily blocked under your family policy.';

  @override
  String get webBlockReasonGeneric =>
      'This content is not suitable for you right now. If it matters for school, ask your father to unlock it.';

  @override
  String get webBlockReasonBlocklist =>
      'This site is on your family\'s block list.';

  @override
  String get webBlockReasonDictionary =>
      'This page matches a blocked keyword from your family\'s dictionary.';

  @override
  String webBlockSourceOfDeny(String source) {
    return 'Source: $source';
  }

  @override
  String get webBlockFeedbackPending =>
      'Unlock request sent — waiting for a parent';

  @override
  String get webBlockFeedbackApproved =>
      'Temporary unlock approved — try again soon';

  @override
  String get webBlockFeedbackDenied => 'Unlock was denied';

  @override
  String get webBlockFeedbackExpired => 'Temporary unlock expired';

  @override
  String get webFilterDeliveryHonesty =>
      'Policy delivery is tracked locally (Configured→Verified). Device block remains mock-remote.';

  @override
  String get webUnlockInboxTitle => 'Unlock requests';

  @override
  String get webUnlockInboxSubtitle =>
      'Approve or deny sites your child asked to open — like Family Link app approval';

  @override
  String get webUnlockInboxEmpty => 'No pending unlock requests';

  @override
  String get webUnlockApprove => 'Approve';

  @override
  String get webUnlockDeny => 'Deny';

  @override
  String get webUnlockObserverHint =>
      'View only — partner or father can approve';

  @override
  String get webUnlockRequestedToast => 'Unlock request sent to your parents';

  @override
  String get webUnlockDuplicateToast => 'You already asked to unlock this site';

  @override
  String get webUnlockApprovedToast => 'Your parents unlocked this site';

  @override
  String get webUnlockDeniedToast => 'Your parents kept this site blocked';

  @override
  String get instantLockTitle => 'Instant lock';

  @override
  String get instantLockToggle => 'Lock device now';

  @override
  String get instantLockSubtitle =>
      'Locks the child device immediately; SOS, chat, and Quran stay reachable';

  @override
  String get instantLockStatusLocked => 'Device locked';

  @override
  String get instantLockStatusUnlocked => 'Device unlocked';

  @override
  String get instantLockLockedByFather => 'Locked by father';

  @override
  String get instantLockLockedByMother => 'Locked by mother';

  @override
  String get instantLockAction => 'Lock';

  @override
  String get instantLockUnlockAction => 'Unlock';

  @override
  String get instantLockDeniedToast => 'Not allowed to change device lock';

  @override
  String get instantLockSupersessionBanner =>
      'Father unlocked the device (your lock was superseded)';

  @override
  String get antiTamperSectionTitle => 'Anti-tamper defenses';

  @override
  String get antiTamperUnavailable => 'Unavailable';

  @override
  String get antiTamperSave => 'Save defenses';

  @override
  String get antiTamperSaveToast => 'Anti-tamper defenses saved';

  @override
  String get antiTamperDeniedToast =>
      'Not allowed to change anti-tamper defenses';

  @override
  String get antiTamperNoDelete => 'Block app uninstall';

  @override
  String get antiTamperNoClockChange => 'Block clock changes';

  @override
  String get antiTamperNoVpn => 'Block VPN';

  @override
  String get antiTamperSimAlert => 'SIM swap alert';

  @override
  String get antiTamperSettingsPin => 'Device settings PIN';

  @override
  String get antiTamperBypassAlert => 'Bypass attempt alert';

  @override
  String get antiTamperNoDeleteWhenEnabled =>
      'Blocks uninstall of the Family OS child app';

  @override
  String get antiTamperNoClockChangeWhenEnabled =>
      'Blocks changing the device clock to cheat schedules';

  @override
  String get antiTamperNoVpnWhenEnabled =>
      'Blocks or alerts on VPN that bypasses the filter';

  @override
  String get antiTamperSimAlertWhenEnabled =>
      'Alerts the father when the SIM is changed or removed';

  @override
  String get antiTamperSettingsPinWhenEnabled =>
      'Requires the father\'s PIN for sensitive device settings';

  @override
  String get antiTamperBypassAlertWhenEnabled =>
      'Alerts the father when a bypass or tamper attempt is detected';

  @override
  String get antiTamperNeedsDevicePermission => 'Needs device permission';

  @override
  String get notificationPrefsTitle => 'Notifications';

  @override
  String get notificationPrefsSubtitle =>
      'Quiet hours mute non-critical alerts only';

  @override
  String get notificationPrefsQuietHours => 'Quiet hours';

  @override
  String get notificationPrefsStart => 'Start';

  @override
  String get notificationPrefsEnd => 'End';

  @override
  String get notificationPrefsValidation =>
      'Choose different start and end times';

  @override
  String get notificationPrefsSave => 'Save notifications';

  @override
  String get notificationPrefsSaveToast => 'Notification preferences saved';

  @override
  String get notificationPrefsSosPierceBanner =>
      'SOS and critical alerts always get through — even during quiet hours';

  @override
  String notificationPrefsMemberHeading(String member) {
    return 'Preferences for $member';
  }

  @override
  String get notificationPrefsMemberFather => 'Father';

  @override
  String get notificationPrefsMemberMother => 'Mother';

  @override
  String get notificationPrefsMemberChild => 'Child';

  @override
  String get notificationPrefsAnalysisNotices => 'Analysis notices';

  @override
  String get notificationPrefsAnalysisNoticesHint =>
      'Optional non-critical updates when Advisor analyses run';

  @override
  String get privacyDataTitle => 'Privacy & data';

  @override
  String get privacyDataSubtitle =>
      'What is collected about the child is shown honestly — father toggles update the transparency screen';

  @override
  String get privacyDataScopesHeading => 'Collection scopes';

  @override
  String get privacyDataRetentionNote =>
      'Turning off live collection does not wipe historical records — retention ≠ current collection';

  @override
  String get privacyDataReadOnlyNote =>
      'View only — owner privacy edits are father-only';

  @override
  String get privacyDataSave => 'Save collection scopes';

  @override
  String get privacyDataSaveToast => 'Collection scopes saved';

  @override
  String get privacyDataWriteDenied => 'Not allowed — owner privacy only';

  @override
  String get privacyScopeLocation => 'Location';

  @override
  String get privacyScopeScreenTime => 'Screen time';

  @override
  String get privacyScopeWebActivity => 'Web activity';

  @override
  String get privacyScopeCommunications => 'Communications';

  @override
  String get whatIsCollectedTitle => 'What is collected about me';

  @override
  String get whatIsCollectedSubtitle =>
      'This list mirrors what your guardian currently allows to be collected';

  @override
  String get whatIsCollectedHonestyNote =>
      'Transparency without deception — you cannot edit these scopes';

  @override
  String get whatIsCollectedEmpty =>
      'Nothing is being collected about you right now per guardian settings';

  @override
  String whatIsCollectedLastUpdated(String when) {
    return 'Last updated: $when';
  }

  @override
  String get privacyLifecycleHeading => 'Memory & family data';

  @override
  String get privacyForgetButton => 'Forget advisor memory';

  @override
  String get privacyForgetConfirmTitle => 'Forget advisor memory?';

  @override
  String get privacyForgetConfirmBody =>
      'This clears advisor memory notes only. Chat messages and the audit log stay intact.';

  @override
  String get privacyForgetConfirmAction => 'Forget memory';

  @override
  String get privacyForgetToast => 'Advisor memory cleared';

  @override
  String get privacyWipeButton => 'Wipe family data';

  @override
  String get privacyWipeStep1Title => 'Wipe family data?';

  @override
  String get privacyWipeStep1Body =>
      'This schedules a permanent wipe of family data. Audit log entries are never deleted. You get a 7-day regret window to cancel.';

  @override
  String get privacyWipeStep1Continue => 'Continue';

  @override
  String get privacyWipeStep2Title => 'Confirm wipe schedule';

  @override
  String privacyWipeStep2Body(String phrase) {
    return 'Type $phrase to schedule the wipe. Execution waits 7 days — cancel anytime in that window.';
  }

  @override
  String get privacyWipeConfirmPhrase => 'WIPE';

  @override
  String get privacyWipeStep2Action => 'Schedule wipe';

  @override
  String get privacyWipeScheduledToast =>
      'Wipe scheduled — 7-day regret window started';

  @override
  String privacyWipePendingBanner(String when) {
    return 'Wipe pending until $when — cancel within 7 days';
  }

  @override
  String get privacyWipeCancelButton => 'Cancel scheduled wipe';

  @override
  String get privacyWipeCancelledToast => 'Scheduled wipe cancelled';

  @override
  String get privacyLifecycleDeniedToast =>
      'Not allowed — owner-only forget / wipe';

  @override
  String get privacyDialogCancel => 'Cancel';

  @override
  String get privacyAuditPanelTitle => 'Audit log (append-only)';

  @override
  String get privacyAuditPanelHint =>
      'Forget never appears here — audit is never wiped (R10)';

  @override
  String get privacyAuditPanelEmpty => 'No audit entries yet';

  @override
  String get brainControlTitle => 'Brain control';

  @override
  String get brainServesNotDecidesBanner =>
      'AI serves — it does not decide. Suggestions only; you always choose (Bark).';

  @override
  String get brainStagesHeading => 'AI stages (server flags)';

  @override
  String get brainStageAnalyzeTitle => 'Analyze';

  @override
  String get brainStageAnalyzeSubtitle =>
      'Patterns and anomalies — server gateway when enabled';

  @override
  String get brainStageSuggestTitle => 'Suggest';

  @override
  String get brainStageSuggestSubtitle =>
      'Practical suggestions — you approve or reject';

  @override
  String get brainStageCoachTitle => 'Coach';

  @override
  String get brainStageCoachSubtitle =>
      'Ask about family knowledge — never auto-executes';

  @override
  String get brainStageActive => 'Active';

  @override
  String get brainStageComingSoon => 'Coming soon';

  @override
  String get brainStageViewSuggestions => 'View suggestions';

  @override
  String get brainSuggestionsHeading => 'Advisor suggestions (prototype)';

  @override
  String get brainSuggestionsEmpty => 'No suggestions for this stage yet';

  @override
  String get brainSuggestionsDecideHint =>
      'Nothing applies on its own — review and decide.';

  @override
  String get brainControlUnavailable => 'Unavailable';

  @override
  String get smartSupervisionTitle => 'Smart supervision settings';

  @override
  String get smartSupervisionSubtitle =>
      'Every toggle reads the platform capability table — we never claim what does not work (Screen Time honesty).';

  @override
  String get smartSupervisionHonestyBanner =>
      'Toggles reflect real platform capability. Unavailable stays disabled — it never looks fully ON.';

  @override
  String get smartSupervisionPlatformAndroid => 'Platform: Android';

  @override
  String get smartSupervisionPlatformIos => 'Platform: iOS';

  @override
  String get smartSupervisionWebFilter => 'Web filter';

  @override
  String get smartSupervisionAppLimits => 'App limits';

  @override
  String get smartSupervisionNotificationListen => 'Notification listening';

  @override
  String get smartSupervisionLocationAlways => 'Location always';

  @override
  String get smartSupervisionUnavailableBadge => 'Unavailable on this platform';

  @override
  String get smartSupervisionLimitedBadge => 'Reports only — limited';

  @override
  String get platformMonitoringTitle => 'Platform monitoring';

  @override
  String get platformMonitoringSubtitle =>
      'Each platform × feature shows real capability. Unavailable never looks fully ON (Screen Time honesty).';

  @override
  String get platformMonitoringHonestyBanner =>
      'Disabled claims stay muted and off — mint ON is reserved for full capability only.';

  @override
  String get platformMonitoringLimitedHint =>
      'Limited reports only — not full enforcement.';

  @override
  String get platformMonitoringOfflineBanner =>
      'Offline — showing last known capability matrix (not live OS claims).';

  @override
  String get effectiveMonitoringSectionTitle => 'Monitoring that applies to me';

  @override
  String get effectiveMonitoringChildSubtitle =>
      'This mirrors what your device can actually enforce — not what a parent wished for.';

  @override
  String get effectiveMonitoringEmpty =>
      'No monitoring features are effectively active on your device right now';

  @override
  String get effectiveMonitoringFullBadge => 'Active';

  @override
  String get smartModesTitle => 'Smart modes';

  @override
  String get smartModesSubtitle =>
      'Activate a built-in mode or edit school hours here. School never opens the deleted FAT-039 screen.';

  @override
  String get smartModesHostBanner =>
      'School schedule (S-SEC-058) and activation (S-SEC-059) live on this screen — not the tombstone FAT-039.';

  @override
  String get smartModesListHeading => 'Built-in modes';

  @override
  String get smartModeSleep => 'Sleep';

  @override
  String get smartModeSchool => 'School';

  @override
  String get smartModeStudy => 'Study';

  @override
  String get smartModeRamadan => 'Ramadan';

  @override
  String get smartModeExams => 'Exams';

  @override
  String get smartModeVacation => 'Vacation';

  @override
  String get smartModeCustom => 'Custom';

  @override
  String get smartModeSchoolStart => 'School start';

  @override
  String get smartModeSchoolEnd => 'School end';

  @override
  String get childDayBoardTitle => 'My day board';

  @override
  String get childDayBoardSubtitle =>
      'Your day status updates when a guardian activates a smart mode';

  @override
  String get childDayBoardIdleStatus => 'No smart mode is active right now';

  @override
  String childDayBoardActiveStatus(String modeName) {
    return 'Active mode: $modeName';
  }

  @override
  String childDayBoardModeEnter(String modeName) {
    return 'Entered $modeName mode';
  }

  @override
  String childDayBoardModeExit(String modeName) {
    return '$modeName mode ended';
  }

  @override
  String childDayBoardModeExpiry(String time) {
    return 'Ends around $time';
  }

  @override
  String childDayBoardLastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String childDayBoardOfflineBanner(String time) {
    return 'Offline — showing last synced board ($time). Updates when you reconnect.';
  }

  @override
  String get requestInboxTitle => 'Extra time requests';

  @override
  String get requestInboxEmptyContext => 'extra time requests';

  @override
  String requestInboxRequestedMinutes(int minutes) {
    return 'Requested +$minutes minutes';
  }

  @override
  String get requestInboxGrantLabel => 'Grant minutes';

  @override
  String requestInboxGrantMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String requestInboxCeilingHint(int minutes) {
    return 'Your grant ceiling is $minutes minutes (ADR-039)';
  }

  @override
  String get requestInboxApprove => 'Approve';

  @override
  String get requestInboxReject => 'Reject';

  @override
  String get requestInboxRejectReasonLabel => 'Reason for your child';

  @override
  String get requestInboxRejectReasonHint => 'They will see this reason';

  @override
  String get requestInboxReasonRequired =>
      'Add a reason so your child understands';

  @override
  String get requestInboxObserverHint =>
      'View only — partner, full, or father can decide';

  @override
  String get requestInboxOfflineBanner =>
      'Offline — decisions will sync when you reconnect.';

  @override
  String get requestInboxOfflineQueued => 'Decision queued';

  @override
  String requestInboxChildRejectedReason(String reason) {
    return 'Your request was declined: $reason';
  }

  @override
  String requestInboxChildApproved(int minutes) {
    return 'You received +$minutes extra minutes';
  }

  @override
  String get emptyStateTitle => 'Nothing here yet';

  @override
  String emptyStateMessage(String contextName) {
    return 'When something new happens in “$contextName”, you’ll see it here first.';
  }

  @override
  String get emptyStateDefaultContext => 'this screen';

  @override
  String get emptyStateActionCta => 'OK';

  @override
  String get emergencySetupTitle => 'Emergency setup';

  @override
  String get sosLadderProtocolBanner =>
      'When a child triggers SOS, father and mother are alerted immediately. If unanswered, the alert escalates down this ladder';

  @override
  String get sosReceiptCannotDisableBanner =>
      'SOS receipt cannot be turned off for guardians — mother receives it at every level, including Observer';

  @override
  String get sosLadderSubtitle =>
      'Parents are fixed on rung 1 — they cannot be removed or have emergency alerts turned off';

  @override
  String get sosLadderHeading => 'Approved escalation ladder';

  @override
  String get sosLadderFatherLabel => 'Father';

  @override
  String get sosLadderMotherLabel => 'Mother';

  @override
  String get sosLadderRung1LockedHint => 'Immediate — audible alert, no delay';

  @override
  String get sosLadderMandatoryTag => 'Required';

  @override
  String get sosLadderParentImmovableError =>
      'Parents cannot be removed from rung 1 of the SOS ladder';

  @override
  String get sosLadderAddBackup => 'Add a trusted outside-family contact';

  @override
  String get sosLadderBackupDefaultName => 'Backup contact';

  @override
  String get sosLadderBackupDefaultRelation => 'Trusted';

  @override
  String sosLadderBackupDelay(int seconds) {
    return 'After ${seconds}s with no response';
  }

  @override
  String get myAdvisorTitle => 'My advisor — what it does for me';

  @override
  String get myAdvisorServesBanner =>
      'AI serves — it does not decide. Suggestions only; you always choose (Bark).';

  @override
  String get myAdvisorSuggestionsHeading => 'Advisor suggestions';

  @override
  String get myAdvisorSuggestionsHint =>
      'Approve to create a RulesEngine rule — the suggestion itself never executes.';

  @override
  String get myAdvisorSuggestionsEmpty => 'No pending suggestions';

  @override
  String get myAdvisorMyRulesHeading => 'My rules';

  @override
  String get myAdvisorMyRulesHint =>
      'Deterministic rules the father authored or approved — not AI suggestions.';

  @override
  String get myAdvisorMyRulesEmpty => 'No enabled rules yet';

  @override
  String get myAdvisorApprove => 'Approve';

  @override
  String get myAdvisorReject => 'Reject';

  @override
  String get myAdvisorReadOnlyHint =>
      'View only — rule approval is father-only (A-5).';

  @override
  String get ruleEditorHeading => 'Rule editor — consequents';

  @override
  String get ruleEditorHint =>
      'Choose only allowed automations. Owner-only actions cannot be rules (Bark / ADR-038).';

  @override
  String get ruleEditorSave => 'Save rule';

  @override
  String get ruleEditorForbiddenBlocked =>
      'Blocked — anti-tamper, unlock blocked apps, and delegation edits cannot be rule consequents.';

  @override
  String get ruleConsequentNotifyFather => 'Notify father';

  @override
  String get ruleConsequentGrantMinutes => 'Grant minutes';

  @override
  String get ruleConsequentSoftLock => 'Soft lock';

  @override
  String get childWelcomeTitle => 'Child welcome';

  @override
  String get childWelcomeSubtitle => 'A gentle start';

  @override
  String get childWelcomeHeroEmoji => '🦁';

  @override
  String get childWelcomeHeroSemantics => 'Friendly welcome character';

  @override
  String get childWelcomeHeadline => 'Welcome, champ!';

  @override
  String get childWelcomeBody =>
      'This device will link to your family — so they know you\'re okay, and you can play, learn, and earn play minutes ⏱';

  @override
  String get childWelcomeContinue => 'Let\'s go 🚀';

  @override
  String get childWelcomeContinueSemantics =>
      'Let\'s go — continue to link QR scan';

  @override
  String get childWelcomeParentLeanTitle => 'For the child\'s device';

  @override
  String get childWelcomeParentLeanMessage =>
      'Child welcome is for the child\'s device after mode pick — not part of the parent experience.';

  @override
  String get childQrTitle => 'Scan the code';

  @override
  String get childQrSubtitle => 'From your parent\'s device';

  @override
  String get childQrInstruction =>
      'Point the camera at the code on your parent\'s device';

  @override
  String get childQrScanSemantics => 'Link QR scan frame';

  @override
  String get childQrFatherTokenNote =>
      'Your parent\'s code stays valid until it expires — scanning does not cancel it (UF-01).';

  @override
  String get childQrSimulateScan => 'Scanned ✓ (demo)';

  @override
  String get childQrManualLink => 'Can\'t scan? Enter the code';

  @override
  String get childQrManualHintToast =>
      'Open camera settings, or enter the code manually if camera is permanently denied.';

  @override
  String get childQrRepairTitle => 'Camera permission needed';

  @override
  String get childQrRepairBody =>
      'Scanning needs the camera once to link your device. Open system settings and enable camera for this app — you are not stuck.';

  @override
  String get childQrOpenSettings => 'Open camera settings';

  @override
  String get childQrOpenSettingsToast =>
      'Opening system settings (demo) — enable camera, then return.';

  @override
  String get childQrRetryPermission => 'Try requesting permission again';

  @override
  String get childQrPermanentTitle => 'Camera unavailable — enter the code';

  @override
  String get childQrPermanentBody =>
      'On some devices permission is denied permanently. Open system settings and enable camera, or type the 8-character code shown under your parent\'s screen.';

  @override
  String get childQrManualPlaceholder => 'A1B2-C3D4';

  @override
  String get childQrManualSubmit => 'Link device ✓';

  @override
  String get childQrTokenInvalid =>
      'Invalid code — 8 characters as shown on your parent\'s device (UF-01).';

  @override
  String get transparencyConsentTitle => 'Being honest with you';

  @override
  String get transparencyConsentSubtitle => 'Before we start';

  @override
  String get transparencyConsentHonestyBanner =>
      'We don\'t spy — we check you\'re okay. Here\'s exactly what your parents will know about you:';

  @override
  String get transparencyConsentSharedTitle =>
      '✅ What is shared with your family';

  @override
  String get transparencyConsentSharedLocationTitle => 'Your location';

  @override
  String get transparencyConsentSharedLocationBody =>
      'So they know you\'re safe';

  @override
  String get transparencyConsentSharedScreenTimeTitle =>
      'How long you use the phone';

  @override
  String get transparencyConsentSharedScreenTimeBody =>
      'Total time and app names';

  @override
  String get transparencyConsentSharedBatteryTitle => 'Your device battery';

  @override
  String get transparencyConsentSharedBatteryBody => 'So you stay reachable';

  @override
  String get transparencyConsentNeverTitle => '⛔ What is never read';

  @override
  String get transparencyConsentNeverMessagesTitle =>
      'Your private message text';

  @override
  String get transparencyConsentNeverMessagesBody =>
      'They get a category alert only — not your words';

  @override
  String get transparencyConsentNeverPhotosTitle => 'Your photos and files';

  @override
  String get transparencyConsentNeverPhotosBody =>
      'Their content stays yours — not opened or read';

  @override
  String get transparencyConsentAdvisorTitle => '🧠 One more thing';

  @override
  String get transparencyConsentAdvisorBody =>
      'The app has a smart helper that helps your family understand your day in general — its presence is always announced here and on the Me tab.';

  @override
  String get transparencyConsentAccept => 'I understand and agree ✓';

  @override
  String get transparencyConsentAcceptSemantics =>
      'I understand and agree — continue to My day board';

  @override
  String get transparencyConsentParentLeanTitle => 'For the child\'s device';

  @override
  String get transparencyConsentParentLeanMessage =>
      'Transparency consent is for the child\'s device after linking — not part of the parent experience.';

  @override
  String get dayBoardGreetingSubEmpty =>
      'No children linked yet — add one when you are ready';

  @override
  String get dayBoardEmptyChildrenTitle => 'No children on the board yet';

  @override
  String get dayBoardEmptyChildrenSubtitle =>
      'Link a child device to see live status here. No sample names or minutes.';

  @override
  String get dayBoardEmptyPendingTitle => 'No pending requests';

  @override
  String get dayBoardEmptyPendingSubtitle =>
      'When a child asks for more time, it appears here — not as planted sample copy.';

  @override
  String dayBoardOfflineBanner(String time) {
    return 'Offline — showing last synced board ($time). Updates when you reconnect.';
  }

  @override
  String get dayBoardSyncUnknown => 'unknown';

  @override
  String get plansTitle => 'Plans & subscription';

  @override
  String get manageSubscriptionTitle => 'Manage subscription';

  @override
  String get billingOwnerOnlyDeny =>
      'Subscription is for the family owner only — every member\'s safety stays fully protected.';

  @override
  String get billingSafetyNeverGated =>
      'Permanent safety: SOS, location, and family chat stay free forever — even if a plan expires or renewals stop.';

  @override
  String get billingStatusActive => 'Active';

  @override
  String billingStatusTrial(int days) {
    return 'Trial — $days days left';
  }

  @override
  String get billingStatusExpired => 'Expired — safety still on';

  @override
  String get billingCancelAck =>
      'Renewal stopped — basic safety continues free';

  @override
  String get plansFamilySmartTitle => 'Smart family plan';

  @override
  String get plansFamilySmartSubtitle =>
      'Full family AI + education studio + Quran audio offline for all children.';

  @override
  String get plansFamilySmartPrice => '29 SAR / month for the whole family';

  @override
  String get plansBasicSafetyTitle => 'Always-on basic safety';

  @override
  String get plansBasicSafetySubtitle =>
      'Completely free for life for every family.';

  @override
  String get plansBasicSafetyPrice => 'Free forever';

  @override
  String get plansBasicBulletSos => 'Live location and SOS emergency button';

  @override
  String get plansBasicBulletChat => 'Encrypted family chat and calls';

  @override
  String get plansBasicBulletScreenTime => 'Basic screen-time and instant lock';

  @override
  String get plansRecommended => 'Recommended';

  @override
  String get plansOpenManage => 'Manage subscription';

  @override
  String manageCurrentPlan(String name) {
    return 'Current plan: $name';
  }

  @override
  String get manageAutoRenewOn => 'Auto-renew: on';

  @override
  String get manageAutoRenewOff => 'Auto-renew: off (we will not charge you)';

  @override
  String get manageChangePlan => 'Change or upgrade plan';

  @override
  String get manageCancelRenewal => 'Stop renewal';

  @override
  String get manageCancelSafetyNote =>
      'Stopping renewal never turns off SOS, location, or family chat.';

  @override
  String get timeExpiryTitle => 'Time\'s up — gently';

  @override
  String get timeExpiryHeadline => 'Play time is over for today';

  @override
  String get timeExpiryBody =>
      'You did well today. Your progress and minutes are saved — see you tomorrow rested.';

  @override
  String get timeExpiryExemptBanner =>
      'Family chat and Quran stay open. SOS is always reachable.';

  @override
  String get timeExpiryStillAvailable => 'Still available for you now:';

  @override
  String get timeExpiryChatCta => 'Family chat';

  @override
  String get timeExpiryChatSubtitle =>
      'Talking with your parents is never locked';

  @override
  String get timeExpiryQuranCta => 'Quran & learning';

  @override
  String get timeExpiryQuranSubtitle =>
      'Does not use play time — always available';

  @override
  String get timeExpiryEntertainmentLocked => 'Games & entertainment';

  @override
  String get timeExpiryEntertainmentSubtitle =>
      'Locked until tomorrow or extra time is approved';

  @override
  String get timeExpirySosCta => 'SOS — always reachable';

  @override
  String get deviceHealthSettingsTitle => 'Settings';

  @override
  String get deviceHealthDevicesHeading => 'Devices';

  @override
  String get deviceHealthDevicesSubtitle =>
      'Health, heartbeat, and permissions';

  @override
  String get deviceHealthSectionAtRiskHint => 'A device may drop';

  @override
  String get deviceHealthStatusHealthy => 'Healthy';

  @override
  String get deviceHealthStatusAtRisk => 'May disconnect';

  @override
  String get deviceHealthStatusOffline => 'Offline';

  @override
  String deviceHealthLastBeat(String ago) {
    return 'Last beat $ago ago';
  }

  @override
  String deviceHealthBattery(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get deviceHealthOfflineLastKnown =>
      'Showing last known health — device is offline now';

  @override
  String get deviceHealthDetailTitle => 'Device detail';

  @override
  String get deviceHealthDeviceMissing => 'Device not found';

  @override
  String get deviceHealthPermissionsHeading => 'Permission status';

  @override
  String get deviceHealthPermLocation => 'Location all the time';

  @override
  String get deviceHealthPermAccessibility => 'Accessibility';

  @override
  String get deviceHealthPermBattery => 'Battery exemption';

  @override
  String get deviceHealthPermAutoStart => 'Auto-start';

  @override
  String get deviceHealthPermGranted => 'Granted';

  @override
  String get deviceHealthPermDenied => 'Denied';

  @override
  String get deviceHealthPermOsBlocked => 'Blocked by OS';

  @override
  String get deviceHealthOsBlockedHint =>
      'Blocked by the device OS — not a parent rejection';

  @override
  String get deviceHealthPermanentExplain =>
      'Some permissions are blocked by the device OS. Open settings, fix them manually, then return — we re-check without reinstalling the app.';

  @override
  String get deviceHealthRepairCta => 'Fix what\'s broken';

  @override
  String get deviceHealthOpenSettingsToast =>
      'Opened system settings on the device (simulated)';

  @override
  String deviceHealthOemBanner(String oem) {
    return '$oem devices need a special step — battery saver kills protection minutes after the screen turns off.';
  }

  @override
  String get deviceHealthGuideHeading => 'So the device stays connected to you';

  @override
  String get deviceHealthGuideStep1 => 'Settings → Apps → Family OS';

  @override
  String get deviceHealthGuideStep2 => 'Enable Auto-start';

  @override
  String get deviceHealthGuideStep3 => 'Battery → No restrictions';

  @override
  String get deviceHealthOpenSettingsNowCta => 'Open settings now';

  @override
  String get deviceHealthOpenSettingsNowToast =>
      'Opened the correct settings screen on the device (simulated Intent)';

  @override
  String get deviceHealthRepairRequestToast =>
      'Sent a repair request for the device with the guide (simulated)';

  @override
  String get deviceHealthChildLeanTitle => 'For parents';

  @override
  String get deviceHealthChildLeanMessage =>
      'Device health detail is for parents — your settings appear in the Me tab.';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonHonestyBanner =>
      'Post-launch roadmap — we build with care, without promising ship dates.';

  @override
  String get comingSoonSectionHeading => 'What we are preparing for you';

  @override
  String get comingSoonSectionHint => 'Names only — not working settings yet.';

  @override
  String get comingSoonTag => 'Coming soon';

  @override
  String get comingSoonNotSettingsBanner =>
      'These are not ready controls. Nothing here can be turned on or off.';

  @override
  String get comingSoonFeatureRouterFilter => 'Home router filtering';

  @override
  String get comingSoonFeatureRouterFilterSub =>
      'Network-level filtering when it is ready';

  @override
  String get comingSoonFeatureRoadSafety => 'Road safety';

  @override
  String get comingSoonFeatureRoadSafetySub =>
      'Incidents, driving, and phone-while-driving alerts';

  @override
  String get comingSoonFeaturePeerCompare => 'Peer comparison';

  @override
  String get comingSoonFeaturePeerCompareSub =>
      'Anonymous and reassuring insights';

  @override
  String get comingSoonFeatureChoreAi => 'Smart chore distributor';

  @override
  String get comingSoonFeatureChoreAiSub =>
      'Fair task sharing across the family';

  @override
  String get comingSoonFeatureVoiceAdvisor =>
      'Voice conversation with the family advisor';

  @override
  String get comingSoonFeatureVoiceAdvisorSub =>
      'Talk with the advisor when speech is ready';

  @override
  String get comingSoonFeaturePhasedProject => 'Phased family project';

  @override
  String get comingSoonFeaturePhasedProjectSub =>
      'Studio projects broken into stages';

  @override
  String get comingSoonFeatureSmartRecitation => 'Smart child recitation';

  @override
  String get comingSoonFeatureSmartRecitationSub =>
      'Recitation support from the child’s view';

  @override
  String get comingSoonFeatureDelegatedAgent => 'Delegated agent';

  @override
  String get comingSoonFeatureDelegatedAgentSub =>
      'Bounded automation with audit and undo';

  @override
  String get spineCtaSosSemantics => 'Send SOS emergency alert';

  @override
  String get spineCtaLockSemantics => 'Lock child device now';

  @override
  String get spineCtaUnlockSemantics => 'Unlock child device';

  @override
  String get spineCtaApproveSemantics => 'Approve extra-time request';

  @override
  String get spineCtaRejectSemantics => 'Reject extra-time request';

  @override
  String spineCtaGrantMinutesSemantics(int minutes) {
    return 'Grant $minutes minutes';
  }

  @override
  String get requestInboxBackSemantics => 'Back from request inbox';

  @override
  String get sosLadderBackupRemoveSemantics =>
      'Remove SOS ladder backup contact';

  @override
  String get advisorSuggestionsTitle => 'Family advisor suggestions';

  @override
  String get advisorSuggestionsServesBanner =>
      'Family advisor suggests — you decide. Nothing applies on its own. (AI Serves, Not Decides)';

  @override
  String get advisorSuggestionsSeal => 'Family advisor seal';

  @override
  String get advisorSuggestionsApprove => 'Approve';

  @override
  String get advisorSuggestionsReject => 'Reject';

  @override
  String get advisorSuggestionsApproveConfirmTitle => 'Add to My rules?';

  @override
  String get advisorSuggestionsApproveConfirmBody =>
      'Approving creates a RulesEngine rule. The suggestion itself never runs automatically — you decide.';

  @override
  String get advisorSuggestionsApproveConfirmAction => 'Yes, add to rules';

  @override
  String get advisorSuggestionsApproveCancel => 'Cancel';

  @override
  String get advisorSuggestionsReadOnlyHint =>
      'View only — suggestion approval is father-only (A-5).';

  @override
  String get advisorSuggestionsEmptyTitle => 'No suggestions yet';

  @override
  String get advisorSuggestionsEmptyMessage =>
      'When the family advisor has an idea, it appears here — you choose approve or reject.';

  @override
  String get advisorSuggestionsPrivacyFooter =>
      'Stages 1–2 run on-device — full privacy, free';

  @override
  String get advisorSuggestionsListSemantics =>
      'Family advisor suggestions list';

  @override
  String get childrenListTitle => 'My children';

  @override
  String get childrenListAddChild => '+ Add child';

  @override
  String childrenListTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get childrenListHealthExcellent => 'Excellent';

  @override
  String get childrenListHealthAtRisk => 'May disconnect';

  @override
  String get childrenListSharedPoliciesTitle =>
      'Shared settings for all children';

  @override
  String get childrenListSharedPoliciesSubtitle =>
      'One rule for everyone — individual overrides win (your constitution)';

  @override
  String get childrenListSharedSheetTitle => 'Shared settings';

  @override
  String get childrenListSharedHonesty =>
      'Applies to whom you choose — any later individual setting overrides and shows as an exception.';

  @override
  String get childrenListSharedScopeLabel => 'Applies to:';

  @override
  String get childrenListSharedScopeAll => 'Everyone';

  @override
  String get childrenListSharedScopeSome => 'Selected children';

  @override
  String get childrenListSharedDailyCap => 'Shared daily limit';

  @override
  String childrenListSharedDailyCapValue(int hours) {
    return '$hours hours';
  }

  @override
  String get childrenListSharedBedtime => 'Shared bedtime';

  @override
  String get childrenListSharedWebFilter => 'Web filter';

  @override
  String get childrenListSharedWebFilterHint => 'One level for everyone';

  @override
  String get childrenListSharedExceptionsTitle =>
      'Active individual exceptions (override shared)';

  @override
  String get childrenListSharedExceptionsBody =>
      'Any individual limit on a child profile overrides the shared rule — applying to everyone does not erase exceptions.';

  @override
  String get childrenListSharedApply => 'Apply to everyone ✓';

  @override
  String get childrenListEmptyTitle => 'No children yet';

  @override
  String get childrenListEmptyMessage =>
      'Add a child to see status, location, and screen time here — the list stays empty until a device is linked.';

  @override
  String get childrenListChildLeanTitle => 'For parents';

  @override
  String get childrenListChildLeanMessage =>
      'The children list is a parent surface for following the family — not part of the child experience.';

  @override
  String get childrenListLoadingSemantics => 'Loading children list';

  @override
  String get childrenListListSemantics => 'Children list';

  @override
  String childrenListRowSemantics(
    String name,
    String age,
    String location,
    String battery,
    String health,
  ) {
    return '$name, $age, $location, battery $battery, health $health';
  }

  @override
  String get childProfileTitle => 'Child profile';

  @override
  String childProfileNameAge(String name, String age) {
    return '$name — $age';
  }

  @override
  String get childProfileStatusOk => 'Everything looks fine';

  @override
  String get childProfileStatusAtRisk => 'Connection may drop';

  @override
  String get childProfileMetricBattery => 'Battery';

  @override
  String get childProfileMetricConnection => 'Connection';

  @override
  String get childProfileMetricLocation => 'Location';

  @override
  String get childProfileMetricWallet => 'Wallet';

  @override
  String childProfileTodayUsage(String used, String cap) {
    return 'Today: $used of $cap';
  }

  @override
  String get childProfileToolsTitle => 'Child tools';

  @override
  String get childProfileToolsBadge => 'This child only';

  @override
  String get childProfileToolsHint =>
      'Everything you set here applies to this child only — each child has independent settings';

  @override
  String get childProfileToolScreenTime => 'Screen time';

  @override
  String get childProfileToolTimeRequests => 'Time requests';

  @override
  String get childProfileToolWebFilter => 'Web filter';

  @override
  String get childProfileToolInstantLock => 'Instant lock';

  @override
  String get childProfileToolSmartSupervision => 'Supervision';

  @override
  String get childProfileToolDeviceHealth => 'Device health';

  @override
  String get childProfileLocationTitle => 'Live location';

  @override
  String childProfileLocationSummary(
    String location,
    String seen,
    String battery,
  ) {
    return '📍 $location · $seen · 🔋 $battery';
  }

  @override
  String get childProfileDetailsLink => 'Details ‹';

  @override
  String get childProfileConnectionTitle => 'Connection health';

  @override
  String childProfileConnectionBody(String heartbeat) {
    return 'Last heartbeat: $heartbeat · all permissions granted.';
  }

  @override
  String get childProfileDeviceDetailsLink => 'Device details ‹';

  @override
  String get childProfileMissingIdTitle => 'Choose a child first';

  @override
  String get childProfileMissingIdMessage =>
      'Open a child profile from the children list — a profile is not shown without a child id.';

  @override
  String get childProfileSelectChildTitle => 'Select a child';

  @override
  String get childProfileSelectChildMessage =>
      'Pick a child in this family to open their profile and device enrollment.';

  @override
  String get childProfileSelectChildEmpty =>
      'No children in this family yet — add a child first.';

  @override
  String get childProfileSelectChildSemantics => 'Open profile for this child';

  @override
  String get childProfileAddDevice => '+ Add device';

  @override
  String get childProfileMaxDevicesBlock =>
      'This child already has 3 enrolled devices — revoke one before pairing another.';

  @override
  String get enrollmentStatePairingPending => 'Pairing pending';

  @override
  String get enrollmentStateEnrolled => 'Enrolled';

  @override
  String get enrollmentStateRevoked => 'Revoked';

  @override
  String get enrollmentStateLost => 'Marked lost';

  @override
  String get enrollmentStateDecommissioned => 'Decommissioned';

  @override
  String get enrollmentStateUnenrolled => 'Unenrolled';

  @override
  String get enrollmentShowPairingCode => 'Show pairing code';

  @override
  String get enrollmentFailureMaxDevices =>
      'Enrollment blocked — max 3 active devices for this child.';

  @override
  String get enrollmentFailureInvalidToken =>
      'This pairing code is invalid, expired, or already used.';

  @override
  String get enrollmentFailureGeneric => 'Enrollment could not be completed.';

  @override
  String get pairingVerificationTitle => 'Verifying pairing';

  @override
  String get pairingVerificationMessage =>
      'Checking the pairing code against a pending enrollment — enrollment is not complete until verification succeeds.';

  @override
  String get enrollmentProgressTitle => 'Enrollment in progress';

  @override
  String get enrollmentProgressMessage =>
      'Pairing was verified. Completing enrollment for this device…';

  @override
  String get inviteLifecyclePending => 'Invite pending';

  @override
  String get inviteLifecycleActive => 'Invite active';

  @override
  String get inviteLifecycleAccepted => 'Invite accepted';

  @override
  String get inviteLifecycleExpired => 'Invite expired';

  @override
  String get inviteLifecycleRevoked => 'Invite revoked';

  @override
  String get deviceHealthManageEnrollment => 'Manage enrollment';

  @override
  String get deviceHealthManageEnrollmentSub =>
      'Revoke, re-pair, or set primary on the child profile — health stays observational.';

  @override
  String get linkQrSelectChildTitle => 'Choose whose device to pair';

  @override
  String get linkQrSelectChildMessage =>
      'Pairing needs a child in the active family. Select one to issue a pairing code.';

  @override
  String get linkQrAwaitingClaim =>
      'Waiting for the child device to scan — enrollment stays pending until claim succeeds.';

  @override
  String get linkQrReturnToProfile => 'Return to child profile';

  @override
  String get childProfileNotFoundTitle => 'Child not found';

  @override
  String get childProfileNotFoundMessage =>
      'No child with this id is in the family — go back to the children list and pick a linked child.';

  @override
  String get childProfileChildLeanTitle => 'For parents';

  @override
  String get childProfileChildLeanMessage =>
      'The child profile is a parent surface for following and configuring a child — not part of the child experience.';

  @override
  String get childProfileLoadingSemantics => 'Loading child profile';

  @override
  String get childProfileToolsSemantics => 'Child settings tools';

  @override
  String childProfileIdentitySemantics(String name, String age, String status) {
    return '$name, $age, status $status';
  }

  @override
  String get locationMapTitle => 'Where are my kids?';

  @override
  String get locationMapHonestyBanner =>
      'Location and safe zones are geographic peace-of-mind (Life360-style) — not a substitute for screen time or content filtering.';

  @override
  String get locationMapEmptyTitle => 'No locations yet';

  @override
  String get locationMapEmptyMessage =>
      'Link a child device to see live location and safe zones here — no planted names or coordinates.';

  @override
  String get locationMapNotFoundTitle => 'Child not found';

  @override
  String get locationMapNotFoundMessage =>
      'No child with this id appears on the map — return to the children list and pick a linked child.';

  @override
  String get locationMapChildLeanTitle => 'For parents';

  @override
  String get locationMapChildLeanMessage =>
      'The location map is a parent surface for following kids — not part of the child experience.';

  @override
  String get locationMapLoadingSemantics => 'Loading location map';

  @override
  String get locationMapCanvasSemantics =>
      'Live map of children locations and safe zones';

  @override
  String locationMapPinTitle(String name, String place) {
    return '$name — $place';
  }

  @override
  String locationMapPinSubtitle(String seen, String battery) {
    return '$seen · 🔋 $battery';
  }

  @override
  String locationMapPinSubtitleInZone(
    String zone,
    String seen,
    String battery,
  ) {
    return 'Inside “$zone” · $seen · 🔋 $battery';
  }

  @override
  String get locationMapHistoryLink => 'History →';

  @override
  String locationMapThreadTitle(String name) {
    return '🧵 $name\'s day thread';
  }

  @override
  String get locationMapFullHistoryLink => 'Full history ‹';

  @override
  String get locationMapSafeZonesCta => '🛡️ Safe zones';

  @override
  String get locationMapSafeZonesSemantics => 'Open safe zones list';

  @override
  String get locationMapLandmarkHome => 'Our home';

  @override
  String get locationMapLandmarkSchool => 'School';

  @override
  String get locationMapLandmarkPark => 'Neighborhood park';

  @override
  String get locationMapLandmarkClub => 'Neighborhood club';

  @override
  String get locationMapLandmarkMosque => 'Neighborhood mosque';

  @override
  String get locationMapLandmarkStreet => 'Neighborhood street';

  @override
  String get locationHistoryTitle => 'Location history';

  @override
  String locationHistoryThreadTitle(String name) {
    return '$name\'s day thread';
  }

  @override
  String get locationHistoryHonestyBanner =>
      'Location history is geographic peace-of-mind (Life360-style) — not a substitute for screen time or content filtering.';

  @override
  String get locationHistoryMissingIdTitle => 'Pick a child first';

  @override
  String get locationHistoryMissingIdMessage =>
      'Open history from the live map or child profile — no planted names on this screen.';

  @override
  String get locationHistoryEmptyTitle => 'No history yet';

  @override
  String get locationHistoryEmptyMessage =>
      'When the device moves, today\'s places will appear here — no planted timeline.';

  @override
  String get locationHistoryNotFoundTitle => 'Child not found';

  @override
  String get locationHistoryNotFoundMessage =>
      'No child with this id appears in history — return to the map and pick a linked child.';

  @override
  String get locationHistoryChildLeanTitle => 'For parents';

  @override
  String get locationHistoryChildLeanMessage =>
      'Location history is a parent surface for following kids\' movement — not part of the child experience.';

  @override
  String get locationHistoryLoadingSemantics => 'Loading location history';

  @override
  String get locationHistoryOpenMapCta => 'Open location map';

  @override
  String locationHistoryFrequentTitle(String name) {
    return '📍 $name\'s frequent places';
  }

  @override
  String get locationHistoryFrequentNewBadge => 'New';

  @override
  String get locationHistoryPlaceRegular => 'Regular';

  @override
  String get locationHistoryPlaceNovel => 'New';

  @override
  String get locationHistoryFrequentHint =>
      'Learned automatically — a new place is a conversation cue, not an accusation.';

  @override
  String get locationHistoryRetentionNote =>
      'History is kept for 90 days, then deleted automatically — mandatory prune policy.';

  @override
  String get safeZonesTitle => 'Safe zones';

  @override
  String get safeZonesHonestyBanner =>
      'Safe zones are geographic peace-of-mind (Life360-style) — not a substitute for screen time or content filtering.';

  @override
  String get safeZonesReadOnlyBanner =>
      '🔒 View only — editing zones needs «Full» level. You can always see kids\' locations.';

  @override
  String get safeZonesSectionTitle => 'Family-approved zones';

  @override
  String get safeZonesAddHeaderCta => '+ Add zone';

  @override
  String get safeZonesAddHeaderSemantics => 'Add a new safe zone';

  @override
  String get safeZonesDrawCta => '+ Draw a new safe zone on the map';

  @override
  String get safeZonesDrawSemantics => 'Draw a new safe zone on the map';

  @override
  String get safeZonesEmptyTitle => 'No safe zones yet';

  @override
  String get safeZonesEmptyMessage =>
      'Draw the first zone on the map to get arrival and departure alerts — no planted zones.';

  @override
  String get safeZonesEmptyCta => 'Draw a safe zone';

  @override
  String get safeZonesChildLeanTitle => 'For parents';

  @override
  String get safeZonesChildLeanMessage =>
      'Safe zones are a parent surface for geographic peace-of-mind — not part of the child experience.';

  @override
  String get safeZonesLoadingSemantics => 'Loading safe zones';

  @override
  String safeZonesAlertSubtitle(String desc) {
    return '$desc · arrival and departure alerts';
  }

  @override
  String safeZonesSwitchSemantics(String name) {
    return 'Arrival and departure alerts for $name';
  }

  @override
  String get safeZonesAppliesNote =>
      'Applies to all children — per-child alert tuning lives on each profile.';

  @override
  String get createSafeZoneTitle => 'Create safe zone';

  @override
  String get createSafeZoneDrawBanner =>
      '✍️ Draw it yourself: tap the map for the zone center, drag to move it, then set size with the slider.';

  @override
  String get createSafeZoneHonestyBanner =>
      'Safe zones are geographic peace-of-mind (Life360-style) — not a substitute for screen time or content filtering.';

  @override
  String get createSafeZoneReadOnlyBanner =>
      '🔒 View only — drawing zones needs «Full» level. You can always see kids\' locations.';

  @override
  String get createSafeZoneTapHint => '👆 Tap here to place the zone center';

  @override
  String get createSafeZoneCenterPlaced =>
      '✓ Center placed — drag it on the map to adjust';

  @override
  String get createSafeZoneMapSemantics =>
      'Map for drawing a safe zone — tap to place center, drag to move';

  @override
  String createSafeZoneRadiusLabel(String meters) {
    return 'Radius — $meters m (updates live on the map)';
  }

  @override
  String get createSafeZoneRadiusSemantics => 'Safe zone radius';

  @override
  String get createSafeZoneNameLabel => 'Zone name';

  @override
  String get createSafeZoneNameHint => 'Neighborhood club';

  @override
  String get createSafeZoneAlertsHeading => 'Alert me on';

  @override
  String get createSafeZoneAlertArrival => 'Arrival';

  @override
  String get createSafeZoneAlertDeparture => 'Departure';

  @override
  String get createSafeZoneAlertNoShow => 'No-show on schedule';

  @override
  String get createSafeZoneAlertNoShowHint =>
      'Example: did not reach school by 7:30 AM';

  @override
  String get createSafeZoneSaveCta => 'Save safe zone →';

  @override
  String get createSafeZoneSaveSemantics => 'Save safe zone and return to list';

  @override
  String get createSafeZoneAppliesNote =>
      'Applies to all children — per-child alert tuning lives on each profile';

  @override
  String get createSafeZoneNeedCenter =>
      '👆 Place the zone center on the map first';

  @override
  String createSafeZoneSavedToast(String name) {
    return 'Safe zone «$name» saved ✓';
  }

  @override
  String createSafeZoneRadiusDesc(String meters) {
    return 'Radius $meters m';
  }

  @override
  String get createSafeZoneChildLeanTitle => 'For parents';

  @override
  String get createSafeZoneChildLeanMessage =>
      'Drawing safe zones is a parent surface — not part of the child experience.';

  @override
  String get createSafeZonePinSemantics => 'Safe zone center';

  @override
  String get sosAlertTitle => 'SOS alert';

  @override
  String sosAlertHeadline(String name) {
    return '$name needs help';
  }

  @override
  String get sosAlertSirenBanner =>
      'SOS alert is open — channels below show honest delivery status';

  @override
  String get sosAlertLiveBroadcastNote =>
      'Incident open — location and delivery are reported honestly (no silent success)';

  @override
  String get sosAlertAutoCallPending =>
      'Call capability: NOT_CONFIGURED in this build';

  @override
  String sosAlertMetaLine(
    String location,
    String battery,
    String movement,
    String accuracy,
  ) {
    return '📍 $location\n🔋 $battery% · $movement · accuracy ± $accuracy m';
  }

  @override
  String sosAlertCallNowCta(String name) {
    return '📞 Call $name now (emergency call)';
  }

  @override
  String get sosAlertCallNowSemantics =>
      'Place an immediate emergency call to the child';

  @override
  String get sosAlertLiveMapCta => '🗺️ Open precise live location on the map';

  @override
  String get sosAlertLiveMapSemantics => 'Open the live location map';

  @override
  String get sosAlertResolveCta =>
      '✓ I reached them — resolve and close the alert';

  @override
  String get sosAlertResolveSemantics =>
      'Close the SOS alert after checking in';

  @override
  String get sosAlertEscalateCta => '🚨 Alert emergency contacts';

  @override
  String get sosAlertEscalateSemantics =>
      'Escalate the alert to emergency contacts';

  @override
  String sosAlertRecipientsFooter(String names) {
    return 'Recipients: $names — SOS is never paywalled';
  }

  @override
  String get sosAlertP4NeverGated =>
      'SOS is never muted or paywalled — every guardian always receives it';

  @override
  String get sosAlertMapSemantics => 'Live location map during an SOS alert';

  @override
  String sosAlertPinSemantics(String name) {
    return '$name live location';
  }

  @override
  String get sosAlertEmptyTitle => 'No active SOS alert';

  @override
  String get sosAlertEmptyMessage =>
      'When your child presses SOS, the alert appears here instantly — piercing siren and live map.';

  @override
  String get sosAlertErrorTitle => 'Couldn’t load the alert';

  @override
  String get sosAlertErrorMessage =>
      'Try again — SOS does not depend on this screen alone.';

  @override
  String get sosAlertChildLeanTitle => 'For parents';

  @override
  String get sosAlertChildLeanMessage =>
      'The SOS alert board is for parents — your SOS button lives in the child app.';

  @override
  String get sosAlertSetupCta => 'Emergency ladder setup →';

  @override
  String get sosAlertSetupSemantics => 'Open emergency setup';

  @override
  String get sosAlertResolvedToast =>
      '✓ Alhamdulillah — alert closed, check-in recorded in the safety log';

  @override
  String get sosAlertEscalatedToast =>
      'Escalation requested — delivery status stays honest per channel';

  @override
  String get sosAlertCallStartedToast =>
      'Calling is not configured yet — alert stays active';

  @override
  String get alertsHubTitle => 'Alerts';

  @override
  String get alertsHubHonestyBanner =>
      'Three urgency tiers — mute protection · 🔴 act now · 🟡 look · 🟢 peace of mind';

  @override
  String get alertsHubP4Banner =>
      'Critical alerts and SOS are never muted by quiet hours — they always arrive';

  @override
  String get alertsHubSectionCritical => '🔴 Needs you now';

  @override
  String get alertsHubSectionAttention => '🟡 Deserves a look';

  @override
  String get alertsHubSectionReassurance => '🟢 For peace of mind';

  @override
  String alertsHubCount(int count) {
    return '$count';
  }

  @override
  String get alertsHubEmptyTitle => 'No alerts right now';

  @override
  String get alertsHubEmptyMessage =>
      'When monitoring raises an alert it appears here by urgency — excerpt only, never an archive.';

  @override
  String get alertsHubLoadingSemantics => 'Loading alerts hub';

  @override
  String get alertsHubChildLeanTitle => 'For parents';

  @override
  String get alertsHubChildLeanMessage =>
      'The alerts hub is a parent surface — your check-ins show there by urgency.';

  @override
  String get alertDetailTitle => 'Alert detail';

  @override
  String get alertDetailHonestyBanner =>
      'Category + severity + advice — never raw message text (Bark-style honesty)';

  @override
  String get alertDetailP4Banner =>
      'SOS and critical alerts are never muted by quiet hours — they always arrive';

  @override
  String get alertDetailUrgencyCritical => '🔴 High';

  @override
  String get alertDetailUrgencyAttention => '🟡 Look';

  @override
  String get alertDetailUrgencyReassurance => '🟢 Peace of mind';

  @override
  String get alertDetailCategoryStranger => 'Category: stranger contact';

  @override
  String get alertDetailCategoryDevice => 'Category: device status';

  @override
  String get alertDetailCategoryScreenTime => 'Category: screen time';

  @override
  String get alertDetailCategorySafeArrival => 'Category: safe arrival';

  @override
  String get alertDetailAdvicePrefix => '🧠 Family advisor tip:';

  @override
  String get alertDetailToneSectionTitle => 'Tone-safe replies';

  @override
  String get alertDetailBlockCta => 'Block this number';

  @override
  String get alertDetailRequestBlockCta => 'Ask the rule holder to block';

  @override
  String get alertDetailRequestBlockToast =>
      'The rule holder was notified of your block request';

  @override
  String get alertDetailBlockDoneBanner =>
      '✓ Number blocked on the child\'s device — you got confirmation; nothing harsh showed to the child';

  @override
  String get alertDetailSendReminderCta => 'Send a gentle reminder';

  @override
  String get alertDetailReminderDoneBanner =>
      '✓ Gentle reminder sent to the child';

  @override
  String get alertDetailOpenChatCta => 'Open chat';

  @override
  String get alertDetailReviewScreenTimeCta => 'Review screen time';

  @override
  String get alertDetailDismissCta => 'Dismiss this time';

  @override
  String get alertDetailDismissDoneBanner =>
      '✓ Dismissed this time — nothing deducted';

  @override
  String get alertDetailSendHeartCta => 'Send ❤️';

  @override
  String get alertDetailHeartDoneBanner =>
      '✓ Your heart reached the child — joy received';

  @override
  String get alertDetailShowOnMapCta => 'Show on map';

  @override
  String get alertDetailEmptyTitle => 'No alert selected';

  @override
  String get alertDetailEmptyMessage =>
      'Alert detail opens from the alerts hub only — pick an alert to see its category and severity.';

  @override
  String get alertDetailNotFoundTitle => 'Alert not found';

  @override
  String get alertDetailNotFoundMessage =>
      'We could not find this alert — it may have been closed or expired.';

  @override
  String get alertDetailLoadingSemantics => 'Loading alert detail';

  @override
  String get alertDetailChildLeanTitle => 'For parents';

  @override
  String get alertDetailChildLeanMessage =>
      'Alert detail is a parent surface — your check-ins reach them as category and severity, never raw text.';

  @override
  String get conversationsListTitle => 'Family';

  @override
  String get conversationsListHonestyBanner =>
      'Fixed right: family chat is never limited by any plan tier — encrypted and always available';

  @override
  String get conversationsListSectionTitle => 'Conversations';

  @override
  String get conversationsListNewChatCta => '+ New chat';

  @override
  String get conversationsListNewChatToast =>
      'New chat — coming soon (Stage 1)';

  @override
  String get conversationsListEmptyTitle => 'No conversations yet';

  @override
  String get conversationsListEmptyMessage =>
      'When a family chat starts it appears here — the family thread stays pinned and is never gated.';

  @override
  String get conversationsListLoadingSemantics => 'Loading conversations list';

  @override
  String get conversationsListChildLeanTitle => 'For parents';

  @override
  String get conversationsListChildLeanMessage =>
      'This is the parents\' conversations list — your family chats appear in your Family tab.';

  @override
  String get conversationTitle => 'Conversation';

  @override
  String get conversationEncryptedTag => '🔒 End-to-end encrypted';

  @override
  String get conversationSettingsTag => '⚙️ Chat settings';

  @override
  String get conversationSettingsToast =>
      'Chat settings — coming soon (Stage 1)';

  @override
  String get conversationFamilyPinNote =>
      '📌 Family chat stays pinned — a fixed right never limited by any plan';

  @override
  String get conversationToneBridgeNote =>
      '💜 Tone bridge — warm replies are always ready';

  @override
  String get conversationInputHint => 'Write a message…';

  @override
  String get conversationSendSemantics => 'Send message';

  @override
  String get conversationSentNow => 'Now';

  @override
  String get conversationAttachSemantics => 'Attach photo, voice, or file';

  @override
  String get conversationAttachToast =>
      '📎 Share a photo, recording, or file — family circle only';

  @override
  String get conversationEmptyTitle => 'Start the conversation';

  @override
  String get conversationEmptyMessage =>
      'No messages yet — write the first one below. Chat is a fixed right never limited by any plan.';

  @override
  String get conversationMissingPeerTitle => 'Pick a conversation';

  @override
  String get conversationMissingPeerMessage =>
      'Open a chat from the family list to see messages.';

  @override
  String get conversationNotFoundTitle => 'Conversation not found';

  @override
  String get conversationNotFoundMessage =>
      'This peer is not in family conversations yet.';

  @override
  String get conversationLoadingSemantics => 'Loading conversation';

  @override
  String get conversationChildLeanTitle => 'For parents';

  @override
  String get conversationChildLeanMessage =>
      'This is a parent conversation — your family chats appear in your Family tab.';

  @override
  String get activeCallTitle => 'Active call';

  @override
  String activeCallStatusActive(String elapsed) {
    return 'Active · $elapsed';
  }

  @override
  String get activeCallMuteSemantics => 'Mute microphone';

  @override
  String get activeCallUnmuteSemantics => 'Unmute microphone';

  @override
  String get activeCallSpeakerSemantics => 'Speaker';

  @override
  String get activeCallVideoSemantics => 'Camera';

  @override
  String get activeCallEndSemantics => 'End call';

  @override
  String get activeCallMuteOnToast => '🔇 Mic muted — tap again to unmute';

  @override
  String get activeCallMuteOffToast => '🎙 Mic back on';

  @override
  String get activeCallSpeakerOnToast => '🔊 Speaker on';

  @override
  String get activeCallSpeakerOffToast => '🔈 Speaker off';

  @override
  String activeCallCameraOnToast(String name) {
    return '📹 Camera on — $name can see you now';
  }

  @override
  String get activeCallCameraOffToast => '📷 Camera off';

  @override
  String get activeCallHonestyNote =>
      'Audio & video via LiveKit — metadata only, never recorded · 🔔 Check-in calls ring on the child\'s device even when silent';

  @override
  String get activeCallPlayTogetherTitle => '🎮 Play together during the call';

  @override
  String get activeCallDrawTitle => 'Shared drawing board';

  @override
  String get activeCallDrawSubtitle =>
      'Draw together in the same moment — close the distance';

  @override
  String get activeCallDrawCta => 'Open';

  @override
  String get activeCallDrawToast =>
      '🎨 Shared board opened — strokes sync live';

  @override
  String get activeCallXoTitle => 'Quick tic-tac-toe';

  @override
  String get activeCallXoSubtitle => 'A light round while you talk';

  @override
  String get activeCallXoCta => 'Play';

  @override
  String get activeCallXoToast => '❌⭕ Round started — their turn first';

  @override
  String get activeCallMissingIdTitle => 'No active call';

  @override
  String get activeCallMissingIdMessage =>
      'Open a call from the call log or a family conversation.';

  @override
  String get activeCallNotFoundTitle => 'Call not found';

  @override
  String get activeCallNotFoundMessage => 'This id is not in family calls yet.';

  @override
  String get activeCallLoadingSemantics => 'Loading call';

  @override
  String get activeCallChildLeanTitle => 'For parents';

  @override
  String get activeCallChildLeanMessage =>
      'This is a parent call — your family calls appear in your Family tab.';

  @override
  String get callHistoryTitle => 'Calls';

  @override
  String get callHistoryHonestyBanner =>
      'Metadata only — never recorded · Quick redial or a love message from the log';

  @override
  String get callHistoryDirectionOutgoing => '↗ Outgoing';

  @override
  String get callHistoryDirectionIncoming => '↙ Incoming';

  @override
  String get callHistoryDirectionMissed => '↙ Missed';

  @override
  String get callHistoryDirectionOutgoingVideo => '↗ Outgoing video';

  @override
  String get callHistoryRedialSemantics => 'Redial';

  @override
  String get callHistoryDialToast => 'New call — coming soon (Stage 1)';

  @override
  String get callHistoryEmptyTitle => 'No calls yet';

  @override
  String get callHistoryEmptyMessage =>
      'Family calls appear here — incoming, outgoing, and missed with quick redial.';

  @override
  String get callHistoryLoadingSemantics => 'Loading call history';

  @override
  String get callHistoryChildLeanTitle => 'For parents';

  @override
  String get callHistoryChildLeanMessage =>
      'This is the parent call log — your family calls appear in your Family tab.';

  @override
  String get settingsHubTitle => 'Settings';

  @override
  String get settingsHubChildLeanTitle => 'For parents';

  @override
  String get settingsHubChildLeanMessage =>
      'Family settings are for parents — your own settings appear in the Me tab.';

  @override
  String get settingsHubSectionFamily => 'Family';

  @override
  String get settingsHubSectionEmergency => 'Emergency';

  @override
  String get settingsHubSectionPrivacy => 'Intelligence & privacy';

  @override
  String get settingsHubSectionGeneral => 'General';

  @override
  String get settingsHubSectionComingSoon => 'Coming soon';

  @override
  String get settingsHubRowFamilyMembers => 'Family members';

  @override
  String get settingsHubRowFamilyMembersSub => 'Roles and invites';

  @override
  String get settingsHubRowMotherShare => 'Mother sharing level';

  @override
  String get settingsHubRowMotherShareSub => 'How much mother can share';

  @override
  String get settingsHubRowParentModeRequests => 'Parent-mode unlock requests';

  @override
  String get settingsHubRowLinkDevice => 'Link a new device';

  @override
  String get settingsHubRowLinkDeviceSub => 'QR code — one device per child';

  @override
  String get settingsHubRowEmergency => 'Emergency setup';

  @override
  String get settingsHubRowEmergencySub => 'Rescue contacts and SOS button';

  @override
  String get settingsHubRowBrain => 'Family advisor limits & powers';

  @override
  String get settingsHubRowBrainSub => 'What it can and cannot see';

  @override
  String get settingsHubRowAdvisor => 'My AI assistant — what it does for me';

  @override
  String get settingsHubRowAdvisorSub => 'Delegation rules';

  @override
  String get settingsHubRowPrivacy => 'Privacy & data';

  @override
  String get settingsHubRowAudit => 'Audit log';

  @override
  String get settingsHubRowAuditSub => 'Who did what and when';

  @override
  String get settingsHubRowNotifications => 'Notifications';

  @override
  String get settingsHubRowBilling => 'Plans & subscription';

  @override
  String get settingsHubRowLanguage => 'Language & help';

  @override
  String get settingsHubRowComingSoon => 'What we are preparing carefully';

  @override
  String get settingsHubRowComingSoonSub => 'No date promises';

  @override
  String get familyMembersTitle => 'Family members';

  @override
  String familyMembersSelfName(String name) {
    return '$name (you)';
  }

  @override
  String get familyMembersRoleOwner => 'Owner — full control';

  @override
  String get familyMembersRoleMother => 'Co-parent';

  @override
  String get familyMembersRoleGuardian => 'Extra guardian — not promotable';

  @override
  String get familyMembersRoleChild => 'Child — triple-lock mode';

  @override
  String get familyMembersTagOwner => 'Owner';

  @override
  String familyMembersTagMotherChange(String level) {
    return '$level · change ←';
  }

  @override
  String get familyMembersTagGuardianLocked => 'Observer 🔒';

  @override
  String get familyMembersTagChild => '🔒 Child';

  @override
  String get familyMembersInviteCta => '+ Invite a co-parent';

  @override
  String get familyMembersInviteOwnerOnly => '+ Invite (owner only)';

  @override
  String get familyMembersInviteOnlyNote =>
      'No one joins the family except by the owner\'s invite';

  @override
  String get familyMembersEmptyTitle => 'No members yet';

  @override
  String get familyMembersEmptyMessage =>
      'Invite a co-parent or link a child to see roles and levels here.';

  @override
  String get familyMembersChildLeanTitle => 'For parents';

  @override
  String get familyMembersChildLeanMessage =>
      'Family members and roles are a parent surface — not part of the child experience.';

  @override
  String get childSosTitle => 'Call for help';

  @override
  String get childSosSubtitle => 'SOS button';

  @override
  String get childSosHint =>
      'If you feel unsafe — press and hold for 3 seconds';

  @override
  String get childSosHoldLabel => 'SOS\n🚨';

  @override
  String get childSosHoldSemantics =>
      'SOS button — press and hold three seconds to call for help';

  @override
  String get childSosStatusIdle => 'Keep pressing…';

  @override
  String childSosStatusHolding(int seconds) {
    return 'Keep holding… $seconds';
  }

  @override
  String get childSosStatusCancelled =>
      'Released before 3 seconds — alert was not sent (accidental-touch protection)';

  @override
  String get childSosStatusFiring => 'Sending alert…';

  @override
  String get childSosAlwaysOnBanner =>
      '🛡 This button always works — even if your time ran out, the network dropped, or the family plan ended. Your location reaches your family immediately.';

  @override
  String get childSosParentLeanTitle => 'For the child device';

  @override
  String get childSosParentLeanMessage =>
      'The SOS button is a child-device surface — parents receive the alert on the SOS alert screen.';

  @override
  String get childSosInProgressHeadline => 'Your family got your alert';

  @override
  String get childSosInProgressBroadcast =>
      'Help request is active — status below is honest';

  @override
  String get childSosInProgressFatherSeen =>
      'Father channel: see delivery status';

  @override
  String get childSosInProgressMotherSeen =>
      'Mother channel: see delivery status';

  @override
  String get childSosInProgressBackupStandby =>
      'Backup escalation: verified contacts only when configured';

  @override
  String get childSosInProgressCallFatherCta => '📞 Call dad now';

  @override
  String get childSosInProgressCallFatherSemantics =>
      'Place an immediate call to dad during SOS';

  @override
  String get childSosInProgressCancelCta => 'I’m OK — cancel the alert 💚';

  @override
  String get childSosInProgressCancelSemantics =>
      'Open cancel confirmation for the SOS alert';

  @override
  String get childSosInProgressCancelSheetTitle => 'Cancel the alert?';

  @override
  String get childSosInProgressCancelSheetBody =>
      'Are you sure you’re safe? Your family will know you cancelled it yourself.';

  @override
  String get childSosInProgressConfirmSafeCta =>
      'Yes, I’m safe — Alhamdulillah ✓';

  @override
  String get childSosInProgressConfirmSafeSemantics =>
      'Confirm safety and cancel the SOS alert';

  @override
  String get childSosInProgressCancelBackCta => 'Back';

  @override
  String get childSosInProgressResolvedToast =>
      'Alhamdulillah you’re safe 💚 — your family was told you’re OK';

  @override
  String get childSosInProgressP4Banner =>
      '🛡 An in-progress SOS is never muted or paywalled — your location always reaches your family';

  @override
  String get childSosInProgressEmptyTitle => 'No SOS in progress';

  @override
  String get childSosInProgressEmptyMessage =>
      'When you fire SOS, live broadcast status and who saw the alert appear here.';

  @override
  String get childSosInProgressOpenButtonCta => 'SOS button →';

  @override
  String get childSosInProgressOpenButtonSemantics => 'Open the SOS button';

  @override
  String get childSosInProgressErrorTitle => 'Couldn’t load the alert';

  @override
  String get childSosInProgressErrorMessage =>
      'Try again — SOS does not depend on this screen alone.';

  @override
  String get childSosInProgressParentLeanTitle => 'For the child device';

  @override
  String get childSosInProgressParentLeanMessage =>
      'The SOS-in-progress screen is for the child device — parents follow from the SOS alert board.';

  @override
  String get childSosInProgressBroadcastSemantics =>
      'Live location broadcast during SOS';

  @override
  String get childChatsTitle => 'My chats';

  @override
  String get childChatsHonestyBanner =>
      '🔒 All your chats are end-to-end encrypted — and never lock even when your time runs out';

  @override
  String get childChatsSafeCircleBanner =>
      '🛡 Your safe circle: you only reach people your parent approved — no strangers can reach you.';

  @override
  String get childChatsCallContactsCta => '📞 Call — your phone contacts';

  @override
  String get childChatsCallContactsSemantics =>
      'Open phone contacts — approved family first';

  @override
  String get childChatsCallContactsToast =>
      'Phone contacts — coming soon (stage 1)';

  @override
  String get childChatsEmptyTitle => 'No chats yet';

  @override
  String get childChatsEmptyMessage =>
      'When you start chatting with your family it appears here — encrypted and never locked when time runs out.';

  @override
  String get childChatsLoadingSemantics => 'Loading your chats';

  @override
  String get childChatsParentLeanTitle => 'For the child device';

  @override
  String get childChatsParentLeanMessage =>
      'Child chats belong on the child device — parents open the family list from the Family tab.';

  @override
  String get childConversationTitle => 'Chat';

  @override
  String get childConversationNowLabel => 'Now';

  @override
  String get childConversationIncomingTitle => 'A parent is calling you now';

  @override
  String get childConversationIncomingSubtitle =>
      'Reassurance call — rings even on silent';

  @override
  String get childConversationAnswerCta => 'Answer ✓';

  @override
  String get childConversationAnswerToast =>
      '📞 Answered in one tap — they can hear you now';

  @override
  String get childConversationNeverLockBanner =>
      '💬 This chat never locks — even when play time ends. Your family is always here.';

  @override
  String get childConversationInputHint => 'Write a message…';

  @override
  String get childConversationSendSemantics => 'Send message';

  @override
  String get childConversationLoadingSemantics => 'Loading conversation';

  @override
  String get childConversationEmptyTitle => 'Start chatting';

  @override
  String get childConversationEmptyMessage =>
      'Send the first message — it reaches your family right away.';

  @override
  String get childConversationMissingPeerTitle => 'Pick a chat';

  @override
  String get childConversationMissingPeerMessage =>
      'Open a conversation from My Family first.';

  @override
  String get childConversationNotFoundTitle => 'Chat not found';

  @override
  String get childConversationNotFoundMessage =>
      'It may be outside your safe circle — go back to chats.';

  @override
  String get childConversationParentLeanTitle => 'For the child device';

  @override
  String get childConversationParentLeanMessage =>
      'Child chat belongs on the child device — use the parent conversations list instead.';

  @override
  String get childActiveCallTitle => 'Call';

  @override
  String childActiveCallStatus(String elapsed) {
    return 'In progress · $elapsed';
  }

  @override
  String get childActiveCallMuteSemantics => 'Mute microphone';

  @override
  String get childActiveCallSpeakerSemantics => 'Speaker';

  @override
  String get childActiveCallEndSemantics => 'End call';

  @override
  String get childActiveCallMuteOnToast => 'Microphone muted';

  @override
  String get childActiveCallMuteOffToast => 'Microphone on';

  @override
  String get childActiveCallSpeakerOnToast => 'Speaker on';

  @override
  String get childActiveCallSpeakerOffToast => 'Speaker off';

  @override
  String get childActiveCallLoadingSemantics => 'Preparing call';

  @override
  String get childActiveCallMissingIdTitle => 'No call selected';

  @override
  String get childActiveCallMissingIdMessage =>
      'Start a call from your family contacts.';

  @override
  String get childActiveCallNotFoundTitle => 'Call ended';

  @override
  String get childActiveCallNotFoundMessage =>
      'Go back to chats and try again.';

  @override
  String get childActiveCallParentLeanTitle => 'For the child device';

  @override
  String get childActiveCallParentLeanMessage =>
      'Child calls belong on the child device — parents use the active call screen.';

  @override
  String get deviceUserSwitchTitle => 'Switch user';

  @override
  String deviceUserSwitchSelfName(String name) {
    return '$name (you)';
  }

  @override
  String get deviceUserSwitchRoleOwner => 'Family owner';

  @override
  String get deviceUserSwitchRoleMother => 'Co-parent';

  @override
  String deviceUserSwitchRoleMotherWithLevel(String level) {
    return 'Co-parent — $level';
  }

  @override
  String get deviceUserSwitchRoleChild => 'Child';

  @override
  String get deviceUserSwitchActiveTag => 'Active';

  @override
  String get deviceUserSwitchEnterHint => 'Enter →';

  @override
  String get deviceUserSwitchAddAccountCta => '+ Add account on this device';

  @override
  String get deviceUserSwitchAddAccountToast =>
      'Each account keeps its own password — no open sessions';

  @override
  String get deviceUserSwitchEmptyTitle => 'No accounts on this device yet';

  @override
  String get deviceUserSwitchEmptyMessage =>
      'Add the father’s or mother’s account here to switch without reinstalling.';

  @override
  String get deviceUserSwitchChildLeanTitle => 'For parents';

  @override
  String get deviceUserSwitchChildLeanMessage =>
      'User switch is for father and mother on a shared device — the child device stays in child mode.';

  @override
  String get deviceUserSwitchConfirmTitle => 'Confirm switch';

  @override
  String deviceUserSwitchConfirmBody(String name) {
    return 'Enter the password for “$name” to switch on this device.';
  }

  @override
  String get deviceUserSwitchPasswordLabel => 'Password';

  @override
  String get deviceUserSwitchConfirmSubmit => 'Enter';

  @override
  String get deviceUserSwitchConfirmCancel => 'Cancel';

  @override
  String get childModeLockTitle => 'Open parent mode';

  @override
  String get childModeLockSubtitle => 'Triple lock 🔐';

  @override
  String get childModeLockDualKeyBanner =>
      '🔒 This device is in locked child mode. Unlock needs two keys: guardian account password + approval from their device.';

  @override
  String get childModeLockSecretStepTitle => 'Step 1 — secret entry';

  @override
  String get childModeLockSecretStepHint =>
      'Press and hold the logo for 10 seconds:';

  @override
  String get childModeLockLogoHoldSemantics =>
      'Press and hold the family logo for ten seconds to open the secret entry';

  @override
  String get childModeLockSecretOpened => '✓ Secret entry opened (mock)';

  @override
  String get childModeLockPasswordStepTitle => 'Step 2 — account password';

  @override
  String get childModeLockPasswordStepHint =>
      'Guardian account password — not a device PIN.';

  @override
  String get childModeLockPasswordLabel => 'Account password';

  @override
  String get childModeLockPasswordHint => 'Guardian password — not a PIN';

  @override
  String get childModeLockVerifyCta => 'Verify';

  @override
  String get childModeLockVerifying => 'Verifying…';

  @override
  String get childModeLockVerifySemantics =>
      'Verify the guardian password to request the second key';

  @override
  String childModeLockPasswordFailed(int current, int max) {
    return 'Incorrect password ($current/$max) — father notified immediately';
  }

  @override
  String get childModeLockRequestSentToast =>
      'Approval request sent to the father’s device…';

  @override
  String get childModeLockAwaitingBanner =>
      '⏳ Step 3 — waiting for the second key from your parent’s device. Password alone is not enough.';

  @override
  String get childModeLockViewFatherCta => 'See what the father receives →';

  @override
  String get childModeLockViewFatherSemantics =>
      'Open the parent-mode unlock request screen on the father’s device';

  @override
  String get childModeLockAttemptsWarning =>
      '⚠️ Every wrong attempt notifies your father immediately. After 3 attempts: 24-hour lock + mother notified.';

  @override
  String get childModeLockLockoutBanner =>
      '🔒 Secret entry locked for 24 hours after three failed attempts — and your mother was notified.';

  @override
  String get childModeLockEntertainmentLocked =>
      'Entertainment stays locked in child mode — only dual keys open parent mode.';

  @override
  String get childModeLockSosCta => '🛡 SOS — always available';

  @override
  String get childModeLockParentLeanTitle => 'For the child device';

  @override
  String get childModeLockParentLeanMessage =>
      'Child-mode lock and secret entry live on the child device — the second key reaches the father on the parent-mode unlock request screen.';

  @override
  String get parentSecondKeyTitle => 'Parent-mode unlock requests';

  @override
  String get parentSecondKeyEmptyTitle => 'No unlock requests';

  @override
  String get parentSecondKeyEmptyMessage =>
      'When a child device verifies the guardian password, the second-key request appears here for your allow or deny.';

  @override
  String get parentSecondKeyPendingHeading => '🔓 Request now';

  @override
  String get parentSecondKeyPendingBody =>
      'Parent-mode unlock request on a child device';

  @override
  String get parentSecondKeyPendingMeta =>
      'Correct password entered · waiting for your second key';

  @override
  String get parentSecondKeyApprove => 'Allow 10 minutes';

  @override
  String get parentSecondKeyDeny => 'Deny';

  @override
  String get parentSecondKeyApproveSemantics =>
      'Allow parent mode for ten minutes on the child device';

  @override
  String get parentSecondKeyDenySemantics =>
      'Deny the parent-mode unlock request';

  @override
  String get parentSecondKeyApprovedToast =>
      'Parent mode allowed for 10 minutes on the child device';

  @override
  String get parentSecondKeyDeniedToast =>
      'Request denied — the child device stays locked';

  @override
  String get parentSecondKeyAttemptsTitle => 'Attempt log';

  @override
  String get parentSecondKeyAttemptsEmpty => 'No failed attempts yet.';

  @override
  String parentSecondKeyAttemptFailed(int current, int max) {
    return 'Wrong-password attempt ($current/$max)';
  }

  @override
  String parentSecondKeyAttemptLockout(int current) {
    return 'Lockout after attempt $current — mother notified';
  }

  @override
  String get parentSecondKeyAttemptDevice => 'Child device';

  @override
  String get parentSecondKeyLockoutHint =>
      '💡 After 3 failed attempts: 24-hour lock + mother notified. The gap becomes an early tamper alarm.';

  @override
  String get parentSecondKeyMotherHint =>
      '🔒 The second key stays with the father — you see requests and failed attempts; allow/deny is on his device.';

  @override
  String get parentSecondKeySosCta => '🛡 SOS — always available';

  @override
  String get parentSecondKeyChildLeanTitle => 'For the parent device';

  @override
  String get parentSecondKeyChildLeanMessage =>
      'Second-key allow and deny live on the father’s device after the child verifies the guardian password.';

  @override
  String get motherPermissionLevelTitle => 'Mother permission level';

  @override
  String motherPermissionLevelCurrentTitle(String level) {
    return '$level — current';
  }

  @override
  String get motherPermissionLevelObserverDesc =>
      'Sees, stays reassured, and notifies you';

  @override
  String get motherPermissionLevelPartnerDesc =>
      '+ Approves requests, grants extra time (≤30 min), and manages tasks';

  @override
  String get motherPermissionLevelFullDesc =>
      '+ Edits rules, limits, and safe zones';

  @override
  String get motherPermissionLevelFixedRightsBanner =>
      'At every level: she receives SOS · can call children · sees their locations. Family advisor, subscription, and invites stay yours alone.';

  @override
  String get motherPermissionLevelOwnerOnlyBanner =>
      'This screen is for the owner only — change mother’s permission level on the father’s device.';

  @override
  String get motherPermissionLevelAuditTitle => 'Change log — never deleted';

  @override
  String get motherPermissionLevelAuditEmpty =>
      'No changes yet — every raise or lower is recorded here and never deleted.';

  @override
  String motherPermissionLevelAuditTransition(String from, String to) {
    return '$from → $to';
  }

  @override
  String motherPermissionLevelAuditMeta(String when) {
    return '$when · by you · mother notified';
  }

  @override
  String get motherPermissionLevelDowngradeTitle => '⚠️ Confirm downgrade';

  @override
  String motherPermissionLevelDowngradeBody(String level) {
    return 'She will lose the ability to approve kids’ requests and grant extra time when lowered to «$level» — sure?';
  }

  @override
  String motherPermissionLevelDowngradeConfirm(String level) {
    return 'Yes — lower to $level';
  }

  @override
  String motherPermissionLevelUpgradeTitle(String level) {
    return '🤍 Upgrade to «$level»';
  }

  @override
  String motherPermissionLevelUpgradeBody(String level) {
    return 'She will get a trust message: you can now do more at «$level» — without owner powers (family advisor · subscription · invites).';
  }

  @override
  String motherPermissionLevelUpgradeConfirm(String level) {
    return 'Upgrade to $level';
  }

  @override
  String get motherPermissionLevelDialogCancel => 'Cancel';

  @override
  String motherPermissionLevelDowngradedToast(String level) {
    return 'Level lowered to «$level» — mother notified';
  }

  @override
  String motherPermissionLevelUpgradedToast(String level) {
    return 'Upgraded to «$level» 🤍 — recorded in the never-deleted log';
  }

  @override
  String get motherPermissionLevelSosCta => '🛡 SOS — always available';

  @override
  String get motherPermissionLevelChildLeanTitle => 'For the parent device';

  @override
  String get motherPermissionLevelChildLeanMessage =>
      'Mother’s permission level is set by the owner only — it does not appear on the child’s device.';

  @override
  String get focusReportTitle => 'Focus report and sessions';

  @override
  String focusReportHeading(String name) {
    return 'Focus sessions for $name';
  }

  @override
  String get focusReportWeeklyLabel => 'This week';

  @override
  String get focusReportGoalComplete => 'Weekly goal: 100% complete';

  @override
  String get focusReportGoalInProgress => 'Weekly goal: in progress';

  @override
  String get focusReportSessionsLabel => 'focus sessions';

  @override
  String focusReportWeeklyMeta(int hours, int minutes, int longest) {
    return '${hours}h ${minutes}m net focus · longest $longest min';
  }

  @override
  String get focusReportAdvisorTitleSelfDiscipline =>
      'Smart note: self-discipline worth celebrating';

  @override
  String focusReportAdvisorBodyScienceResist(String name) {
    return 'During science study on Monday, $name tried to open a distracting app twice but stepped back immediately and returned to studying.';
  }

  @override
  String get focusReportPraiseNewTag => 'New';

  @override
  String get focusReportPraiseSentTag => 'Praise sent ✓';

  @override
  String get focusReportPraiseCta => 'Send praise';

  @override
  String focusReportRewardCta(int minutes) {
    return 'Reward (+$minutes min)';
  }

  @override
  String focusReportPraiseDeliveredLabel(String name) {
    return 'Your encouragement was sent to $name\'s screen:';
  }

  @override
  String get focusReportPraiseQuoteResistDistraction =>
      'Proud of you! I noticed you resisted distraction and returned to study 👏';

  @override
  String focusReportPraiseSentToast(String name) {
    return 'Encouragement sent to $name\'s screen';
  }

  @override
  String focusReportRewardToast(String name, int minutes) {
    return 'Rewarded $name with +$minutes minutes of play for great self-discipline';
  }

  @override
  String get focusReportScheduleHeading => 'Your scheduled sessions';

  @override
  String get focusReportScheduleOwnerTag => 'You create these';

  @override
  String get focusReportScheduleAfternoonStudy => 'Afternoon study';

  @override
  String get focusReportScheduleAfternoonSlot => '4:30 – 5:30 PM';

  @override
  String get focusReportScheduleSchoolDays => 'School days';

  @override
  String get focusReportBlockedYoutube => 'video apps';

  @override
  String get focusReportBlockedGames => 'games';

  @override
  String get focusReportBlockedJoiner => ', ';

  @override
  String focusReportScheduleMeta(String time, String days, String blocked) {
    return '$time · $days · blocks: $blocked';
  }

  @override
  String get focusReportAddScheduleCta => '+ New scheduled session';

  @override
  String get focusReportAddScheduleToast =>
      'Scheduled sessions — full editor coming in a later stage';

  @override
  String focusReportScheduleFootnote(String name) {
    return 'During a session only selected apps are blocked — Quran and educational apps stay open. $name\'s voluntary sessions still earn discipline minutes as before.';
  }

  @override
  String get focusReportChildOne => 'Child one';

  @override
  String get focusReportChildTwo => 'Child two';

  @override
  String get focusReportChildThree => 'Child three';

  @override
  String get focusReportEmptyTitle => 'No focus data yet';

  @override
  String get focusReportEmptyMessage =>
      'Add a child first — then weekly focus sessions and parent schedules appear here.';

  @override
  String get focusReportEmptyCta => 'Add a child';

  @override
  String get focusReportLoadingSemantics => 'Loading focus report';

  @override
  String get focusReportChildLeanTitle => 'Focus reports are for parents';

  @override
  String get focusReportChildLeanMessage =>
      'Weekly focus reports and parent schedules are managed on the parent device. SOS stays available.';

  @override
  String get focusReportObserverHint =>
      'View only — praise, rewards, and schedule toggles are for the father or a partner/full mother.';

  @override
  String get focusReportObserverBlocked =>
      'View only — ask the father or a partner mother to manage focus';

  @override
  String get focusReportSosCta => 'SOS';

  @override
  String get familyCalendarTitle => 'Family calendar';

  @override
  String get familyCalendarHijriDate => 'Sunday 22 Rabi al-Awwal 1448';

  @override
  String get familyCalendarGregorianDate => '14 September 2026';

  @override
  String get familyCalendarPrayerFajr => '🕌 Fajr 4:38';

  @override
  String get familyCalendarPrayerDhuhr => '🕌 Dhuhr 11:54';

  @override
  String get familyCalendarPrayerAsr => '🕌 Asr 3:18';

  @override
  String get familyCalendarPrayerMaghrib => '🕌 Maghrib 5:56';

  @override
  String get familyCalendarPrayerIsha => '🕌 Isha 7:26';

  @override
  String get familyCalendarMonthSep2026 => 'September 2026 · Rabi al-Awwal';

  @override
  String get familyCalendarWeekdaySun => 'Sun';

  @override
  String get familyCalendarWeekdayMon => 'Mon';

  @override
  String get familyCalendarWeekdayTue => 'Tue';

  @override
  String get familyCalendarWeekdayWed => 'Wed';

  @override
  String get familyCalendarWeekdayThu => 'Thu';

  @override
  String get familyCalendarWeekdayFri => 'Fri';

  @override
  String get familyCalendarWeekdaySat => 'Sat';

  @override
  String get familyCalendarFilterAll => 'All';

  @override
  String get familyCalendarFilterDin => '🕌 Religious';

  @override
  String get familyCalendarFilterOcc => '🎂 Occasions';

  @override
  String get familyCalendarFilterSch => '🏫 School';

  @override
  String get familyCalendarFilterAct => '⚽ Activity';

  @override
  String get familyCalendarEventsHeadingAll => 'Upcoming events';

  @override
  String get familyCalendarEventsHeadingDin => '🕌 Religious';

  @override
  String get familyCalendarEventsHeadingOcc => '🎂 Occasions';

  @override
  String get familyCalendarEventsHeadingSch => '🏫 School';

  @override
  String get familyCalendarEventsHeadingAct => '⚽ Activity';

  @override
  String get familyCalendarFilterEmpty => 'No events in this category';

  @override
  String get familyCalendarAddEventCta => '+ New event';

  @override
  String get familyCalendarEventMemorizationReview =>
      'Memorization review — daily wird';

  @override
  String get familyCalendarEventSwimPractice => 'Swim practice — sports club';

  @override
  String get familyCalendarEventGrandpaDinner => 'Grandparents dinner';

  @override
  String get familyCalendarEventQuranTest => 'Quran test';

  @override
  String get familyCalendarEventAnniversary => 'Your anniversary';

  @override
  String get familyCalendarEventDentalAppointment => 'Dental appointment';

  @override
  String get familyCalendarWhenTodayAfterMaghrib => 'Today · after Maghrib';

  @override
  String get familyCalendarWhenToday430pm => 'Today · 4:30 PM';

  @override
  String get familyCalendarWhenToday730pm => 'Today · 7:30 PM';

  @override
  String get familyCalendarWhenTuesday => 'Tuesday';

  @override
  String get familyCalendarWhenThursday26 => 'Thursday 26 Rabi al-Awwal';

  @override
  String get familyCalendarWhenThursday10am => 'Thursday · 10 AM';

  @override
  String get familyCalendarWhoOne => 'Child one';

  @override
  String get familyCalendarWhoTwo => 'Child two';

  @override
  String get familyCalendarWhoThree => 'Child three';

  @override
  String get familyCalendarWhoParents => 'Parents';

  @override
  String get familyCalendarWhoEveryone => 'Everyone';

  @override
  String get familyCalendarEmptyTitle => 'No calendar events yet';

  @override
  String get familyCalendarEmptyMessage =>
      'Add a child first — then family events, prayer times, and the month grid fill in here.';

  @override
  String get familyCalendarEmptyCta => 'Add a child';

  @override
  String get familyCalendarLoadingSemantics => 'Loading family calendar';

  @override
  String get familyCalendarChildLeanTitle => 'Calendar is for parents';

  @override
  String get familyCalendarChildLeanMessage =>
      'Family calendar and events are managed on the parent device. SOS stays available.';

  @override
  String get familyCalendarObserverHint =>
      'View only — adding events is for the father or a partner/full mother.';

  @override
  String get familyCalendarObserverBlocked =>
      'View only — ask the father or a partner mother to manage the calendar';

  @override
  String get familyCalendarSosCta => 'SOS';

  @override
  String get addEventTitle => 'New event';

  @override
  String get addEventTitleLabel => 'Title';

  @override
  String get addEventTitleHint => 'What is this event about?';

  @override
  String get addEventDefaultTitleSample => 'Memorization review session';

  @override
  String get addEventCategoryHeading => 'Category';

  @override
  String get addEventCategoryDin => 'Faith';

  @override
  String get addEventCategoryOcc => 'Occasion';

  @override
  String get addEventCategorySch => 'School';

  @override
  String get addEventCategoryAct => 'Activity';

  @override
  String get addEventDateHeading => 'Date';

  @override
  String get addEventCalendarHijri => '🌙 Hijri';

  @override
  String get addEventCalendarGregorian => 'Gregorian';

  @override
  String get addEventCalendarHijriToast =>
      'Hijri calendar selected (Stage 1 mock)';

  @override
  String get addEventCalendarGregorianToast =>
      'Gregorian calendar selected (Stage 1 mock)';

  @override
  String get addEventDateHijriSample => '23 Rabi al-Awwal 1448';

  @override
  String get addEventDateGregorianSample => 'Monday 15 September 2026';

  @override
  String get addEventDateConversionSample =>
      '= Monday 15 September — auto-converted';

  @override
  String get addEventTimeLabel => 'Time';

  @override
  String get addEventTimeAfterMaghrib => '🕌 Right after Maghrib';

  @override
  String get addEventTimeAfterIsha => '🕌 After Isha';

  @override
  String get addEventTimeSpecific => '⏰ Specific time';

  @override
  String get addEventPlaceLabel => 'Place (optional) 📍';

  @override
  String get addEventPlaceHint => 'Home, mosque, club…';

  @override
  String get addEventReminderLabel => 'Remind before';

  @override
  String get addEventReminderAtTime => 'At event time';

  @override
  String get addEventReminderFifteenMin => '15 minutes';

  @override
  String get addEventReminderOneHour => '1 hour';

  @override
  String get addEventReminderOneDay => 'Full day';

  @override
  String get addEventWhoLabel => 'Applies to';

  @override
  String get addEventWhoChildOne => 'Child one 🦁';

  @override
  String get addEventWhoChildTwo => 'Child two 🐱';

  @override
  String get addEventWhoChildThree => 'Child three 🐼';

  @override
  String get addEventWhoMother => 'Mother 🌸';

  @override
  String get addEventWhoEveryone => 'Everyone 👨‍👩‍👧‍👦';

  @override
  String get addEventWeeklyRepeat => 'Weekly repeat';

  @override
  String get addEventSaveCta => 'Save event ✓';

  @override
  String get addEventTitleEmptyToast => 'Enter an event title first';

  @override
  String addEventSavedToast(String title, String who) {
    return 'Saved \"$title\" — it appears on the calendar and $who will be reminded';
  }

  @override
  String get addEventEmptyTitle => 'No family members yet';

  @override
  String get addEventEmptyMessage =>
      'Add a child first — then family calendar events can be scheduled here.';

  @override
  String get addEventEmptyCta => 'Add a child';

  @override
  String get addEventLoadingSemantics => 'Loading add event form';

  @override
  String get addEventChildLeanTitle => 'Calendar events are for parents';

  @override
  String get addEventChildLeanMessage =>
      'Adding family calendar events is managed on the parent device. SOS stays available.';

  @override
  String get addEventSosCta => 'SOS';

  @override
  String get addEventObserverHint =>
      'View only — saving events is for the father or a partner/full mother.';

  @override
  String get addEventObserverBlocked =>
      'View only — ask the father or a partner mother to save events';

  @override
  String get familyTasksTitle => 'Family tasks';

  @override
  String get familyTasksSubtitle => 'Daily tasks and encouraging rewards';

  @override
  String get familyTasksNewTaskCta => '+ New task';

  @override
  String get familyTasksPendingHeading => '⏳ Awaiting your approval';

  @override
  String get familyTasksPendingEmpty =>
      'No pending tasks right now — well done 👏';

  @override
  String familyTasksApproveCta(int minutes) {
    return '✓ Approve (+$minutes min)';
  }

  @override
  String familyTasksApproveToast(String child, int minutes) {
    return 'Approved $child\'s task — +$minutes minutes deposited in wallet!';
  }

  @override
  String familyTasksPendingLine(String child, String title) {
    return '$child: «$title»';
  }

  @override
  String get familyTasksMotherHelpHeading => '🤝 Mother help requests';

  @override
  String familyTasksMotherHelpMeta(String time) {
    return 'No minutes — home partnership 💗 · $time';
  }

  @override
  String get familyTasksMotherStatusOpen => 'Open';

  @override
  String get familyTasksMotherStatusDone => 'Done 🌟';

  @override
  String get familyTasksActiveHeading => 'Active child tasks';

  @override
  String familyTasksActiveLine(String title, String child) {
    return '$title ($child)';
  }

  @override
  String familyTasksRewardMeta(int minutes) {
    return 'Reward: +$minutes minutes to wallet — your decision';
  }

  @override
  String get familyTasksStatusCompleted => 'Completed';

  @override
  String get familyTasksStatusPendingApproval => 'Under review';

  @override
  String get familyTasksStatusAssigned => 'In progress';

  @override
  String get familyTasksChildOne => 'Child one';

  @override
  String get familyTasksChildTwo => 'Child two';

  @override
  String get familyTasksChildThree => 'Child three';

  @override
  String get familyTasksTaskTidyRoom => 'Tidy the room and bed';

  @override
  String get familyTasksTaskWashDishes => 'Wash dishes after dinner';

  @override
  String get familyTasksTaskMathStudy => 'Math study and exercises';

  @override
  String get familyTasksTaskSchoolReturnList =>
      'Review back-to-school checklist';

  @override
  String get familyTasksProofPhotoAttached => '📸 Photo of tidy room attached';

  @override
  String get familyTasksTimeTenMinAgo => '10 minutes ago';

  @override
  String get familyTasksTimeToday => 'Today';

  @override
  String get familyTasksTimeYesterday => 'Yesterday';

  @override
  String get familyTasksEmptyTitle => 'No family members yet';

  @override
  String get familyTasksEmptyMessage =>
      'Add a child first — then family tasks and rewards can be managed here.';

  @override
  String get familyTasksEmptyCta => 'Add a child';

  @override
  String get familyTasksLoadingSemantics => 'Loading family tasks';

  @override
  String get familyTasksChildLeanTitle => 'Family tasks are for parents';

  @override
  String get familyTasksChildLeanMessage =>
      'Managing family tasks and rewards is done on the parent device. SOS stays available.';

  @override
  String get familyTasksSosCta => 'SOS';

  @override
  String get familyTasksObserverHint =>
      'View only — approving tasks and creating new ones is for the father or a partner/full mother.';

  @override
  String get familyTasksObserverBlocked =>
      'View only — ask the father or a partner mother to manage tasks';

  @override
  String get createTaskTitle => 'New task';

  @override
  String get createTaskTaskTitleLabel => 'Task title';

  @override
  String get createTaskTaskTitleHint =>
      'Example: Tidy your room before Maghrib';

  @override
  String get createTaskAssigneeLabel => 'Assign to';

  @override
  String get createTaskAssigneeChildOne => 'Child one 🦁';

  @override
  String get createTaskAssigneeChildTwo => 'Child two 🐱';

  @override
  String get createTaskAssigneeChildThree => 'Child three 🐼';

  @override
  String get createTaskAssigneeMother => 'Mother 🌸';

  @override
  String get createTaskMotherHelpBanner =>
      'This becomes a help request for mother — no play minutes reward.';

  @override
  String get createTaskRewardTitle => 'Reward (minutes only)';

  @override
  String get createTaskCourageLabel => 'Courage minutes';

  @override
  String get createTaskPlaytimeLabel => 'Extra playtime';

  @override
  String createTaskMinutesLabel(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get createTaskSubmitCta => 'Create task →';

  @override
  String get createTaskTitleEmptyToast => 'Enter a task title first';

  @override
  String createTaskSubmittedToast(String title, String who) {
    return 'Task \"$title\" assigned to $who';
  }

  @override
  String get createTaskEmptyTitle => 'No family members yet';

  @override
  String get createTaskEmptyMessage =>
      'Add a child first — then family tasks with rewards can be created here.';

  @override
  String get createTaskEmptyCta => 'Add a child';

  @override
  String get createTaskLoadingSemantics => 'Loading create task form';

  @override
  String get createTaskChildLeanTitle => 'Family tasks are for parents';

  @override
  String get createTaskChildLeanMessage =>
      'Creating family tasks is managed on the parent device. SOS stays available.';

  @override
  String get createTaskSosCta => 'SOS';

  @override
  String get createTaskObserverHint =>
      'View only — creating tasks is for the father or a partner/full mother.';

  @override
  String get createTaskObserverBlocked =>
      'View only — ask the father or a partner mother to create tasks';

  @override
  String get auditLogTitle => 'Audit log';

  @override
  String get auditLogAppendBanner =>
      'Appended only — never edited, never deleted. Its neutrality is your protection.';

  @override
  String get auditLogEmptyTitle => 'No audit entries yet';

  @override
  String get auditLogEmptyMessage =>
      'Consequential family actions will appear here as an append-only record. Nothing on this screen can be deleted.';

  @override
  String get auditLogLoadingSemantics => 'Loading audit log';

  @override
  String get auditLogChildLeanTitle => 'Audit log is for parents';

  @override
  String get auditLogChildLeanMessage =>
      'The security audit log is managed on the parent device. SOS stays available.';

  @override
  String get auditLogSosCta => 'SOS';

  @override
  String get auditLogObserverHint =>
      'View only — the audit log cannot be changed at any permission level.';

  @override
  String get auditLogSubjectChildOne => 'Child one';

  @override
  String get auditLogSubjectChildTwo => 'Child two';

  @override
  String get auditLogSubjectChildThree => 'Child three';

  @override
  String get auditLogSubjectMother => 'Mother';

  @override
  String get auditLogActorFather => 'by Father';

  @override
  String get auditLogActorMother => 'by Mother';

  @override
  String get auditLogActorSystem => 'system';

  @override
  String auditLogActorChildDevice(String who) {
    return '$who\'s device';
  }

  @override
  String auditLogWhenStamp(String date, String time) {
    return '$date · $time';
  }

  @override
  String auditLogEntrySosTitle(String who) {
    return 'SOS alert — $who';
  }

  @override
  String get auditLogEntryMotherLevelTitle =>
      'Mother level: Observer → Partner';

  @override
  String get auditLogEntryUnlockTitle => 'Parent-mode unlock attempt ×2';

  @override
  String get auditLogEntryForgetTitle => 'Forget button used';

  @override
  String auditLogEntryConsentTitle(String who) {
    return 'Parental consent — pair $who\'s device';
  }

  @override
  String get auditLogDetailClosedAfter6m => 'closed manually after 6 min';

  @override
  String get auditLogDetailObserverToPartner => 'notified';

  @override
  String get auditLogDetailRejectedX2 => 'rejected';

  @override
  String get auditLogDetailFriday => 'Friday';

  @override
  String get auditLogDetailTimestamped => 'timestamped';

  @override
  String get auditLogDetailNotified => 'notified';

  @override
  String get languageHelpTitle => 'Language & help';

  @override
  String get languageHelpLanguageSection => 'Language';

  @override
  String get languageHelpArabic => 'Arabic';

  @override
  String get languageHelpArabicSubtitle => 'Authentic RTL';

  @override
  String get languageHelpCurrentTag => 'Current';

  @override
  String get languageHelpEnglish => 'English';

  @override
  String get languageHelpChooseAction => 'Choose';

  @override
  String get languageHelpLocaleToast =>
      'English interface — coming in a later update';

  @override
  String get languageHelpHelpCenterSection => 'Help center';

  @override
  String get languageHelpDeviceDisconnectTitle =>
      'My child\'s device keeps disconnecting?';

  @override
  String get languageHelpDeviceDisconnectSubtitle =>
      'Most common — per-device guide';

  @override
  String get languageHelpParentModeTitle => 'How do I unlock parent mode?';

  @override
  String get languageHelpSupportCta => 'Contact support';

  @override
  String get languageHelpSupportToast =>
      'Arabic support chat — reply during business hours';

  @override
  String get languageHelpEmptyTitle => 'Set up your family first';

  @override
  String get languageHelpEmptyMessage =>
      'Add a child to unlock language settings and the help center.';

  @override
  String get languageHelpEmptyCta => 'Add a child';

  @override
  String get languageHelpLoadingSemantics => 'Loading language & help';

  @override
  String get languageHelpChildLeanTitle => 'Language & help is for parents';

  @override
  String get languageHelpChildLeanMessage =>
      'Language and help settings are managed on a parent device. SOS stays available.';

  @override
  String get languageHelpObserverHint =>
      'View only — language switch and support contact are for the father or a partner/full mother.';

  @override
  String get languageHelpObserverBlocked =>
      'View only — ask the father or a partner mother to change language or contact support';

  @override
  String get languageHelpSosCta => 'SOS';

  @override
  String individualTimelineTitle(String name) {
    return '$name\'s timeline';
  }

  @override
  String get individualTimelineChildOne => 'Child one';

  @override
  String get individualTimelineChildTwo => 'Child two';

  @override
  String get individualTimelineChildThree => 'Child three';

  @override
  String get individualTimelineEmptyTitle => 'No timeline yet';

  @override
  String get individualTimelineEmptyMessage =>
      'Add a child to see their unified timeline across safety, learning, and connection.';

  @override
  String get individualTimelineEmptyCta => 'Add a child';

  @override
  String get individualTimelineLoadingSemantics =>
      'Loading individual timeline';

  @override
  String get individualTimelineChildLeanTitle => 'Timeline is for parents';

  @override
  String get individualTimelineChildLeanMessage =>
      'The individual timeline is viewed on the parent device. SOS stays available.';

  @override
  String get individualTimelineSosCta => 'SOS';

  @override
  String get individualTimelineObserverHint =>
      'View only — you can read insights and today\'s thread but cannot act on suggestions.';

  @override
  String get individualTimelineObserverBlocked =>
      'View only — acting on advisor suggestions requires Partner or Full permission.';

  @override
  String get individualTimelineInsightBadgeCrossDomain => 'Cross-domain link';

  @override
  String get individualTimelinePatternLabel => 'Pattern found: ';

  @override
  String get individualTimelinePatternFootballSleepStudy =>
      'On football practice days, sleep starts ~25 min earlier → next-morning learning scores ~15% higher.';

  @override
  String get individualTimelineSuggestionLabel => 'Suggestion: ';

  @override
  String get individualTimelineSuggestionTestsAfterPractice =>
      'Schedule important tests on mornings after practice.';

  @override
  String get individualTimelinePrivacyTriDomainUnique =>
      'No competitor sees the tri-domain picture: safety + learning + connection together.';

  @override
  String get individualTimelineDiscussCta => 'Discuss with advisor';

  @override
  String get individualTimelineDiscussToast =>
      'Suggestion queued for your family advisor (Stage 1 mock).';

  @override
  String get individualTimelineTodayHeading => 'Today';

  @override
  String get individualTimelineStopSchoolModeActive => 'School mode active';

  @override
  String get individualTimelineStopFinishedFractionsReview =>
      'Finished fractions review';

  @override
  String get individualTimelineStopArrivedSchoolMessage =>
      '«Dad, I arrived at school»';

  @override
  String get individualTimelineStopLateSleep => 'Slept at 11:10 PM yesterday';

  @override
  String get individualTimelineTimeSince7am => 'since 7:00 AM';

  @override
  String get individualTimelineTimeAt840am => '8:40 AM';

  @override
  String get individualTimelineTimeAt714am => '7:14 AM';

  @override
  String get individualTimelineTimeAt1110pmYesterday => '11:10 PM yesterday';

  @override
  String get individualTimelineDetailScore90 => '90%';

  @override
  String get individualTimelineDetailLate40minBaseline =>
      '40 min late vs baseline';

  @override
  String get familyPatternsTitle => 'Family patterns';

  @override
  String familyPatternsAdvisorBanner(int percent) {
    return '🧠 Family advisor learns your family rhythm to spot what drifts — trust indicator always shown: $percent%.';
  }

  @override
  String get familyPatternsChildOne => 'Child one';

  @override
  String get familyPatternsChildTwo => 'Child two';

  @override
  String familyPatternsConfidenceSeal(int percent) {
    return 'Trust $percent%';
  }

  @override
  String get familyPatternsSleepDelayTitle =>
      'Sleep shifted 40 min later this week';

  @override
  String get familyPatternsSleepBaselineSubtitle => 'vs. baseline 10:30 PM';

  @override
  String get familyPatternsCommunicationStableTitle =>
      'Communication normal and stable';

  @override
  String get familyPatternsEducationImproveTitle => 'Learning trend +12%';

  @override
  String get familyPatternsMorningActivityDropTitle =>
      'Morning activity dipped 3 days';

  @override
  String get familyPatternsMorningActivityHint =>
      'Early signal — may be fatigue';

  @override
  String get familyPatternsTagAnomaly => 'Anomaly';

  @override
  String get familyPatternsTagOk => '✓';

  @override
  String get familyPatternsTagWatch => 'Watch';

  @override
  String get familyPatternsTagImprove => '📈';

  @override
  String get familyPatternsTimelineLink => 'Timeline ‹';

  @override
  String get familyPatternsFooterNote =>
      'Baseline builds from 14 days — the family advisor suggests, never judges.';

  @override
  String get familyPatternsEmptyTitle => 'No family patterns yet';

  @override
  String get familyPatternsEmptyMessage =>
      'Add a child first — then sleep, communication, and learning patterns appear here after the baseline window.';

  @override
  String get familyPatternsEmptyCta => 'Add a child';

  @override
  String get familyPatternsLoadingSemantics => 'Loading family patterns';

  @override
  String get familyPatternsChildLeanTitle => 'Family patterns are for parents';

  @override
  String get familyPatternsChildLeanMessage =>
      'Pattern insights are managed on the parent device. SOS stays available.';

  @override
  String get familyPatternsObserverHint =>
      'View only — individual timelines open for the father or a partner/full mother.';

  @override
  String get familyPatternsObserverBlocked =>
      'View only — ask the father or a partner mother to open the timeline';

  @override
  String get familyPatternsSosCta => 'SOS';

  @override
  String knowledgeMapsTitle(String name) {
    return 'Growth & connection map — $name';
  }

  @override
  String get knowledgeMapsChildOne => 'Child one';

  @override
  String get knowledgeMapsChildTwo => 'Child two';

  @override
  String get knowledgeMapsChildThree => 'Child three';

  @override
  String get knowledgeMapsEmptyTitle => 'No knowledge map yet';

  @override
  String get knowledgeMapsEmptyMessage =>
      'Add a child to see learning paths, social balance, and dinner prompts.';

  @override
  String get knowledgeMapsEmptyCta => 'Add a child';

  @override
  String get knowledgeMapsLoadingSemantics => 'Loading knowledge maps';

  @override
  String get knowledgeMapsChildLeanTitle => 'Knowledge maps are for parents';

  @override
  String get knowledgeMapsChildLeanMessage =>
      'Growth and connection maps are viewed on the parent device. SOS stays available.';

  @override
  String get knowledgeMapsSosCta => 'SOS';

  @override
  String get knowledgeMapsObserverHint =>
      'View only — path links and dinner actions need Partner or Full permission.';

  @override
  String get knowledgeMapsObserverBlocked =>
      'View only — ask the father or a partner mother to open paths or send dinner prompts';

  @override
  String get knowledgeMapsLearningHeading => 'Learning & mastery paths';

  @override
  String knowledgeMapsMasteryTag(int percent) {
    return 'Rising mastery ↗ $percent%';
  }

  @override
  String get knowledgeMapsPathQuranTitle => 'Qur\'an — Surah Al-Mulk';

  @override
  String get knowledgeMapsPathQuranSubtitle =>
      'Completed 15 of 30 ayahs · 🔥 5-day streak';

  @override
  String get knowledgeMapsPathQuranCta => 'Follow wird →';

  @override
  String get knowledgeMapsPathMathTitle => 'Math — ordinary fractions';

  @override
  String get knowledgeMapsPathMathSubtitle =>
      'Mastered add & subtract · needs division practice';

  @override
  String get knowledgeMapsPathMathCta => 'Practice drill';

  @override
  String get knowledgeMapsSocialHeading =>
      'Connection network & social balance';

  @override
  String get knowledgeMapsSocialSafeTag => 'Safe environment';

  @override
  String get knowledgeMapsSocialFamilyTitle => 'Immediate family (80%)';

  @override
  String get knowledgeMapsSocialFamilySubtitle => 'Warm daily chats';

  @override
  String get knowledgeMapsSocialFriendsTitle => 'Approved friends (15%)';

  @override
  String get knowledgeMapsSocialNewTitle => 'New interaction (5%)';

  @override
  String get knowledgeMapsSocialFoundationTag => 'Foundation';

  @override
  String get knowledgeMapsDinnerHeading => 'Tonight\'s dinner question';

  @override
  String get knowledgeMapsDinnerQ1 =>
      'If we opened a family restaurant — what would we name it, and what\'s our signature dish?';

  @override
  String get knowledgeMapsDinnerQ2 =>
      'What was the best thing that happened today… and what do you wish had gone better?';

  @override
  String get knowledgeMapsDinnerQ3 =>
      'If we swapped roles for a full day — who takes whose role, and why?';

  @override
  String get knowledgeMapsDinnerNextCta => 'Another question';

  @override
  String get knowledgeMapsDinnerSendCta => 'Send to family';

  @override
  String get knowledgeMapsDinnerSendToast =>
      'Sent to family chat — tonight\'s discussion is ready (Stage 1 mock)';

  @override
  String get knowledgeMapsDinnerFooter =>
      'From Family Advisor — to deepen your table talk';

  @override
  String get childLearnHomeTitle => 'My learning';

  @override
  String get childLearnHomeChildChip => 'Child mode';

  @override
  String get childLearnHomeLevelExplorer => 'Explorer';

  @override
  String childLearnHomeLevelLabel(int level, String title) {
    return 'Level $level — $title';
  }

  @override
  String childLearnHomeMinutesEarned(int minutes) {
    return '$minutes minutes earned this month';
  }

  @override
  String childLearnHomeStreakDays(int days) {
    return '$days-day streak';
  }

  @override
  String get childLearnHomeFreeTimeChip => 'Free time now';

  @override
  String get childLearnHomeChallengeHeading => 'Your parent\'s challenge';

  @override
  String get childLearnHomeChallengeFractions => 'Fractions quiz';

  @override
  String childLearnHomeChallengeBody(String title, int minutes) {
    return '$title — +$minutes play minutes if you master it!';
  }

  @override
  String get childLearnHomeChallengeCta => 'Start the challenge';

  @override
  String get childLearnHomeMaterialsHeading => 'My subjects';

  @override
  String get childLearnHomeSubjectMath => 'Math';

  @override
  String get childLearnHomeSubjectQuran => 'Qur\'an';

  @override
  String get childLearnHomeSubjectEnglish => 'English';

  @override
  String get childLearnHomeMathNewLesson => 'New lesson from your parent';

  @override
  String get childLearnHomeQuranWird => 'Wird: Al-Mulk 11–15';

  @override
  String get childLearnHomeEnglishCardsLeft => '6 cards left';

  @override
  String get childLearnHomeTagNew => 'New';

  @override
  String childLearnHomeTagProgress(int percent) {
    return '$percent%';
  }

  @override
  String get childLearnHomeMaterialSoonToast =>
      'Coming soon on this path (Stage 1 mock)';

  @override
  String get childLearnHomeQuickTutor => 'My tutor';

  @override
  String get childLearnHomeQuickFocus => 'Focus';

  @override
  String get childLearnHomeQuickHomework => 'My homework';

  @override
  String get childLearnHomeEmptyTitle => 'No learning path yet';

  @override
  String get childLearnHomeEmptyMessage =>
      'When your parent assigns a lesson, it will appear here. SOS stays available.';

  @override
  String get childLearnHomeEmptyCta => 'SOS';

  @override
  String get childLearnHomeLoadingSemantics => 'Loading my learning';

  @override
  String get childLearnHomeParentLeanTitle => 'Child learning home';

  @override
  String get childLearnHomeParentLeanMessage =>
      'This learn hub is for the child\'s device. Open parent education tools from the studio.';

  @override
  String get childLessonAppBar => 'Lesson';

  @override
  String get childLessonTitleAddingFractions => 'Adding fractions';

  @override
  String get childLessonHookImaginePizza => 'Imagine a pizza!';

  @override
  String get childLessonBodyPizzaFractions =>
      'We split a pizza into 7 slices. You ate 2 (2/7) and your sibling ate 3 (3/7). Together we add only the tops: 2+3=5 — that is 5/7!';

  @override
  String childLessonRewardToast(int minutes) {
    return '+$minutes minutes — you finished this part!';
  }

  @override
  String get childLessonNextCta => 'Got it — next';

  @override
  String get childLessonTutorCta => 'I don\'t get it — ask my tutor';

  @override
  String get childLessonEmptyTitle => 'No lesson open';

  @override
  String get childLessonEmptyMessage =>
      'Open a subject from My learning to start a lesson.';

  @override
  String get childLessonEmptyCta => 'Back to My learning';

  @override
  String get childLessonLoadingSemantics => 'Loading lesson';

  @override
  String get childLessonParentLeanTitle => 'Child lesson';

  @override
  String get childLessonParentLeanMessage =>
      'Lessons play on the child\'s device. Assign content from Studio.';

  @override
  String get childFlashcardsTitle => 'My smart cards';

  @override
  String get childFlashcardsLessonFractionsOps =>
      'Fractions & operations lesson';

  @override
  String get childFlashcardsSourceMathPdf => 'math_chapter_two.pdf';

  @override
  String childFlashcardsSourceLine(String source) {
    return 'Extracted from: $source';
  }

  @override
  String childFlashcardsCounter(int current, int total) {
    return 'Card $current of $total';
  }

  @override
  String get childFlashcardsQOrdinaryFraction =>
      'What is an ordinary fraction?';

  @override
  String get childFlashcardsAOrdinaryFraction =>
      'A number that represents one or more equal parts of a whole, with a numerator and a denominator (example: 3/4).';

  @override
  String get childFlashcardsHPizza => 'Remember the pizza split evenly';

  @override
  String get childFlashcardsQAddNumerators =>
      'When do we add two numerators directly?';

  @override
  String get childFlashcardsAAddNumerators =>
      'When the denominators are exactly the same! Add the numerators and keep the denominator (example: 1/5 + 2/5 = 3/5).';

  @override
  String get childFlashcardsHSameDenom =>
      'Matching denominators stay as they are';

  @override
  String get childFlashcardsSideQuestion => 'Question & concept';

  @override
  String get childFlashcardsSideAnswer => 'Explanation & answer';

  @override
  String get childFlashcardsTapHint =>
      'Tap the card to flip and see the answer';

  @override
  String get childFlashcardsKnownCta => 'I know it';

  @override
  String get childFlashcardsReviewCta => 'Need review';

  @override
  String get childFlashcardsKnownToast =>
      'Great — we will space this out so it sticks';

  @override
  String get childFlashcardsReviewToast =>
      'Honesty is strength — we will repeat this soon';

  @override
  String get childFlashcardsPrevCta => 'Previous';

  @override
  String get childFlashcardsNextCta => 'Next';

  @override
  String get childFlashcardsFirstToast => 'This is the first card';

  @override
  String get childFlashcardsEndToast =>
      'You finished every card! Ready for the quiz';

  @override
  String childFlashcardsQuizCta(int minutes) {
    return 'Start interactive quiz (+$minutes minutes)';
  }

  @override
  String get childFlashcardsEmptyTitle => 'No cards yet';

  @override
  String get childFlashcardsEmptyMessage =>
      'When a parent extracts cards from a lesson, they appear here.';

  @override
  String get childFlashcardsEmptyCta => 'Back to My learning';

  @override
  String get childFlashcardsLoadingSemantics => 'Loading flashcards';

  @override
  String get childFlashcardsParentLeanTitle => 'Child cards';

  @override
  String get childFlashcardsParentLeanMessage =>
      'Flashcards are for the child device. Create materials in Studio.';

  @override
  String get childQuizTitle => 'Skill challenge';

  @override
  String get childQuizSkillDividingFractions => 'Dividing ordinary fractions';

  @override
  String childQuizSkillTag(String skill) {
    return 'Skill: $skill · from your parent';
  }

  @override
  String get childQuizPromptHalfDivQuarter => '1/2 ÷ 1/4 = ?';

  @override
  String childQuizEarnHint(int minutes) {
    return 'Pick the correct answer to earn +$minutes play minutes';
  }

  @override
  String get childQuizOpt2 => '2';

  @override
  String get childQuizOpt1over8 => '1/8';

  @override
  String get childQuizOpt1over2 => '1/2';

  @override
  String get childQuizOpt4 => '4';

  @override
  String get childQuizExplainHalfDivQuarter =>
      'Multiply by the reciprocal: 1/2 × 4/1 = 2.';

  @override
  String childQuizCorrectToast(String explanation, int minutes) {
    return 'Brilliant! $explanation You earned +$minutes minutes.';
  }

  @override
  String get childQuizHintNearMiss =>
      'So close! Flip the second fraction and turn division into multiplication.';

  @override
  String get childQuizHintFlip => 'Not quite — flip 1/4 to become 4/1';

  @override
  String get childQuizHintMultiply => 'Try again — multiply 1/2 by 4';

  @override
  String get childQuizStudyGiftNote =>
      'Study time is a gift — it never deducts from your play minutes';

  @override
  String get childQuizEmptyTitle => 'No quiz yet';

  @override
  String get childQuizEmptyMessage =>
      'When a parent assigns a skill challenge, it opens here.';

  @override
  String get childQuizEmptyCta => 'Back to My learning';

  @override
  String get childQuizLoadingSemantics => 'Loading quiz';

  @override
  String get childQuizParentLeanTitle => 'Child quiz';

  @override
  String get childQuizParentLeanMessage =>
      'Skill quizzes run on the child\'s device.';

  @override
  String get childResultTitle => 'Your result';

  @override
  String childResultScore(int correct, int total) {
    return '$correct of $total';
  }

  @override
  String get childResultPraiseMasteredAdd =>
      'You mastered adding fractions! Your parent got the news.';

  @override
  String get childResultRewardsHeading => 'Your rewards';

  @override
  String get childResultRewardWallet20 => '+20 minutes to your wallet';

  @override
  String get childResultRewardPlay15 => '+15 play minutes';

  @override
  String get childResultRewardBonus30 => '+30 minutes';

  @override
  String get childResultRewardNearLevel4 => 'Getting closer to level 4!';

  @override
  String get childResultTagArrived => 'Arrived';

  @override
  String get childResultTagAdded => 'Added';

  @override
  String get childResultTagProgress370 => '370/500';

  @override
  String get childResultMissedHeading => 'The one question you missed';

  @override
  String get childResultMissedQ7 => 'Q7 — dividing fractions.';

  @override
  String get childResultMissedDivisionOk =>
      'Totally fine — we prepared a short explanation for you.';

  @override
  String get childResultReviewCta => 'Watch the explanation (2 min)';

  @override
  String get childResultHomeCta => 'Back to My learning';

  @override
  String get childResultEmptyTitle => 'No result yet';

  @override
  String get childResultEmptyMessage =>
      'Finish a quiz to see your encouraging result here.';

  @override
  String get childResultEmptyCta => 'Back to My learning';

  @override
  String get childResultLoadingSemantics => 'Loading result';

  @override
  String get childResultParentLeanTitle => 'Child result';

  @override
  String get childResultParentLeanMessage =>
      'Results celebrate progress on the child\'s device.';

  @override
  String get childTutorTitle => 'My tutor';

  @override
  String get childTutorSubtitle => 'Won\'t solve it for you';

  @override
  String get childTutorPolicyBanner =>
      'I help you understand — I never give the ready-made answer. That\'s how you become the hero.';

  @override
  String get childTutorTransparencyNote =>
      'Your parent can see our chats — our home is transparent and safe';

  @override
  String get childTutorBubbleGreetStuck =>
      'Hi! I saw you\'re stuck on 3/5 + 1/2 … where should we start?';

  @override
  String get childTutorBubbleChildDifferentDenom =>
      'I don\'t know how to add them — the bottoms are different!';

  @override
  String get childTutorBubbleLcmPrompt =>
      'Great observation! The secret: we need the bottoms to be the same number. My question: what\'s the smallest number divisible by both 5 and 2?';

  @override
  String get childTutorChoiceTen => '10?';

  @override
  String get childTutorChoiceSeven => '7?';

  @override
  String get childTutorReplyTen =>
      'Exactly! 10 ✓ — now convert 3/5 into tenths…';

  @override
  String get childTutorReplySeven => 'Close! Try: 5×2 equals what?';

  @override
  String get childTutorPhotoCta => 'Photo a problem from your book';

  @override
  String get childTutorPhotoToast =>
      'Photo a problem — I\'ll explain step by step (Stage 1 mock)';

  @override
  String get childTutorEmptyTitle => 'Tutor is ready when you are';

  @override
  String get childTutorEmptyMessage =>
      'Open a lesson or quiz, then ask your tutor for hints — never the full answer.';

  @override
  String get childTutorEmptyCta => 'Back to My learning';

  @override
  String get childTutorLoadingSemantics => 'Loading tutor';

  @override
  String get childTutorParentLeanTitle => 'Child tutor';

  @override
  String get childTutorParentLeanMessage =>
      'The Socratic tutor lives on the child\'s device. Parents see the thread for transparency.';

  @override
  String get childFocusTitle => 'Focus mode';

  @override
  String get childFocusTimerCaption => 'minutes of clear focus';

  @override
  String childFocusTimerSemantics(int minutes) {
    return '$minutes minute focus timer';
  }

  @override
  String get childFocusGiftNote =>
      'During focus, distracting apps quiet down — and this time is a gift that never counts against your play minutes.';

  @override
  String get childFocusHonestyNote =>
      'During focus, distracting apps quiet down — and this time is a gift that never counts against your play minutes.';

  @override
  String childFocusStartCta(int minutes) {
    return 'Start $minutes minutes';
  }

  @override
  String get childFocusRunningCta => 'Focus session running';

  @override
  String get childFocusStartToast =>
      'Focus started — distractions muted. You\'ve got this!';

  @override
  String get childFocusSoundsCta => 'Quiet sounds';

  @override
  String get childFocusPraiseHeading => 'Pride note from a parent:';

  @override
  String get childFocusPraiseResistDistraction =>
      'Proud of you — I noticed you resisting distraction!';

  @override
  String get childFocusEmptyTitle => 'No focus session ready';

  @override
  String get childFocusEmptyMessage =>
      'Open My learning to start a focus gift session.';

  @override
  String get childFocusEmptyCta => 'Back to My learning';

  @override
  String get childFocusLoadingSemantics => 'Loading focus mode';

  @override
  String get childFocusParentLeanTitle => 'Child focus mode';

  @override
  String get childFocusParentLeanMessage =>
      'Focus sessions run on the child\'s device. Assign study time from parent tools.';

  @override
  String get childWalletTitle => 'My wallet';

  @override
  String childWalletTotalMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get childWalletTotalCaption => 'Your total earned minutes balance';

  @override
  String childWalletStreakAndBadges(int days, int badges) {
    return '$days streak days · $badges badges';
  }

  @override
  String get childWalletCompeteHeading => 'Compete with yourself — no one else';

  @override
  String childWalletRecordLine(int days) {
    return 'Your record: $days streak days';
  }

  @override
  String childWalletCurrentStreakLine(int days) {
    return 'You are on $days now — close to beating your record!';
  }

  @override
  String get childWalletBadgesHeading => 'My badge vault';

  @override
  String get childWalletBadgeFirstWird => 'First wird';

  @override
  String get childWalletBadgeAdhkarWeek => 'Adhkar week';

  @override
  String get childWalletBadgeFocusFive => '5 focus sessions';

  @override
  String get childWalletBadgeMonthStreak => 'Month streak';

  @override
  String get childWalletBadgeFamilyHero => 'Family hero';

  @override
  String childWalletBadgesFootnote(int count) {
    return '$count badges earned — more ahead';
  }

  @override
  String get childWalletBadgesNotCurrency =>
      'Badges are pride — minutes are earned only by real work.';

  @override
  String get childWalletAppsHeading => 'My app wallets';

  @override
  String get childWalletAppsCaption =>
      'Each app has its own minutes wallet — blocked apps stay closed.';

  @override
  String get childWalletAppYoutube => 'YouTube';

  @override
  String get childWalletAppGames => 'Games';

  @override
  String get childWalletAppSocial => 'Social';

  @override
  String get childWalletAppQuran => 'Quran';

  @override
  String get childWalletSimulatedTag => 'Demo · Simulated';

  @override
  String childWalletAppBalance(int minutes) {
    return 'Balance: $minutes minutes';
  }

  @override
  String get childWalletAppNoBalance => 'No balance yet — earn with a task!';

  @override
  String childWalletMinutesTag(int minutes) {
    return '$minutes m';
  }

  @override
  String get childWalletZeroTag => '0';

  @override
  String get childWalletEarnHeading => 'How do I earn minutes?';

  @override
  String get childWalletEarnQuranTitle => 'My Quran wird';

  @override
  String get childWalletEarnQuranBody => 'Finish it and earn what Dad set';

  @override
  String get childWalletEarnTasksTitle => 'My tasks';

  @override
  String get childWalletEarnTasksBody => 'Every task = minutes Dad chooses';

  @override
  String get childWalletEarnQuizTitle => 'Learning challenges';

  @override
  String get childWalletEarnQuizBody => 'Learn more, play more';

  @override
  String get childWalletEmptyTitle => 'Wallet is empty';

  @override
  String get childWalletEmptyMessage =>
      'Earn minutes with tasks and learning — badges stay pride only.';

  @override
  String get childWalletEmptyCta => 'Back to My learning';

  @override
  String get childWalletLoadingSemantics => 'Loading wallet';

  @override
  String get childWalletParentLeanTitle => 'Child wallet';

  @override
  String get childWalletParentLeanMessage =>
      'Minutes wallets and pride badges live on the child\'s device.';

  @override
  String get childTimeRequestTitle => 'Extra time request';

  @override
  String get childTimeRequestHowMuch => 'How much time do you need?';

  @override
  String get childTimeRequestMins15 => '15 minutes';

  @override
  String get childTimeRequestMins30 => '30 minutes';

  @override
  String get childTimeRequestMins60 => 'Full hour';

  @override
  String get childTimeRequestReasonLabel => 'Why? (so your parents know)';

  @override
  String get childTimeRequestReasonFinishedHomework =>
      'I finished my homework and want to keep playing with a friend';

  @override
  String get childTimeRequestTradeHeading =>
      'Smart trade wheel (offer good work)';

  @override
  String get childTimeRequestTradeCaption =>
      'Pick work you will do for extra minutes — it raises approval odds.';

  @override
  String get childTimeRequestTradeWird => 'Today\'s wird from Surah Al-Mulk';

  @override
  String get childTimeRequestTradeTidy => 'Tidy desk and room';

  @override
  String get childTimeRequestTradeMath => 'Review math lesson';

  @override
  String get childTimeRequestTradeDirect => 'Direct ask without a trade';

  @override
  String get childTimeRequestSubmitCta => 'Send negotiation to my parents';

  @override
  String get childTimeRequestSubmitToast =>
      'Your request reached your parents — they will reply with the trade.';

  @override
  String get childTimeRequestStatusPendingTitle =>
      'Your request is with your parent now';

  @override
  String childTimeRequestStatusPendingBody(int minutes) {
    return 'You asked for $minutes minutes — a reply is coming.';
  }

  @override
  String childTimeRequestStatusApprovedTitle(int minutes) {
    return 'Approved — $minutes minutes by your parent\'s choice';
  }

  @override
  String get childTimeRequestStatusApprovedBody =>
      'Minutes added as a temporary grant for today — enjoy them wisely.';

  @override
  String get childTimeRequestStatusTaskedTitle =>
      'Your parent says: time is earned!';

  @override
  String childTimeRequestStatusTaskedBody(String task, int minutes) {
    return 'Finish «$task» and $minutes minutes deposit automatically.';
  }

  @override
  String get childTimeRequestTaskTidyDesk => 'Tidy the desk';

  @override
  String get childTimeRequestGoTasksCta => 'To my tasks';

  @override
  String get childTimeRequestStatusRejectedTitle => 'Not right now, dear one';

  @override
  String get childTimeRequestStatusRejectedBody =>
      'Your parent declined kindly — try tomorrow, or earn minutes with a task now.';

  @override
  String get childTimeRequestEmptyTitle => 'Requests unavailable';

  @override
  String get childTimeRequestEmptyMessage =>
      'When extra-time requests open, this form appears. SOS stays available.';

  @override
  String get childTimeRequestEmptyCta => 'Back to my day';

  @override
  String get childTimeRequestLoadingSemantics => 'Loading time request';

  @override
  String get childTimeRequestParentLeanTitle => 'Child time request';

  @override
  String get childTimeRequestParentLeanMessage =>
      'Extra-time requests are sent from the child\'s device to the parent inbox.';

  @override
  String get childTimeRequestStatusExpiredTitle => 'Request expired';

  @override
  String get childTimeRequestStatusExpiredBody =>
      'This request timed out — you can send a new one.';

  @override
  String get childTimeRequestDuplicateError =>
      'You already have a pending request — wait for your parent\'s reply.';

  @override
  String get enforcementSimulatedLabel => 'SIMULATED';

  @override
  String get remainingMinutesCardTitle => 'Remaining minutes';

  @override
  String get remainingMinutesDailyLabel => 'Daily remaining';

  @override
  String get remainingMinutesGrantLabel => 'Temporary grant';

  @override
  String get remainingMinutesWalletLabel => 'Earned wallet';

  @override
  String remainingMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String timeWarningBannerMessage(int minutes) {
    return 'Only $minutes minutes left today — wrap up soon.';
  }

  @override
  String get childTasksTitle => 'My tasks';

  @override
  String get childTasksHeroCaption =>
      'Finish tasks and earn extra play minutes!';

  @override
  String get childTasksHeroHeadline =>
      'Every task you finish brings you closer to your reward';

  @override
  String get childTasksTodayHeading => 'Your tasks today';

  @override
  String get childTasksTitleTidyRoom => 'Tidy my room';

  @override
  String get childTasksTitleMathReview => 'Review math lesson';

  @override
  String get childTasksTitleWirdDone => 'Finish today\'s wird';

  @override
  String childTasksRewardLine(int minutes) {
    return 'Reward: +$minutes minutes to wallet';
  }

  @override
  String get childTasksSubmitCta => 'I finished it';

  @override
  String get childTasksSubmitToast =>
      'Proof sent — waiting for parent confirmation (Stage 1 mock)';

  @override
  String get childTasksTagPending => 'Awaiting confirmation';

  @override
  String get childTasksTagRewarded => 'Reward deposited';

  @override
  String get childTasksEmptyTitle => 'No tasks yet';

  @override
  String get childTasksEmptyMessage =>
      'When your parent assigns a task it appears here with its minutes reward.';

  @override
  String get childTasksEmptyCta => 'Back to my day';

  @override
  String get childTasksLoadingSemantics => 'Loading tasks';

  @override
  String get childTasksParentLeanTitle => 'Child tasks';

  @override
  String get childTasksParentLeanMessage =>
      'Task completion and proof live on the child\'s device. Parents approve from the family board.';

  @override
  String get childMediaShareTitle => 'Share media';

  @override
  String get childMediaShareHeroHeadline => 'Share a moment';

  @override
  String get childMediaShareQuickPhoto => 'Photo';

  @override
  String get childMediaShareQuickVoice => 'Voice';

  @override
  String get childMediaShareQuickFile => 'File';

  @override
  String get childMediaSharePhotoToast => 'Capture and share with your family';

  @override
  String get childMediaShareVoiceToast =>
      'Hold to record — it arrives transcribed too (P1)';

  @override
  String get childMediaShareFileToast => 'Share a homework file';

  @override
  String get childMediaShareRecentHeading => 'My recent shares';

  @override
  String get childMediaShareTitlePhotoGoal => 'Match-day goal';

  @override
  String get childMediaShareSubPhotoGoal => 'Family group · Dad liked';

  @override
  String get childMediaShareTitleVoiceShoes => '«Mom, where are my shoes?»';

  @override
  String get childMediaShareSubVoiceShoes => 'Arrived transcribed to text too';

  @override
  String get childMediaShareSafeCircleBanner =>
      'Your shares stay inside your family circle only — they never leave.';

  @override
  String get childMediaShareEmptyTitle => 'No shares yet';

  @override
  String get childMediaShareEmptyMessage =>
      'Share photos, voice notes, or files safely with your family from here.';

  @override
  String get childMediaShareEmptyCta => 'Back to my chats';

  @override
  String get childMediaShareLoadingSemantics => 'Loading media share';

  @override
  String get childMediaShareParentLeanTitle => 'Child media share';

  @override
  String get childMediaShareParentLeanMessage =>
      'Media sharing runs on the child\'s device inside the closed family circle.';

  @override
  String get childMediaSharePhotoSemantics => 'Share a photo with family';

  @override
  String get childMediaShareVoiceSemantics =>
      'Record and share a voice message';

  @override
  String get childMediaShareFileSemantics => 'Share a file with family';

  @override
  String get childArrivalTitle => 'I arrived';

  @override
  String get childArrivalHeadline => 'Where did you arrive, champion?';

  @override
  String get childArrivalSubtitle =>
      'Tap a place to reassure your parents in one touch:';

  @override
  String get childArrivalZoneSchool => 'School';

  @override
  String get childArrivalZoneSchoolDesc => 'Secondary school area';

  @override
  String get childArrivalZoneHome => 'Home';

  @override
  String get childArrivalZoneHomeDesc => 'Neighborhood safe zone';

  @override
  String childArrivalZoneCta(String place) {
    return 'Arrived at $place';
  }

  @override
  String childArrivalCheckInToast(String place) {
    return 'Reassurance sent to your parents: «Arrived at $place»';
  }

  @override
  String get childArrivalLiveHeading => 'Your live location';

  @override
  String get childArrivalLiveConnected => 'Connected now at high accuracy';

  @override
  String get childArrivalSafeTag => 'Safe';

  @override
  String get childArrivalEmptyTitle => 'No safe places yet';

  @override
  String get childArrivalEmptyMessage =>
      'When your parent adds safe zones, one-tap check-in appears here.';

  @override
  String get childArrivalEmptyCta => 'Back to my day';

  @override
  String get childArrivalLoadingSemantics => 'Loading arrival check-in';

  @override
  String get childArrivalParentLeanTitle => 'Child arrival';

  @override
  String get childArrivalParentLeanMessage =>
      'Check-in lives on the child\'s device. Parents manage safe zones from the map.';

  @override
  String get smartAlertsTitle => 'Smart watch';

  @override
  String get smartAlertsHonestyBanner =>
      'Watching here is transparent — your child knows Family Advisor protects their chats. No spying in our home.';

  @override
  String get smartAlertsAlertWithdrawal => 'Withdrawal pattern in chats';

  @override
  String get smartAlertsAlertWithdrawalSub => 'Emotion analysis · last 5 days';

  @override
  String get smartAlertsAlertArabizi => 'Suspicious Arabizi phrase spotted';

  @override
  String get smartAlertsAlertArabiziSub =>
      'Transliterated slang from an unknown contact';

  @override
  String get smartAlertsTagNew => 'New';

  @override
  String get smartAlertsTagYesterday => 'Yesterday';

  @override
  String get smartAlertsTagActive => 'Active';

  @override
  String get smartAlertsWatchHeading => 'What Family Advisor watches';

  @override
  String get smartAlertsWatchKeywords => 'Suspicious words';

  @override
  String get smartAlertsWatchKeywordsSub =>
      'Formal, dialect, and Arabizi — a rare capability';

  @override
  String get smartAlertsWatchEmotions => 'Emotion analysis';

  @override
  String get smartAlertsWatchEmotionsSub =>
      'Sadness, fear, withdrawal patterns';

  @override
  String get smartAlertsWatchImages => 'Sensitive images + sexual messages';

  @override
  String get smartAlertsWatchImagesSub => 'Instant block, then notify you';

  @override
  String get smartAlertsToolsHeading => 'Watch tools — you turn them on';

  @override
  String get smartAlertsToolSearchScan => 'Search-bar analysis';

  @override
  String get smartAlertsToolSearchScanSub =>
      'Any search in any app — formal, dialect, Arabizi';

  @override
  String get smartAlertsToolImageScan => 'On-device image classification';

  @override
  String get smartAlertsToolImageScanSub =>
      'Classifies locally — images never leave the device';

  @override
  String get smartAlertsToolScreenshot => 'Screenshot on app open';

  @override
  String get smartAlertsToolScreenshotSub => 'Only for apps you choose';

  @override
  String get smartAlertsToolOffline => 'Works offline';

  @override
  String get smartAlertsToolOfflineSub =>
      'Local analysis — reports sync when network returns';

  @override
  String get smartAlertsDetectHeading => 'When unsuitable content is found';

  @override
  String get smartAlertsDetectBody =>
      '1. Instant block on the child\'s device\n2. Encrypted snapshot saved on your device\n3. A report reaches you: app, time, reason — you choose the next step';

  @override
  String get smartAlertsSettingsCta => 'Advanced settings';

  @override
  String get smartAlertsEmptyTitle => 'No smart alerts yet';

  @override
  String get smartAlertsEmptyMessage =>
      'When Family Advisor spots a pattern, amber alerts appear here — describing behavior, never judging the child.';

  @override
  String get smartAlertsEmptyCta => 'Add a child';

  @override
  String get smartAlertsLoadingSemantics => 'Loading smart alerts';

  @override
  String get smartAlertsChildLeanTitle => 'Smart watch';

  @override
  String get smartAlertsChildLeanMessage =>
      'Smart alerts are for parents. Your device shows that protection is on — honesty builds trust.';

  @override
  String get smartAlertDetailTitle => 'Alert: withdrawal pattern';

  @override
  String get smartAlertDetailBehaviorBanner =>
      'This alert describes a behavior Family Advisor noticed — not a judgment on your child.';

  @override
  String get smartAlertDetailChangesHeading => 'What changed?';

  @override
  String get smartAlertDetailChangeShorter => 'Replies are ~60% shorter';

  @override
  String get smartAlertDetailChangeShorterSub =>
      'Compared with their usual week';

  @override
  String get smartAlertDetailChangeLateNights => 'Late-night activity';

  @override
  String get smartAlertDetailChangeLateNightsSub => 'Three nights after 11 PM';

  @override
  String get smartAlertDetailChangeSadWords => 'Sad words repeated';

  @override
  String get smartAlertDetailChangeSadWordsSub =>
      'Worn-out / no energy phrases';

  @override
  String get smartAlertDetailDialogueHeading => 'Suggested dialogue step';

  @override
  String get smartAlertDetailDialogueQuote =>
      '«I\'ve noticed you\'ve seemed tired these days… want to go for a walk and talk?»';

  @override
  String get smartAlertDetailDialogueHint =>
      'Start with care, not interrogation — and don\'t mention the app.';

  @override
  String get smartAlertDetailScheduleCta => 'Schedule time together';

  @override
  String get smartAlertDetailScheduleToast =>
      'Added to your calendar: a walk together tomorrow afternoon';

  @override
  String get smartAlertDetailSilentCta => 'Quiet follow for a week';

  @override
  String get smartAlertDetailSilentToast =>
      'Family Advisor will keep watching the pattern and update you — without bothering your child';

  @override
  String get smartAlertDetailEmptyTitle => 'No alert detail';

  @override
  String get smartAlertDetailEmptyMessage =>
      'Open an amber alert from Smart watch to see context and a dialogue step.';

  @override
  String get smartAlertDetailEmptyCta => 'Back to smart watch';

  @override
  String get smartAlertDetailLoadingSemantics => 'Loading alert detail';

  @override
  String get smartAlertDetailChildLeanTitle => 'Alert detail';

  @override
  String get smartAlertDetailChildLeanMessage =>
      'Alert details and dialogue steps are for parents. Your device stays honest that protection is on.';

  @override
  String get childUsageReportTitle => 'Child usage report';

  @override
  String childUsageReportHeading(String name) {
    return 'Report for $name';
  }

  @override
  String get childUsageReportThisWeek => 'This week';

  @override
  String childUsageReportWeekTotal(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get childUsageReportDaySat => 'Sa';

  @override
  String get childUsageReportDaySun => 'Su';

  @override
  String get childUsageReportDayMon => 'Mo';

  @override
  String get childUsageReportDayTue => 'Tu';

  @override
  String get childUsageReportDayWed => 'We';

  @override
  String get childUsageReportDayThu => 'Th';

  @override
  String get childUsageReportDayFri => 'Fr';

  @override
  String get childUsageReportWhereHeading => 'Where did the time go?';

  @override
  String get childUsageReportCatLearning => 'Learning';

  @override
  String get childUsageReportCatGames => 'Games';

  @override
  String get childUsageReportCatChat => 'Chat';

  @override
  String childUsageReportCatHours(String label, int hours) {
    return '$label — ${hours}h';
  }

  @override
  String get childUsageReportGiftNote => 'Gift — not counted toward the limit';

  @override
  String childUsageReportRetentionBanner(int days) {
    return 'Data is kept for $days days only, then erased — and the Forget button (Settings) erases it immediately. Privacy is a promise, not a slogan.';
  }

  @override
  String get childUsageReportChildOne => 'Child One';

  @override
  String get childUsageReportChildTwo => 'Child Two';

  @override
  String get childUsageReportChildThree => 'Child Three';

  @override
  String get childUsageReportEmptyTitle => 'No usage report yet';

  @override
  String get childUsageReportEmptyMessage =>
      'Add a child to see weekly usage, category breakdown, and 30-day retention honesty.';

  @override
  String get childUsageReportEmptyCta => 'Add a child';

  @override
  String get childUsageReportLoadingSemantics => 'Loading usage report';

  @override
  String get childUsageReportChildLeanTitle => 'Usage report';

  @override
  String get childUsageReportChildLeanMessage =>
      'Detailed usage reports are for parents. Your device stays honest that protection is on.';

  @override
  String get childUsageReportSosCta => 'Emergency SOS';

  @override
  String get outerCircleTitle => 'Trusted outer circle';

  @override
  String get outerCircleStrangersBanner =>
      'Strangers are always blocked: this protects your children automatically. Every external contact needs parent approval.';

  @override
  String get outerCircleRelativesHeading => 'Trusted relatives';

  @override
  String get outerCircleFriendsHeading => 'Approved friends';

  @override
  String get outerCircleScheduleHeading => 'External contact schedule';

  @override
  String get outerCircleScheduleFriendsEvening =>
      'Friends: after school until Maghrib (4–7 PM) · Relatives: always open';

  @override
  String get outerCircleNameGrandpa => 'Grandpa';

  @override
  String get outerCircleNameAunt => 'Aunt';

  @override
  String get outerCircleNameFriendOne => 'Friend One';

  @override
  String get outerCircleNamePendingFriend => 'Pending Friend';

  @override
  String get outerCircleMetaCallsAnytime => 'Calls + messages anytime';

  @override
  String get outerCircleMetaMessagesCalls => 'Messages and calls';

  @override
  String get outerCircleMetaClassmateSlot =>
      'Approved classmate · contact window 4–7 PM';

  @override
  String get outerCircleMetaClassmatePending =>
      'Classmate · waiting for your decision';

  @override
  String get outerCircleStatusApproved => 'Approved ✓';

  @override
  String get outerCircleStatusAlwaysApproved => 'Always approved';

  @override
  String get outerCircleStatusPending => 'Pending';

  @override
  String outerCirclePendingTitle(String name) {
    return '$name — new request';
  }

  @override
  String get outerCirclePendingCta => 'Decide →';

  @override
  String outerCirclePendingSemantics(String name) {
    return 'Pending friend request from $name';
  }

  @override
  String get outerCircleEmptyTitle => 'Outer circle is empty';

  @override
  String get outerCircleEmptyMessage =>
      'Add a child to manage trusted relatives and approved friends. Strangers stay blocked.';

  @override
  String get outerCircleEmptyCta => 'Add a child';

  @override
  String get outerCircleLoadingSemantics => 'Loading outer circle';

  @override
  String get outerCircleChildLeanTitle => 'Outer circle';

  @override
  String get outerCircleChildLeanMessage =>
      'Trusted contacts are managed by parents. Your chats stay with people they approve.';

  @override
  String get outerCircleSosCta => 'Emergency SOS';

  @override
  String get friendApprovalTitle => 'New friend request';

  @override
  String get friendApprovalNamePending => 'Pending Friend';

  @override
  String get friendApprovalSchoolClassmate => 'classmate at the light school';

  @override
  String get friendApprovalChildOne => 'Child One';

  @override
  String get friendApprovalChildTwo => 'Child Two';

  @override
  String get friendApprovalChildThree => 'Child Three';

  @override
  String friendApprovalProfileSub(String child, String school) {
    return '$child\'s classmate ($school) — request sent today';
  }

  @override
  String get friendApprovalChannelsHeading => 'Allowed channels';

  @override
  String get friendApprovalChannelText => 'Safe text messages';

  @override
  String get friendApprovalChannelCalls => 'Voice calls';

  @override
  String get friendApprovalChannelSchedule => 'Within contact schedule';

  @override
  String get friendApprovalChannelScheduleSub => '4–7 PM only';

  @override
  String get friendApprovalScheduleAutoTag => 'Automatic';

  @override
  String get friendApprovalApproveCta => 'Approve as a safe friend';

  @override
  String get friendApprovalDeclineCta => 'Not now (gentle reply)';

  @override
  String friendApprovalApprovedToast(String name, String child) {
    return '$name approved as a safe friend — $child was notified with joy';
  }

  @override
  String friendApprovalDeclinedToast(String child, String name) {
    return 'Gentle reply sent to $child: «$name\'s request needs time — we\'ll talk together»';
  }

  @override
  String get friendApprovalObserverHint =>
      'Approving friends needs Partner level or above — you can review this request.';

  @override
  String get friendApprovalObserverBlocked =>
      'Approving friends needs Partner level or above';

  @override
  String get friendApprovalEmptyTitle => 'No pending friend request';

  @override
  String get friendApprovalEmptyMessage =>
      'Open Outer circle when a new classmate request is waiting for your decision.';

  @override
  String get friendApprovalEmptyCta => 'Back to outer circle';

  @override
  String get friendApprovalLoadingSemantics => 'Loading friend request';

  @override
  String get friendApprovalChildLeanTitle => 'Friend approval';

  @override
  String get friendApprovalChildLeanMessage =>
      'Parents approve new friends. You already know your trusted circle stays safe.';

  @override
  String get friendApprovalSosCta => 'Emergency SOS';

  @override
  String get quranProgressTitle => 'Quran ward progress';

  @override
  String quranProgressHeading(String name) {
    return 'Memorization & recitation — $name';
  }

  @override
  String get quranProgressActiveWardTag => 'Active ward';

  @override
  String get quranProgressOfflineTag => 'Offline ready';

  @override
  String quranProgressSurahTitle(String surah) {
    return 'Surah $surah';
  }

  @override
  String quranProgressAyahRange(int from, int to, String reciter) {
    return 'Ayahs ($from–$to) · voice of $reciter';
  }

  @override
  String quranProgressCompleted(int done, int total) {
    return 'Done $done of $total ayahs';
  }

  @override
  String quranProgressStreak(int days) {
    return '🔥 $days days streak';
  }

  @override
  String quranProgressDownloadHeading(String name) {
    return 'Download board for $name\'s device';
  }

  @override
  String get quranProgressInstalledTag => 'Installed ✓';

  @override
  String quranProgressDownloadBody(String surah, String size, String name) {
    return 'Audio for Surah «$surah» is on $name\'s device ($size) and available offline for listening and practice.';
  }

  @override
  String quranProgressDownloadCta(String name) {
    return 'Download a new surah or reciter for $name';
  }

  @override
  String quranProgressDownloadToast(String name) {
    return 'Download queued for $name\'s device';
  }

  @override
  String get quranProgressRecitationHeading => 'New recitation waiting for you';

  @override
  String get quranProgressNewTag => 'New';

  @override
  String get quranProgressApprovedTag => 'Approved ✓';

  @override
  String quranProgressRecitationSub(String name, String surah) {
    return '$name recorded Surah $surah (ayahs 16–20):';
  }

  @override
  String quranProgressRecitationClip(String name, String surah) {
    return '$name\'s recitation — Surah $surah';
  }

  @override
  String get quranProgressClipDuration => '1:24';

  @override
  String get quranProgressPlaySemantics => 'Play or pause recitation';

  @override
  String quranProgressApproveCta(int minutes) {
    return 'Approve & reward (+$minutes min)';
  }

  @override
  String get quranProgressWhisperCta => 'Whisper 💬';

  @override
  String quranProgressApproveToast(String name, int minutes) {
    return 'Approved $name\'s recitation and added +$minutes minutes of play';
  }

  @override
  String quranProgressWhisperToast(String name) {
    return 'Encouraging whisper sent to $name';
  }

  @override
  String quranProgressApprovedBanner(int minutes) {
    return '⭐ This ward was approved and +$minutes minutes rewarded';
  }

  @override
  String get quranProgressPlanHeading => 'Ward plan & reward';

  @override
  String get quranProgressPlanSurah => 'Current surah';

  @override
  String get quranProgressPlanReciter => 'Reciter';

  @override
  String get quranProgressPlanReward => 'Completion reward';

  @override
  String quranProgressPlanRewardValue(int minutes) {
    return '+$minutes play minutes to the wallet';
  }

  @override
  String get quranProgressSurahNaba => 'An-Naba';

  @override
  String get quranProgressReciterDefault => 'default reciter';

  @override
  String get quranProgressAudioSize184 => '18.4 MB';

  @override
  String get quranProgressChildOne => 'Child One';

  @override
  String get quranProgressChildTwo => 'Child Two';

  @override
  String get quranProgressChildThree => 'Child Three';

  @override
  String get quranProgressObserverHint =>
      'Approving recitation needs Partner level or above — you can review progress.';

  @override
  String get quranProgressObserverBlocked =>
      'Approving Quran rewards needs Partner level or above';

  @override
  String get quranProgressEmptyTitle => 'No Quran ward yet';

  @override
  String get quranProgressEmptyMessage =>
      'Add a child to set a ward plan, download offline audio, and approve recitations with minutes rewards.';

  @override
  String get quranProgressEmptyCta => 'Add a child';

  @override
  String get quranProgressLoadingSemantics => 'Loading Quran progress';

  @override
  String get quranProgressChildLeanTitle => 'Quran progress';

  @override
  String get quranProgressChildLeanMessage =>
      'Parents follow your ward and approve recitations. Your Quran time is never locked by expiry.';

  @override
  String get quranProgressSosCta => 'Emergency SOS';

  @override
  String get weeklyReportTitle => 'Weekly report with one tip';

  @override
  String get weeklyReportSettingsHeading => 'Your report settings';

  @override
  String get weeklyReportSettingsTag => 'Updates the report instantly';

  @override
  String get weeklyReportWhenLabel => 'Timing';

  @override
  String get weeklyReportWhenFriday => 'Friday morning';

  @override
  String get weeklyReportWhenSaturday => 'Saturday evening';

  @override
  String weeklyReportWhenToast(String when) {
    return 'Report timing: $when';
  }

  @override
  String get weeklyReportStyleLabel => 'Format';

  @override
  String get weeklyReportStyleDetailed => 'Detailed';

  @override
  String get weeklyReportStyleBrief => 'Brief';

  @override
  String get weeklyReportChangeCta => 'Change';

  @override
  String get weeklyReportToggleCta => 'Switch';

  @override
  String get weeklyReportIncScreen => 'Screen time';

  @override
  String get weeklyReportIncPlaces => 'Places';

  @override
  String get weeklyReportIncWins => 'Wins';

  @override
  String get weeklyReportIncQuran => 'Quran';

  @override
  String get weeklyReportIncWatch => 'Smart watch';

  @override
  String get weeklyReportRecommendHeading => 'This week\'s tip — one only';

  @override
  String weeklyReportRecommendBody(String name) {
    return '$name\'s math is steadily improving, but sleep runs late Thursday and Friday and focus dips on Saturday. Try shifting Sleep mode 30 minutes earlier on weekends.';
  }

  @override
  String get weeklyReportApplyCta => 'Apply suggestion';

  @override
  String get weeklyReportDeferCta => 'Not now';

  @override
  String get weeklyReportApplyToast =>
      'Sleep schedule adjusted — gentle steps over two weeks';

  @override
  String get weeklyReportDeferToast =>
      'Alright — Family Advisor will reassess next Friday';

  @override
  String get weeklyReportAppliedBanner =>
      '✓ Suggestion applied with your approval';

  @override
  String get weeklyReportDeferredBanner =>
      'Deferred until the next Friday review';

  @override
  String get weeklyReportMetricLearn => 'Learning';

  @override
  String get weeklyReportMetricSleep => 'Sleep';

  @override
  String weeklyReportLearnDelta(int percent) {
    return '↑ $percent%';
  }

  @override
  String weeklyReportSleepDelta(int minutes) {
    return '↓ $minutes m';
  }

  @override
  String get weeklyReportSecScreenTitle => 'Screen time';

  @override
  String get weeklyReportSecScreenBody =>
      'Average 2h 12m daily — within the limit. Thursday was highest (3h).';

  @override
  String get weeklyReportSecPlacesTitle => 'Places';

  @override
  String get weeklyReportSecPlacesBody =>
      'All moves stayed inside safe zones. One new place noted this week.';

  @override
  String get weeklyReportSecWinsTitle => 'Wins';

  @override
  String weeklyReportSecWinsBody(String one, String two, String three) {
    return '$one: full ward + 5 focus sessions · $two: science challenge · $three: athkar 7/7.';
  }

  @override
  String get weeklyReportSecQuranTitle => 'Quran';

  @override
  String get weeklyReportSecQuranBody =>
      'Surah An-Naba: 27/40 ayahs — Tuesday recitation approved.';

  @override
  String get weeklyReportSecWatchTitle => 'Smart watch';

  @override
  String get weeklyReportSecWatchBody =>
      'Two amber alerts — handled with dialogue. Nothing red.';

  @override
  String get weeklyReportEmailBanner =>
      'An email copy reached you — and a level-matched summary for the mother partner.';

  @override
  String get weeklyReportChildOne => 'Child One';

  @override
  String get weeklyReportChildTwo => 'Child Two';

  @override
  String get weeklyReportChildThree => 'Child Three';

  @override
  String get weeklyReportObserverHint =>
      'Applying tips needs Partner level or above — you can still read the report.';

  @override
  String get weeklyReportObserverBlocked =>
      'Changing the weekly report needs Partner level or above';

  @override
  String get weeklyReportEmptyTitle => 'No weekly report yet';

  @override
  String get weeklyReportEmptyMessage =>
      'Add a child to receive one focused tip plus section summaries each week.';

  @override
  String get weeklyReportEmptyCta => 'Add a child';

  @override
  String get weeklyReportLoadingSemantics => 'Loading weekly report';

  @override
  String get weeklyReportChildLeanTitle => 'Weekly report';

  @override
  String get weeklyReportChildLeanMessage =>
      'Weekly tips are for parents. Your device stays honest that protection is on.';

  @override
  String get weeklyReportSosCta => 'Emergency SOS';

  @override
  String get familyAdvisorHubTitle => 'Family Advisor';

  @override
  String get familyAdvisorHubGreeting => 'Good evening';

  @override
  String get familyAdvisorHubSubtitle => 'How can I help your family today?';

  @override
  String get familyAdvisorHubChipDay => 'How was my children\'s day?';

  @override
  String get familyAdvisorHubChipWeekly =>
      'Give me the weekly report with a tip';

  @override
  String get familyAdvisorHubChipActivity =>
      'Suggest a family activity for our weekend';

  @override
  String get familyAdvisorHubChipPatterns => 'Show me our family patterns';

  @override
  String get familyAdvisorHubSheetDay =>
      'A calm day: lessons finished, ward done, and one low-battery note — praise first.';

  @override
  String get familyAdvisorHubSheetActivity =>
      'Weather looks gentle tomorrow — a nursery visit then planting a seedling together?';

  @override
  String get familyAdvisorHubCapsHeading => 'Family Advisor capabilities';

  @override
  String get familyAdvisorHubSovHeading => 'You remain the advisor\'s owner';

  @override
  String get familyAdvisorHubCapVoice => 'Voice conversation';

  @override
  String get familyAdvisorHubCapVoiceSub => 'Talk while your hands are busy';

  @override
  String get familyAdvisorHubCapDelegate => 'Delegated assistant';

  @override
  String get familyAdvisorHubCapDelegateSub =>
      'Runs only what you delegated in writing';

  @override
  String get familyAdvisorHubCapMaps => 'Children knowledge maps';

  @override
  String get familyAdvisorHubCapMapsSub =>
      'Where each child thrives and struggles';

  @override
  String get familyAdvisorHubCapMother => 'Mother notifications';

  @override
  String get familyAdvisorHubCapMotherSub => 'What she receives by her level';

  @override
  String get familyAdvisorHubCapLimits => 'Advisor limits & permissions';

  @override
  String get familyAdvisorHubCapLimitsSub =>
      'What it sees — your decision always';

  @override
  String get familyAdvisorHubCapAgentLog => 'What the assistant did';

  @override
  String get familyAdvisorHubCapAgentLogSub =>
      'Permanent log of delegated actions';

  @override
  String get familyAdvisorHubHonestyQ =>
      'Does Child One use YouTube while studying?';

  @override
  String get familyAdvisorHubHonestyA =>
      'I don\'t know with enough precision. Concurrent-play monitoring is off on that device — I tell you my limits instead of guessing. Shall I enable it for you?';

  @override
  String get familyAdvisorHubAskHint => 'Ask anything about your family…';

  @override
  String get familyAdvisorHubAskSendSemantics => 'Send question';

  @override
  String get familyAdvisorHubAskToast =>
      'Thinking… answers come from your family data only — with honest «I don\'t know» when short';

  @override
  String get familyAdvisorHubFooter =>
      'Answers from your family data only · never invents';

  @override
  String get familyAdvisorHubEmptyTitle => 'Family Advisor is waiting';

  @override
  String get familyAdvisorHubEmptyMessage =>
      'Add a child so the advisor can answer from real family data — never inventing.';

  @override
  String get familyAdvisorHubEmptyCta => 'Add a child';

  @override
  String get familyAdvisorHubLoadingSemantics => 'Loading Family Advisor';

  @override
  String get familyAdvisorHubChildLeanTitle => 'Family Advisor';

  @override
  String get familyAdvisorHubChildLeanMessage =>
      'Family Advisor chats are for parents. Your tutor and Quran tools stay available.';

  @override
  String get familyAdvisorHubSosCta => 'Emergency SOS';

  @override
  String get motherAiFeedTitle => 'Mother AI notifications';

  @override
  String get motherAiFeedFatherWatchBanner =>
      'You are viewing what reaches your partner — in her board identity';

  @override
  String get motherAiFeedWelcomeBanner =>
      'As a parenting partner you can send love whispers to children or tips to the father in one tap.';

  @override
  String get motherAiFeedWhisperHeading => 'Whisper & tip for today';

  @override
  String get motherAiFeedPartnershipTag => 'Parent partnership';

  @override
  String motherAiFeedWhisperBody(String name) {
    return '«$name looks tired after club practice today — shall we move bedtime 30 minutes earlier and make it up with extra play tomorrow?»';
  }

  @override
  String get motherAiFeedWhisperCta => 'Send tip to father & child';

  @override
  String get motherAiFeedWhisperToast =>
      'Whisper and tip sent — father notified, child encouraged';

  @override
  String get motherAiFeedWhisperSentBanner => '✓ Whisper sent with love';

  @override
  String get motherAiFeedSummariesHeading => 'Advisor summaries for you';

  @override
  String get motherAiFeedItemWeekTitle => 'Weekly parenting summary';

  @override
  String motherAiFeedItemMathBody(String name) {
    return '$name improved in math by +15%';
  }

  @override
  String get motherAiFeedItemSleepTitle => 'Sleep note';

  @override
  String motherAiFeedItemSleepBody(String name) {
    return '$name\'s weekend bedtime slipped later';
  }

  @override
  String get motherAiFeedTagExcellent => 'Excellent';

  @override
  String get motherAiFeedTagGood => 'Good';

  @override
  String get motherAiFeedTagWatch => 'Watch';

  @override
  String get motherAiFeedChildOne => 'Child One';

  @override
  String get motherAiFeedObserverHint =>
      'Sending whispers needs Partner level or above — you can read summaries.';

  @override
  String get motherAiFeedObserverBlocked =>
      'Sending mother tips needs Partner level or above';

  @override
  String get motherAiFeedEmptyTitle => 'No mother feed yet';

  @override
  String get motherAiFeedEmptyMessage =>
      'Add a child so level-matched mother tips and summaries can appear here.';

  @override
  String get motherAiFeedEmptyCta => 'Add a child';

  @override
  String get motherAiFeedLoadingSemantics => 'Loading mother AI feed';

  @override
  String get motherAiFeedChildLeanTitle => 'Mother notifications';

  @override
  String get motherAiFeedChildLeanMessage =>
      'Mother partnership tips are for parents. Your encouragements arrive as whispers.';

  @override
  String get motherAiFeedSosCta => 'Emergency SOS';

  @override
  String get roadSafetyTitle => 'Road safety';

  @override
  String get roadSafetyHonestyBanner =>
      'Works via the child\'s phone sensors — Android first, iPhone later per Apple permissions. We say that honestly.';

  @override
  String get roadSafetyCrashTitle => 'Crash detection';

  @override
  String get roadSafetyCrashSub =>
      'Hard jolt + sudden stop → verify call then SOS escalate';

  @override
  String get roadSafetyReportTitle => 'Teen driver report';

  @override
  String get roadSafetyReportSub => 'Speed, hard brakes, distraction';

  @override
  String get roadSafetyWeeklyTag => 'Weekly';

  @override
  String get roadSafetyPhoneTitle => 'Phone while driving';

  @override
  String get roadSafetyPhoneSub => 'Gentle alert to them — summary to you';

  @override
  String get roadSafetyTripHeading => 'Yesterday\'s trip — sample';

  @override
  String get roadSafetyStatSpeed => 'Top speed';

  @override
  String roadSafetyStatSpeedValue(int kmh) {
    return '$kmh km/h';
  }

  @override
  String get roadSafetyStatBrakes => 'Hard brakes';

  @override
  String roadSafetyStatBrakesValue(int count) {
    return '$count';
  }

  @override
  String get roadSafetyStatPhone => 'Phone taps';

  @override
  String get roadSafetyStatPhoneZero => 'Zero ✓';

  @override
  String get roadSafetyDialogueStep =>
      'Dialogue step: praise «zero taps» first — then calmly ask about the two hard brakes.';

  @override
  String get roadSafetyObserverHint =>
      'Changing road-safety toggles needs Full mother level — you can review trips.';

  @override
  String get roadSafetyObserverBlocked =>
      'Road-safety toggles need Full mother level or father';

  @override
  String get roadSafetyEmptyTitle => 'No road safety yet';

  @override
  String get roadSafetyEmptyMessage =>
      'Add a child to enable crash detection honesty and driving summaries.';

  @override
  String get roadSafetyEmptyCta => 'Add a child';

  @override
  String get roadSafetyLoadingSemantics => 'Loading road safety';

  @override
  String get roadSafetyChildLeanTitle => 'Road safety';

  @override
  String get roadSafetyChildLeanMessage =>
      'Driving safety settings are for parents. SOS stays available if you need help.';

  @override
  String get roadSafetySosCta => 'Emergency SOS';

  @override
  String get childQuranWardTitle => 'My Quran ward';

  @override
  String get childQuranWardSurahMulk => 'Al-Mulk';

  @override
  String get childQuranWardSurahNaba => 'An-Naba';

  @override
  String get childQuranWardReciterDefault => 'your parent\'s chosen reciter';

  @override
  String get childQuranWardAyahMulk16 =>
      'ءَأَمِنتُم مَّن فِى ٱلسَّمَآءِ أَن يَخْسِفَ بِكُمُ ٱلْأَرْضَ فَإِذَا هِىَ تَمُورُ ﴿١٦﴾';

  @override
  String childQuranWardGiftBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new surahs',
      one: '1 new surah',
    );
    return 'Gift from your parent: $_temp0 — text and recitation ready offline!';
  }

  @override
  String get childQuranWardParentsSet => 'Your ward set by your parents';

  @override
  String get childQuranWardOfflineTag => 'Recitation on this device';

  @override
  String childQuranWardSurahTitle(String name) {
    return 'Surah $name';
  }

  @override
  String childQuranWardAyahRange(int from, int to, String reciter) {
    return 'Ayahs ($from–$to) · voice of $reciter';
  }

  @override
  String childQuranWardReward(int minutes) {
    return 'Completion reward: +$minutes extra play minutes';
  }

  @override
  String get childQuranWardOfflineNote =>
      'Sheikh recitation saved on your device — listen and repeat even offline.';

  @override
  String childQuranWardVoiceOf(String reciter) {
    return 'Voice of $reciter';
  }

  @override
  String get childQuranWardPlayCta => 'Listen and repeat with the sheikh';

  @override
  String get childQuranWardRecordCta =>
      'Record your recitation for your parents';

  @override
  String get childQuranWardPlayToast =>
      'Playing sheikh recitation from your device (offline)';

  @override
  String get childQuranWardRecordToast =>
      'Recording sent to your parents for review';

  @override
  String get childQuranWardStatusHeading => 'Today\'s recitation status';

  @override
  String childQuranWardStatusApproved(int minutes) {
    return 'Approved — +$minutes minutes deposited';
  }

  @override
  String get childQuranWardStatusSent =>
      'Recording sent — waiting for parent review';

  @override
  String get childQuranWardStatusNone => 'Record when you are ready';

  @override
  String get childQuranWardTagApproved => 'Approved';

  @override
  String get childQuranWardTagSent => 'Sent';

  @override
  String get childQuranWardTagNew => 'Ready';

  @override
  String get childQuranWardEmptyTitle => 'No ward yet';

  @override
  String get childQuranWardEmptyMessage =>
      'When your parent sets a Quran ward, it appears here with offline recitation.';

  @override
  String get childQuranWardEmptyCta => 'My learning';

  @override
  String get childQuranWardLoadingSemantics => 'Loading Quran ward';

  @override
  String get childQuranWardParentLeanTitle => 'Quran ward';

  @override
  String get childQuranWardParentLeanMessage =>
      'This ward player is for the child. Track progress from Quran progress.';

  @override
  String get childMemTitle => 'My memorization';

  @override
  String get childMemHeroLabel => 'Memorized so far';

  @override
  String childMemHeroValue(int surahs, int ayahs) {
    return '$surahs surahs + $ayahs ayahs';
  }

  @override
  String get childMemSurahFatiha => 'Al-Fatiha';

  @override
  String get childMemSurahIkhlas => 'Al-Ikhlas';

  @override
  String get childMemSurahNaba => 'An-Naba';

  @override
  String get childMemSurahMulk => 'Al-Mulk';

  @override
  String get childMemBadgeFirst => 'First surah';

  @override
  String get childMemBadgeThree => '3 surahs';

  @override
  String get childMemBadgeHalfAmma => 'Half Juz Amma';

  @override
  String get childMemBadgeHafiz => 'Little hafiz';

  @override
  String get childMemBadgesHint => 'Your next badges are waiting — keep going!';

  @override
  String get childMemReviewsHeading => 'Due reviews';

  @override
  String get childMemReviewTabarak => 'Tabarak 1–10';

  @override
  String get childMemReviewNaba => 'An-Naba complete';

  @override
  String get childMemReviewFourDays => 'Last review 4 days ago';

  @override
  String get childMemReviewTomorrow => 'Due tomorrow';

  @override
  String get childMemReviewTomorrowShort => 'Tomorrow';

  @override
  String get childMemReviewCta => 'Review';

  @override
  String get childMemReviewToast =>
      'Recite — Family Advisor follows with a licensed mushaf';

  @override
  String get childMemHadithBanner =>
      'The best of you are those who learn the Quran and teach it — your parent sees your progress.';

  @override
  String get childMemEmptyTitle => 'No memorization map yet';

  @override
  String get childMemEmptyMessage =>
      'Complete your first ward and your map will grow here.';

  @override
  String get childMemEmptyCta => 'My Quran ward';

  @override
  String get childMemLoadingSemantics => 'Loading memorization';

  @override
  String get childMemParentLeanTitle => 'Memorization map';

  @override
  String get childMemParentLeanMessage =>
      'This map is for the child. Parents track from Quran progress.';

  @override
  String get childAthkarTitle => 'My athkar';

  @override
  String get childAthkarSessionMorning => 'morning';

  @override
  String get childAthkarSessionEvening => 'evening';

  @override
  String get childAthkarThikrAmsayna =>
      '«O Allah, by You we reach the evening and by You we reach the morning, by You we live and by You we die, and to You is the resurrection.»';

  @override
  String childAthkarProgress(String session, int done, int total) {
    return '$session thikr · $done of $total';
  }

  @override
  String get childAthkarSayCta => 'I said it';

  @override
  String get childAthkarDoneCta => 'Finished them all today';

  @override
  String childAthkarProgressToast(int done, int total) {
    return '$done of $total — well done! Next…';
  }

  @override
  String get childAthkarCompleteToast =>
      'MashaAllah — you finished today\'s athkar';

  @override
  String get childAthkarStatMorning => 'Morning';

  @override
  String get childAthkarStatEvening => 'Evening';

  @override
  String childAthkarStatValue(int done, int total) {
    return '$done/$total';
  }

  @override
  String get childAthkarGentleBanner =>
      'Gentle reminder — no pressure. Reward is with Allah; minutes are encouragement from your parent.';

  @override
  String get childAthkarEmptyTitle => 'No athkar session';

  @override
  String get childAthkarEmptyMessage =>
      'Your daily athkar session will appear here when ready.';

  @override
  String get childAthkarEmptyCta => 'My day';

  @override
  String get childAthkarLoadingSemantics => 'Loading athkar';

  @override
  String get childAthkarParentLeanTitle => 'Athkar';

  @override
  String get childAthkarParentLeanMessage =>
      'Daily athkar is for the child. You receive blessing whispers when they finish.';

  @override
  String get childSmartPlanTitle => 'My smart plan';

  @override
  String get childSmartPlanGapHeading => 'We found your sticking point';

  @override
  String get childSmartPlanGapTimes7 =>
      'Your long-division mistakes come from one small idea: the 7 times table. We strengthen it for 3 days — then you take off.';

  @override
  String get childSmartPlanStartCta => 'Start the repair plan';

  @override
  String get childSmartPlanStartedCta => 'Plan started';

  @override
  String get childSmartPlanStartToast =>
      '3-day plan started — 10 minutes a day only';

  @override
  String get childSmartPlanProjectGarden => 'Home garden';

  @override
  String childSmartPlanProjectHeading(String name) {
    return 'Family project — «$name»';
  }

  @override
  String get childSmartPlanStage2 => 'Stage 2 — planting seedlings';

  @override
  String childSmartPlanProjectStage(String stage) {
    return 'Your stage now: $stage (assigned by your parent)';
  }

  @override
  String get childSmartPlanProjectCta => 'I finished my stage';

  @override
  String get childSmartPlanProjectDoneCta => 'Stage recorded';

  @override
  String get childSmartPlanProjectToast =>
      'Nice! Your stage is logged — your parent got the news';

  @override
  String get childSmartPlanPathHeading => 'My visual path';

  @override
  String get childSmartPlanPathCaption =>
      'Add ✓ subtract ✓ multiply ✓ — you are now in division';

  @override
  String get childSmartPlanExerciseHint =>
      'Today\'s exercise — sized for you: easier if you stumble, challenging if you shine.';

  @override
  String get childSmartPlanEmptyTitle => 'No smart plan yet';

  @override
  String get childSmartPlanEmptyMessage =>
      'When learning gaps are spotted, your adaptive plan appears here.';

  @override
  String get childSmartPlanEmptyCta => 'My learning';

  @override
  String get childSmartPlanLoadingSemantics => 'Loading smart plan';

  @override
  String get childSmartPlanParentLeanTitle => 'Smart plan';

  @override
  String get childSmartPlanParentLeanMessage =>
      'The adaptive plan is for the child. Parents see progress from learning insights.';

  @override
  String get childDailyReviewTitle => 'Today\'s review';

  @override
  String get childDailyReviewHeroTitle => '5 minutes protect a week of work';

  @override
  String get childDailyReviewHeroSub =>
      'Family Advisor knows when you are about to forget — and reviews you a day before';

  @override
  String childDailyReviewCardsHeading(int count) {
    return 'Today\'s cards ($count)';
  }

  @override
  String get childDailyReviewCardFractions => 'Similar fractions';

  @override
  String get childDailyReviewCardUnit4 => 'Unit 4 words';

  @override
  String get childDailyReviewCardWaterCycle => 'Water cycle';

  @override
  String get childDailyReviewMetaThreeDays =>
      'Learned 3 days ago — time to lock it in';

  @override
  String get childDailyReviewMetaOneWeek => 'One week ago';

  @override
  String get childDailyReviewMetaTwiceStrong =>
      'Locked in twice — almost memorized!';

  @override
  String get childDailyReviewTagDue => 'Due';

  @override
  String get childDailyReviewTagStrong => 'Strong';

  @override
  String get childDailyReviewStartCta => 'Start the 5 minutes';

  @override
  String get childDailyReviewDoneCta => 'Review complete';

  @override
  String childDailyReviewDoneToast(int minutes) {
    return 'All cards done — memory builds like muscle! +$minutes min';
  }

  @override
  String get childDailyReviewEmptyTitle => 'No review cards';

  @override
  String get childDailyReviewEmptyMessage =>
      'When lessons need a quick refresh, cards appear here.';

  @override
  String get childDailyReviewEmptyCta => 'My learning';

  @override
  String get childDailyReviewLoadingSemantics => 'Loading daily review';

  @override
  String get childDailyReviewParentLeanTitle => 'Daily review';

  @override
  String get childDailyReviewParentLeanMessage =>
      'Spaced review is for the child. Parents see mastery from learning insights.';

  @override
  String get childFriendsTitle => 'My friends';

  @override
  String get childFriendsNameOne => 'Approved friend';

  @override
  String get childFriendsNamePending => 'Pending friend';

  @override
  String get childFriendsMetaSlot47 => 'Available now · contact window 4–7 PM';

  @override
  String get childFriendsMetaAwaiting =>
      'Your request is with your parent for approval';

  @override
  String get childFriendsChatCta => 'Chat';

  @override
  String get childFriendsCallCta => 'Call';

  @override
  String get childFriendsChatToast => 'Opened a safe chat';

  @override
  String get childFriendsCallToast => 'Calling…';

  @override
  String get childFriendsPendingTag => 'Under review';

  @override
  String get childFriendsAddHeading => 'Met a new classmate or friend?';

  @override
  String get childFriendsAddSub =>
      'Ask to add them safely — your parent reviews for your protection';

  @override
  String get childFriendsAddCta => 'Request add friend';

  @override
  String get childFriendsAddToast => 'Request sent to your parent for approval';

  @override
  String get childFriendsSafetyBanner =>
      'No strangers: every friend in your list is personally approved by your parent.';

  @override
  String get childFriendsEmptyTitle => 'No approved friends yet';

  @override
  String get childFriendsEmptyMessage =>
      'Ask your parent to approve a friend so you can chat safely.';

  @override
  String get childFriendsEmptyCta => 'Request add friend';

  @override
  String get childFriendsLoadingSemantics => 'Loading friends';

  @override
  String get childFriendsParentLeanTitle => 'Child friends';

  @override
  String get childFriendsParentLeanMessage =>
      'Approve friends from Friend approval. This list is the child\'s view.';

  @override
  String get childComingGiftsTitle => 'Coming for you';

  @override
  String get childComingGiftsHeroTitle => 'Nice things are coming…';

  @override
  String get childComingGiftsHeroSub => 'We prepare them carefully — no rush';

  @override
  String get childComingGiftsLinksHeading => 'They all arrived! Try them now';

  @override
  String get childComingGiftsCallPlay => 'Call play';

  @override
  String get childComingGiftsCallPlaySub => 'Play with Grandpa while you talk!';

  @override
  String get childComingGiftsChallenges => 'Family challenges';

  @override
  String get childComingGiftsChallengesSub =>
      'Friendly competition with siblings';

  @override
  String get childComingGiftsStories => 'Interactive stories';

  @override
  String get childComingGiftsStoriesSub => 'You are the hero of the tale';

  @override
  String get childComingGiftsSounds => 'Focus sounds';

  @override
  String get childComingGiftsSoundsSub => 'Waves, rain, and calm';

  @override
  String get childComingGiftsStickers => 'My stickers and backgrounds';

  @override
  String get childComingGiftsStickersSub => 'Color your chats';

  @override
  String get childComingGiftsSmartTilawa => 'Smart tilawa';

  @override
  String get childComingGiftsSmartTilawaSub => 'Improve your recitation gently';

  @override
  String get childComingGiftsNewTag => 'New';

  @override
  String get childComingGiftsEmptyTitle => 'Nothing ready yet';

  @override
  String get childComingGiftsEmptyMessage =>
      'When new gifts unlock, they appear here — no date promises.';

  @override
  String get childComingGiftsEmptyCta => 'My learning';

  @override
  String get childComingGiftsLoadingSemantics => 'Loading coming gifts';

  @override
  String get childComingGiftsParentLeanTitle => 'Coming gifts';

  @override
  String get childComingGiftsParentLeanMessage =>
      'This teaser hub is for the child. Feature readiness is managed by the product plan.';

  @override
  String get homeRouterFilterTitle => 'Home router filter';

  @override
  String get homeRouterFilterHeroProtected => 'Home router is protected';

  @override
  String get homeRouterFilterHeroUnprotected => 'Home router needs setup';

  @override
  String homeRouterFilterHeroSub(int count) {
    return '$count devices behind the filter — including guests and the living-room TV';
  }

  @override
  String get homeRouterFilterHowHeading => 'How it works';

  @override
  String get homeRouterFilterHowDnsTitle => 'Family DNS on the router';

  @override
  String get homeRouterFilterHowDnsSub =>
      'Set once — we guide you step by step';

  @override
  String get homeRouterFilterHowCatsTitle => 'Same 29 filter categories';

  @override
  String get homeRouterFilterHowCatsSub => 'One policy: device and home';

  @override
  String get homeRouterFilterHowAwayTitle => 'Away from home?';

  @override
  String get homeRouterFilterHowAwaySub =>
      'Child-device filtering keeps working — no gap';

  @override
  String get homeRouterFilterTagActive => 'On';

  @override
  String get homeRouterFilterTagSynced => 'Synced';

  @override
  String get homeRouterFilterTagAuto => 'Automatic';

  @override
  String get homeRouterFilterTagOff => 'Off';

  @override
  String get homeRouterFilterGuideCta => 'Step-by-step setup guide';

  @override
  String get homeRouterFilterCheckCta => 'Test protection now';

  @override
  String get homeRouterFilterGuideToast =>
      'Opened the step-by-step router guide';

  @override
  String get homeRouterFilterCheckToast =>
      'Check complete — your router is protected and every device is behind the filter';

  @override
  String get homeRouterFilterGuestBanner =>
      'A guest slipped onto your Wi-Fi? They are filtered automatically — you control exceptions.';

  @override
  String get homeRouterFilterObserverHint =>
      'Changing router DNS needs Partner level or above — you can review status.';

  @override
  String get homeRouterFilterObserverBlocked =>
      'Router filter actions need Partner mother level or father';

  @override
  String get homeRouterFilterEmptyTitle => 'No home network yet';

  @override
  String get homeRouterFilterEmptyMessage =>
      'Add a child so home-router protection can cover your household devices.';

  @override
  String get homeRouterFilterEmptyCta => 'Add a child';

  @override
  String get homeRouterFilterLoadingSemantics => 'Loading home router filter';

  @override
  String get homeRouterFilterChildLeanTitle => 'Home router filter';

  @override
  String get homeRouterFilterChildLeanMessage =>
      'Router DNS setup is for parents. Your device filter still protects you away from home.';

  @override
  String get agentActionLogTitle => 'Delegated agent log';

  @override
  String get agentActionLogLiveHeading =>
      'Recent automatic action under your delegation';

  @override
  String agentActionLogTagPending(int min, int sec) {
    return '$min:$sec left to adjust';
  }

  @override
  String get agentActionLogTagBlessed => 'You blessed it';

  @override
  String get agentActionLogTagUndone => 'Gently undone';

  @override
  String get agentActionLogChildOne => 'Child A';

  @override
  String agentActionLogGranted(int minutes, String child) {
    return 'Agent granted +$minutes minutes to $child';
  }

  @override
  String agentActionLogReason(String tasks) {
    return 'Documented reason: completed ($tasks)';
  }

  @override
  String agentActionLogUsage(String app) {
    return 'Usage: reserved for $app · a few minutes ago';
  }

  @override
  String get agentActionLogTaskMath => 'math homework';

  @override
  String get agentActionLogTaskRoom => 'room tidy';

  @override
  String get agentActionLogAppBlocks => 'educational blocks';

  @override
  String get agentActionLogBlessCta => 'Bless + pride whisper';

  @override
  String get agentActionLogUndoCta => 'Gentle undo';

  @override
  String get agentActionLogBlessToast => 'Pride whisper sent';

  @override
  String get agentActionLogUndoToast => 'You gently undid the decision';

  @override
  String get agentActionLogBlessedNote =>
      'You sent a pride whisper — enjoy your well-earned minutes.';

  @override
  String get agentActionLogUndoneNote =>
      'You gently undid the decision with mercy.';

  @override
  String get agentActionLogWeeklyHeading => 'Agent actions this week';

  @override
  String get agentActionLogWeeklySleep => 'Sleep mode activated ×7';

  @override
  String get agentActionLogWeeklySleepMeta => 'Per approved schedule';

  @override
  String get agentActionLogWeeklyReview => 'Review & Quran reminders ×5';

  @override
  String get agentActionLogWeeklyReviewMeta => 'Child responded 4 times';

  @override
  String get agentActionLogRule2 => 'Rule 2';

  @override
  String get agentActionLogRule3 => 'Rule 3';

  @override
  String get agentActionLogEmptyTitle => 'No agent log yet';

  @override
  String get agentActionLogEmptyMessage =>
      'Add a child and delegate rules so automatic agent actions appear here.';

  @override
  String get agentActionLogEmptyCta => 'Add a child';

  @override
  String get agentActionLogLoadingSemantics => 'Loading agent action log';

  @override
  String get agentActionLogChildLeanTitle => 'Agent action log';

  @override
  String get agentActionLogChildLeanMessage =>
      'Delegated agent actions are for parents. Minutes you earn still show in your wallet.';

  @override
  String get peerCompareTitle => 'Peer compare';

  @override
  String get peerComparePrivacyBanner =>
      'Fully anonymous comparison with general age averages — no names, no families, no shaming. Your data never leaves for others.';

  @override
  String get peerCompareChildOne => 'Child A';

  @override
  String peerCompareHeading(String child, int age) {
    return '$child ($age yrs) vs age cohort';
  }

  @override
  String get peerCompareMetricScreen => 'Screen time';

  @override
  String get peerCompareDetailScreen => 'Child: 2h40/day · average: 3h15';

  @override
  String get peerCompareMetricLearn => 'Learning time';

  @override
  String get peerCompareDetailLearn => 'Child: 51 min/day · average: 25 min';

  @override
  String get peerCompareMetricSleep => 'Sleep';

  @override
  String get peerCompareDetailSleep =>
      '20 min later than recommended for this age';

  @override
  String get peerCompareTagBetter => 'Better';

  @override
  String get peerCompareTagImprove => 'Growth chance';

  @override
  String get peerCompareCompassNote =>
      'Advisor reminder: comparison is a compass, not a court — your child beats their own yesterday first. Never make it a scolding topic.';

  @override
  String get peerCompareEmptyTitle => 'No peer compare yet';

  @override
  String get peerCompareEmptyMessage =>
      'Add a child so anonymous age-cohort averages can appear here.';

  @override
  String get peerCompareEmptyCta => 'Add a child';

  @override
  String get peerCompareLoadingSemantics => 'Loading peer compare';

  @override
  String get peerCompareChildLeanTitle => 'Peer compare';

  @override
  String get peerCompareChildLeanMessage =>
      'Anonymous peer averages are for parents. Keep growing — you compete with yourself first.';

  @override
  String get smartChoreTitle => 'Smart chore distributor';

  @override
  String get smartChoreProposalHeading =>
      'This week\'s distribution suggestion';

  @override
  String get smartChoreChildOne => 'Child A';

  @override
  String get smartChoreChildTwo => 'Child B';

  @override
  String get smartChoreChildThree => 'Child C';

  @override
  String get smartChoreDishesPlants => 'dishes (3 days) + plants';

  @override
  String get smartChoreLivingLaundry => 'living room + laundry';

  @override
  String get smartChoreTrashWater => 'trash + watering plants';

  @override
  String get smartChoreNoteExam => 'Lighten Tuesday — exam day';

  @override
  String get smartChoreNoteRotated => 'Rotated — was tired of dishes';

  @override
  String get smartChoreNoteAge8 => 'Light chores for age 8';

  @override
  String get smartChoreApproveCta => 'Approve distribution';

  @override
  String get smartChoreApprovedCta => 'Approved';

  @override
  String get smartChoreShuffleCta => 'Shuffle';

  @override
  String get smartChoreApproveToast =>
      'Approved — each child got their tasks with set minutes';

  @override
  String get smartChoreShuffleToast =>
      'Alternate distribution ready — same fairness';

  @override
  String get smartChoreFairnessHeading => 'Why this distribution is fair';

  @override
  String get smartChoreFairnessBody =>
      'Equal minutes per child by age · no chore repeats for the same child two weeks · school schedules counted.';

  @override
  String get smartChoreObserverHint =>
      'Approving chore distributions needs Partner level or above — you can review the proposal.';

  @override
  String get smartChoreEmptyTitle => 'No chore plan yet';

  @override
  String get smartChoreEmptyMessage =>
      'Add children so ChoreAI can propose a fair weekly distribution.';

  @override
  String get smartChoreEmptyCta => 'Add a child';

  @override
  String get smartChoreLoadingSemantics => 'Loading chore distributor';

  @override
  String get smartChoreChildLeanTitle => 'Chore distributor';

  @override
  String get smartChoreChildLeanMessage =>
      'Weekly chore planning is for parents. Your assigned tasks appear in My tasks.';

  @override
  String get advisorVoiceTitle => 'Talk with Family Advisor';

  @override
  String get advisorVoiceHint =>
      'Press and speak — while driving or hands-busy';

  @override
  String get advisorVoiceTalkCta => 'Press and talk';

  @override
  String get advisorVoiceListeningToast =>
      'Listening… answers from your family data only';

  @override
  String get advisorVoiceLastHeading => 'Last conversation';

  @override
  String get advisorVoiceUserHomework => 'Did Child A finish homework?';

  @override
  String get advisorVoiceReplyHomework =>
      'Yes — finished math and science an hour ago; English review is due tomorrow.';

  @override
  String get advisorVoiceHonestyBanner =>
      'Same honesty pledge: if data is thin, it says aloud — «I do not know precisely enough».';

  @override
  String get advisorVoiceEmptyTitle => 'No voice advisor yet';

  @override
  String get advisorVoiceEmptyMessage =>
      'Add a child so Family Advisor voice can answer from family data.';

  @override
  String get advisorVoiceEmptyCta => 'Add a child';

  @override
  String get advisorVoiceLoadingSemantics => 'Loading advisor voice';

  @override
  String get advisorVoiceChildLeanTitle => 'Advisor voice';

  @override
  String get advisorVoiceChildLeanMessage =>
      'Parent voice mode is for parents. Your tutor voice lives in My learning.';

  @override
  String get stagedProjectTitle => 'Staged project';

  @override
  String get stagedProjectHomeGarden => 'Our home garden';

  @override
  String get stagedProjectChildOne => 'Child A';

  @override
  String stagedProjectHeroTitle(String child, String name) {
    return '$child\'s project: $name';
  }

  @override
  String stagedProjectHeroSub(int stages, int weeks, int current) {
    return '$stages stages · $weeks weeks · stage $current now';
  }

  @override
  String get stagedProjectStageResearch => 'S1: Research & plan';

  @override
  String get stagedProjectStageResearchSub =>
      'Picked 3 plants and drew the garden';

  @override
  String get stagedProjectStagePlant => 'S2: Planting';

  @override
  String get stagedProjectStagePlantSub =>
      'Photo proof of planting — awaiting your confirm';

  @override
  String get stagedProjectStageWater => 'S3: Water & care';

  @override
  String get stagedProjectStageWaterSub => 'Unlocks when S2 is done';

  @override
  String get stagedProjectStageHarvest => 'S4: Harvest & present';

  @override
  String get stagedProjectStageHarvestSub => 'Family presentation!';

  @override
  String get stagedProjectConfirmCta => 'Confirm';

  @override
  String stagedProjectConfirmToast(int minutes) {
    return 'Stage approved! +$minutes min deposited';
  }

  @override
  String stagedProjectMinutesTag(int minutes) {
    return '+$minutes min';
  }

  @override
  String get stagedProjectTemplateCta => '+ New project from template';

  @override
  String get stagedProjectTemplateToast =>
      'Templates ready: science model, family research, first app, charity…';

  @override
  String get stagedProjectEmptyTitle => 'No staged project yet';

  @override
  String get stagedProjectEmptyMessage =>
      'Add a child and create a multi-week staged project from the studio.';

  @override
  String get stagedProjectEmptyCta => 'Add a child';

  @override
  String get stagedProjectLoadingSemantics => 'Loading staged project';

  @override
  String get stagedProjectChildLeanTitle => 'Staged project';

  @override
  String get stagedProjectChildLeanMessage =>
      'Parents confirm stages. Your active stage lives in My learning / My tasks.';

  @override
  String get familyMomentsTitle => 'Our family moments';

  @override
  String get familyMomentsWeekLabel => 'Friday · your family\'s week';

  @override
  String get familyMomentsHeroTitle => 'A week worth celebrating!';

  @override
  String get familyMomentsStatLearn => 'learn hrs';

  @override
  String get familyMomentsStatVerses => 'verses';

  @override
  String get familyMomentsStatTasks => 'tasks done';

  @override
  String get familyMomentsStatAlerts => 'worry alerts';

  @override
  String get familyMomentsStarsTitle => 'Star of the week';

  @override
  String get familyMomentsChildOne => 'Child A';

  @override
  String get familyMomentsChildTwo => 'Child B';

  @override
  String familyMomentsStarQuran(String child) {
    return '$child — finished Juz Amma!';
  }

  @override
  String get familyMomentsStarQuranSub =>
      'Six months of steady work · a landmark moment';

  @override
  String familyMomentsStarMath(String child) {
    return '$child — jumped 17% in math';
  }

  @override
  String get familyMomentsStarMathSub => 'The missing-concept plan paid off';

  @override
  String familyMomentsStarSleep(String child) {
    return '$child — a full week of steady sleep';
  }

  @override
  String get familyMomentsStarSleepSub => 'First time in two months';

  @override
  String get familyMomentsShareCta => 'Share pride card with the family';

  @override
  String get familyMomentsPrideToast =>
      'Pride card reached family chat — they saw your applause!';

  @override
  String get familyMomentsTouchTitle => 'Next week\'s touch';

  @override
  String get familyMomentsTouchBody =>
      'Child B is close to finishing Surah Al-Mulk — when they do, how about a surprise outing they choose? Deeper than any minutes reward.';

  @override
  String get familyMomentsTouchCta => 'Love it — remind me';

  @override
  String get familyMomentsTouchToast =>
      'Surprise promised — you\'ll get a reminder when the surah is done';

  @override
  String get familyMomentsAlbumTitle => 'Moments album';

  @override
  String get familyMomentsCapGarden => 'Garden day';

  @override
  String get familyMomentsCapPrayer => 'Fajr together';

  @override
  String get familyMomentsCapCook => 'Helped cook';

  @override
  String get familyMomentsCapRead => 'Story night';

  @override
  String get familyMomentsCapWalk => 'Evening walk';

  @override
  String get familyMomentsCapLaugh => 'Family laugh';

  @override
  String get familyMomentsCapNew => 'New moment';

  @override
  String get familyMomentsByMother => 'Mother';

  @override
  String get familyMomentsByFather => 'Father';

  @override
  String get familyMomentsWhenYesterday => 'yesterday';

  @override
  String get familyMomentsWhenTue => 'Tue';

  @override
  String get familyMomentsWhenMon => 'Mon';

  @override
  String get familyMomentsWhenSun => 'Sun';

  @override
  String get familyMomentsWhenSat => 'Sat';

  @override
  String get familyMomentsWhenFri => 'Fri';

  @override
  String get familyMomentsWhenNow => 'now';

  @override
  String get familyMomentsAddCta => '+ Add a moment';

  @override
  String get familyMomentsAddToast => 'Added to moments — family notified';

  @override
  String get familyMomentsFridayBanner =>
      'Arrives every Friday morning — open, celebrate, share. Then rest easy.';

  @override
  String get familyMomentsEmptyTitle => 'No family moments yet';

  @override
  String get familyMomentsEmptyMessage =>
      'Add a child so weekly pride, stars, and the moments album can light up.';

  @override
  String get familyMomentsEmptyCta => 'Add a child';

  @override
  String get familyMomentsLoadingSemantics => 'Loading family moments';

  @override
  String get familyMomentsChildLeanTitle => 'Family moments';

  @override
  String get familyMomentsChildLeanMessage =>
      'Parents open the weekly pride wrap. Your stars show up in My learning.';

  @override
  String get childSmartTilawahTitle => 'My smart tilawah';

  @override
  String get childSmartTilawahSurahMulk => 'Surah Al-Mulk';

  @override
  String childSmartTilawahAyahMeta(String surah, int ayah) {
    return '$surah · ayah $ayah';
  }

  @override
  String get childSmartTilawahAyahMulk16 => 'ءَأَمِنتُم مَّن فِى ٱلسَّمَآءِ…';

  @override
  String get childSmartTilawahListenCta => 'Recite — I\'m listening';

  @override
  String get childSmartTilawahListenToast =>
      'Listening to your tilawah… mashaAllah! One gentle note below';

  @override
  String get childSmartTilawahTipTitle => 'Today\'s note — only one';

  @override
  String get childSmartTilawahTipMadd => 'Stretch «as-samaa» six counts';

  @override
  String get childSmartTilawahTipMaddBody =>
      'Connected madd before hamza — hear the sheikh, then try again';

  @override
  String get childSmartTilawahSheikhCta => 'Listen';

  @override
  String get childSmartTilawahSheikhToast =>
      'Sheikh clip for ayah 16 — from a licensed mushaf';

  @override
  String get childSmartTilawahPraise =>
      'Well done on: letter exits ✓ · ghunnah ✓ · pause ✓';

  @override
  String get childSmartTilawahBanner =>
      'Correction uses licensed mushaf sheikh audio — Family Advisor gives one gentle note at a time so it never overwhelms you.';

  @override
  String get childSmartTilawahEmptyTitle => 'No tilawah session yet';

  @override
  String get childSmartTilawahEmptyMessage =>
      'Open your Quran ward to start a gentle smart-tilawah session.';

  @override
  String get childSmartTilawahEmptyCta => 'My Quran ward';

  @override
  String get childSmartTilawahLoadingSemantics => 'Loading smart tilawah';

  @override
  String get childSmartTilawahParentLeanTitle => 'Smart tilawah';

  @override
  String get childSmartTilawahParentLeanMessage =>
      'This gentle recitation coach is on the child\'s device. Progress shows in Quran progress for parents.';

  @override
  String get childInteractiveStoriesTitle => 'My stories';

  @override
  String get childInteractiveStoriesChapterTitle =>
      'Desert treasure — chapter 3';

  @override
  String get childInteractiveStoriesChapterBody =>
      'You and your friend reach an old well. You find a bag of gold coins stamped with the caravan merchant\'s name… your friend whispers: \"No one will know!\"';

  @override
  String get childInteractiveStoriesPrompt => 'What do you do?';

  @override
  String get childInteractiveStoriesChoiceReturn =>
      'Find the merchant and return the bag';

  @override
  String get childInteractiveStoriesChoiceTake => 'Take it — no one will know';

  @override
  String get childInteractiveStoriesChoiceAsk => 'Ask my parent first';

  @override
  String get childInteractiveStoriesToastReturn =>
      'You chose honesty! The merchant will reward you beyond imagining… ending: whoever leaves something for Allah, Allah replaces it with better.';

  @override
  String get childInteractiveStoriesToastTake =>
      'Another path… you\'ll discover yourself in the ending: a calm heart cannot be bought with worldly gold.';

  @override
  String get childInteractiveStoriesToastAsk =>
      'Wisdom! Asking elders is the path of the wise — your parent in the story will surprise you.';

  @override
  String get childInteractiveStoriesFooter =>
      'Your choices write the tale — there is never only one ending';

  @override
  String get childInteractiveStoriesEmptyTitle => 'No story chapter yet';

  @override
  String get childInteractiveStoriesEmptyMessage =>
      'Open My learning to unlock your next interactive story chapter.';

  @override
  String get childInteractiveStoriesEmptyCta => 'My learning';

  @override
  String get childInteractiveStoriesLoadingSemantics =>
      'Loading interactive story';

  @override
  String get childInteractiveStoriesParentLeanTitle => 'Interactive stories';

  @override
  String get childInteractiveStoriesParentLeanMessage =>
      'Value-choice stories run on the child\'s device. Parents see themes in Family Advisor, never spoilers.';

  @override
  String get childFamilyChallengesTitle => 'Family challenges';

  @override
  String get childFamilyChallengesActiveTitle =>
      'This week\'s challenge: review marathon';

  @override
  String get childFamilyChallengesActiveSub =>
      'Who completes review cards every day? Prize: pick Friday\'s outing!';

  @override
  String get childFamilyChallengesYou => 'You';

  @override
  String get childFamilyChallengesSibling => 'Sibling';

  @override
  String get childFamilyChallengesTieNote =>
      'Exciting tie! — and Dad is smiling as he watches';

  @override
  String get childFamilyChallengesDoneTitle => 'Challenges we finished';

  @override
  String get childFamilyChallengesDoneFajr => 'Fajr-together week';

  @override
  String get childFamilyChallengesDoneFajrSub =>
      'You all won — Friday ice cream';

  @override
  String get childFamilyChallengesDoneAmma => 'Family Juz Amma khatma';

  @override
  String get childFamilyChallengesDoneAmmaSub => 'Sibling finished first';

  @override
  String get childFamilyChallengesDoneTag => 'Done';

  @override
  String get childFamilyChallengesBanner =>
      'Here we race to grow together — no ranking that embarrasses anyone. The only loser is laziness.';

  @override
  String get childFamilyChallengesEmptyTitle => 'No family challenges yet';

  @override
  String get childFamilyChallengesEmptyMessage =>
      'When Dad starts a family challenge, your week streak lights up here.';

  @override
  String get childFamilyChallengesEmptyCta => 'Home';

  @override
  String get childFamilyChallengesLoadingSemantics =>
      'Loading family challenges';

  @override
  String get childFamilyChallengesParentLeanTitle => 'Family challenges';

  @override
  String get childFamilyChallengesParentLeanMessage =>
      'Friendly sibling races live on the child\'s device. Parents set prizes from Tasks / Studio.';

  @override
  String get childFocusSoundsTitle => 'Focus sounds';

  @override
  String get childFocusSoundsRain => 'Quiet rain';

  @override
  String get childFocusSoundsWaves => 'Waves';

  @override
  String get childFocusSoundsForest => 'Forest';

  @override
  String get childFocusSoundsFire => 'Hearth';

  @override
  String get childFocusSoundsToastRain => 'Quiet rain is playing softly…';

  @override
  String get childFocusSoundsToastWaves => 'Ocean waves…';

  @override
  String get childFocusSoundsToastForest => 'Leaves in the forest…';

  @override
  String get childFocusSoundsToastFire => 'Warm hearth…';

  @override
  String get childFocusSoundsWithFocusTitle => 'With focus mode';

  @override
  String get childFocusSoundsAutoTitle => 'Auto-play with focus session';

  @override
  String get childFocusSoundsAutoSub =>
      'Sound starts and stops with the session';

  @override
  String get childFocusSoundsFadeTitle => 'Gentle fade in the last two minutes';

  @override
  String get childFocusSoundsFadeSub =>
      'Softly warns you the session is ending';

  @override
  String get childFocusSoundsStartCta =>
      'Start a focus session now — sound with you';

  @override
  String get childFocusSoundsBanner =>
      'Steady natural sounds — no words, no beat. That is what helps the brain focus.';

  @override
  String get childFocusSoundsEmptyTitle => 'No focus sounds yet';

  @override
  String get childFocusSoundsEmptyMessage =>
      'Open focus mode to unlock calm nature loops for your sessions.';

  @override
  String get childFocusSoundsEmptyCta => 'Focus mode';

  @override
  String get childFocusSoundsLoadingSemantics => 'Loading focus sounds';

  @override
  String get childFocusSoundsParentLeanTitle => 'Focus sounds';

  @override
  String get childFocusSoundsParentLeanMessage =>
      'Nature loops live on the child\'s device next to focus mode. Parents see session stats, not the playlist.';

  @override
  String get childCallPlayTitle => 'Call play';

  @override
  String get childCallPlayPeerGrandpa => 'Grandpa';

  @override
  String get childCallPlayYou => 'You';

  @override
  String childCallPlayHeroTitle(String peer) {
    return 'Call with $peer';
  }

  @override
  String get childCallPlayHeroSub => 'Live now — and you are playing together!';

  @override
  String get childCallPlayGamesTitle => 'Play while you talk';

  @override
  String get childCallPlayGameDraw => 'Shared drawing board';

  @override
  String get childCallPlayGameDrawSub => 'Draw together at the same moment';

  @override
  String get childCallPlayGameXo => 'X-O';

  @override
  String get childCallPlayGameXoSub => 'Grandpa is a champ — watch out!';

  @override
  String get childCallPlayGameQuiz => 'Quiz race';

  @override
  String get childCallPlayGameQuizSub => 'Who answers faster?';

  @override
  String get childCallPlayCtaOpen => 'Open';

  @override
  String get childCallPlayCtaPlay => 'Play';

  @override
  String get childCallPlayCtaChallenge => 'Challenge';

  @override
  String get childCallPlayToastDraw =>
      'Board open — Grandpa is drawing a palm! You finish the house';

  @override
  String get childCallPlayToastXo =>
      'Grandpa took the center — what\'s your plan?';

  @override
  String get childCallPlayToastQuiz =>
      'Q1: capital of Yemen? — Grandpa tapped first!';

  @override
  String get childCallPlayBanner =>
      'Games stay inside your safe circle calls only — they bring you closer to people you love.';

  @override
  String get childCallPlayEmptyTitle => 'No live call to play in';

  @override
  String get childCallPlayEmptyMessage =>
      'When you are on a safe-circle call, drawing, X-O, and quiz race appear here.';

  @override
  String get childCallPlayEmptyCta => 'My chats';

  @override
  String get childCallPlayLoadingSemantics => 'Loading call play';

  @override
  String get childCallPlayParentLeanTitle => 'Call play';

  @override
  String get childCallPlayParentLeanMessage =>
      'In-call games are on the child\'s device during safe-circle calls. Parents see call history, not the board.';

  @override
  String get childStickersBackgroundsTitle => 'My stickers';

  @override
  String get childStickersBackgroundsStickersTitle => 'Your stickers';

  @override
  String get childStickersBackgroundsSpaceHint =>
      'Space pack unlocks after two Quran wards — you are close!';

  @override
  String get childStickersBackgroundsUnlockCta => 'Unlocks after two wards';

  @override
  String childStickersBackgroundsUnlockToast(int wards) {
    return 'Space pack unlocks automatically after two wards — you are $wards ward away!';
  }

  @override
  String get childStickersBackgroundsBgTitle => 'Family chat background';

  @override
  String childStickersBackgroundsBgSemantics(String id) {
    return 'Chat background $id';
  }

  @override
  String get childStickersBackgroundsBgToast =>
      'Background changed — looking great!';

  @override
  String get childStickersBackgroundsBanner =>
      'Every sticker is drawn with care and stays modest — express yourself in your sweet way.';

  @override
  String get childStickersBackgroundsEmptyTitle => 'No sticker pack yet';

  @override
  String get childStickersBackgroundsEmptyMessage =>
      'Open family chat to pick stickers and a wallpaper for your conversations.';

  @override
  String get childStickersBackgroundsEmptyCta => 'My chats';

  @override
  String get childStickersBackgroundsLoadingSemantics =>
      'Loading stickers and backgrounds';

  @override
  String get childStickersBackgroundsParentLeanTitle =>
      'Stickers & backgrounds';

  @override
  String get childStickersBackgroundsParentLeanMessage =>
      'Modest sticker packs live on the child\'s device. Parents approve packs from Studio, not the picker.';

  @override
  String get childLearnHomeChallengeAssigned => 'Lesson your parent assigned';

  @override
  String get childLearnHomeChallengeAssignedHomework =>
      'Homework from your parent';

  @override
  String get childLearnHomeChallengeAssignedSkill =>
      'Skill practice from your parent';

  @override
  String get childLearnHomeChallengeAssignedFamily =>
      'Family challenge from your parent';

  @override
  String get childLearnHomeAssignedFromFather =>
      'Assigned just now by your parent';

  @override
  String addFromSourceAttachedTitle(int count) {
    return 'Attached sources ($count)';
  }

  @override
  String addFromSourceAttachedSemantics(int count) {
    return 'Attached learning sources, $count items';
  }

  @override
  String get addFromSourceLabelPdfMath => 'Math workbook PDF';

  @override
  String get addFromSourceLabelPdfScience => 'Science unit PDF';

  @override
  String get addFromSourceLabelPdfDevice => 'PDF from this device';

  @override
  String get addFromSourceLabelLink => 'Educational video link';

  @override
  String get addFromSourceLabelTopic => 'Topic seed for Advisor';

  @override
  String get addFromSourceLabelVoice => 'Voice note for Advisor';

  @override
  String get previewApproveApprovedToast =>
      'Approved — ready to assign rewards to your child';

  @override
  String get childQuizSkillApprovedPack => 'Lesson your parent approved';

  @override
  String get childQuizExplainApproved =>
      'Your parent approved this question for you — great work!';

  @override
  String get sosAlertAcknowledgeCta => 'Acknowledge — I saw this alert';

  @override
  String get sosAlertAcknowledgeSemantics =>
      'Acknowledge the SOS alert without closing it';

  @override
  String get sosAlertAcknowledgedToast =>
      'Acknowledged — alert remains open until resolved';

  @override
  String get sosAlertCallUnavailableToast =>
      'Calling is not configured on this device yet — alert stays active';

  @override
  String get sosAlertStatusActive => 'Incident: ACTIVE';

  @override
  String get sosAlertStatusAcknowledged => 'Incident: ACKNOWLEDGED';

  @override
  String get sosAlertStatusEscalating => 'Incident: ESCALATING';

  @override
  String get sosAlertLocationAcquiring => 'Location: ACQUIRING';

  @override
  String get sosAlertLocationReady => 'Location: READY';

  @override
  String get sosAlertLocationStale => 'Location: STALE';

  @override
  String get sosAlertLocationUnavailable => 'Location: UNAVAILABLE';

  @override
  String sosAlertDeliveryPending(String channel, String recipient) {
    return '$channel → $recipient: PENDING';
  }

  @override
  String sosAlertDeliveryFailed(String channel, String recipient) {
    return '$channel → $recipient: FAILED';
  }

  @override
  String sosAlertDeliveryUnavailable(String channel, String recipient) {
    return '$channel → $recipient: UNAVAILABLE';
  }

  @override
  String sosAlertDeliveryNotConfigured(String channel, String recipient) {
    return '$channel → $recipient: NOT_CONFIGURED';
  }

  @override
  String sosAlertDeliveryDelivered(String channel, String recipient) {
    return '$channel → $recipient: DELIVERED';
  }

  @override
  String get sosAlertBreakGlassCta => 'Temporary break-glass override…';

  @override
  String get sosAlertBreakGlassSemantics =>
      'Open temporary break-glass override sheet';

  @override
  String get sosBreakGlassTitle => 'Temporary break-glass';

  @override
  String sosBreakGlassBody(int minutes) {
    return 'This temporarily unlocks SOS response tools for $minutes minutes. It does not change permanent SOS policy and is audited.';
  }

  @override
  String get sosBreakGlassReasonLabel => 'Reason / context';

  @override
  String get sosBreakGlassContinueCta => 'Continue';

  @override
  String get sosBreakGlassConfirmCta => 'Confirm temporary override';

  @override
  String get sosBreakGlassCancelCta => 'Cancel';

  @override
  String get sosAlertObserverViewOnlyNote =>
      'Observer: view and acknowledge only — resolve, escalate, and setup are not available';

  @override
  String get sosAlertHonestyBanner =>
      'SOS is always available — delivery channels show honest status only';

  @override
  String get sosAlertIncidentNote =>
      'Emergency incident is open — location and delivery status below are honest';

  @override
  String get childSosInProgressLocationPending =>
      'Location status shown honestly — GPS provider not active in this build';

  @override
  String get childSosInProgressDeliveryHonesty =>
      'Parent notification status is shown per channel — no silent success';

  @override
  String get childSosInProgressCallUnavailableToast =>
      'Calling is not available in this build — SOS stays active';

  @override
  String get sosLadderMaxBackupsError => 'Maximum 5 backup contacts';

  @override
  String get sosLadderVerificationUnverified => 'UNVERIFIED';

  @override
  String get sosLadderVerificationPending => 'PENDING';

  @override
  String get sosLadderVerificationVerified => 'VERIFIED';

  @override
  String get sosLadderVerificationRevoked => 'REVOKED';

  @override
  String get sosLadderVerificationFailed => 'FAILED';

  @override
  String sosLadderPriorityLabel(int priority) {
    return 'P$priority';
  }

  @override
  String get sosLadderReadOnlyTitle => 'View only';

  @override
  String get sosLadderReadOnlyMessage =>
      'Only the primary parent or mother with Full access can edit emergency contacts';

  @override
  String get sosPanicQuietTitle => 'Panic Quiet Mode (child)';

  @override
  String get sosPanicQuietSubtitle =>
      'When preferred, the child SOS active screen shows critical status only';

  @override
  String get sosReadinessTitle => 'Capability readiness';

  @override
  String get sosReadinessBody =>
      'Push, SMS, and calling are NOT_CONFIGURED in this UI slice. SOS still fires in-app.';

  @override
  String get sosAlertConnectionOnline => 'Connection: ONLINE';

  @override
  String get sosAlertConnectionDegraded => 'Connection: DEGRADED';

  @override
  String get sosAlertConnectionOffline => 'Connection: OFFLINE';

  @override
  String get sosBreakGlassCapabilityDefault => 'SOS response tools';

  @override
  String get resultsFollowupActivityQuizSubmittedTitle =>
      'Child quiz submitted';

  @override
  String get resultsFollowupActivityJustSubmitted =>
      'Just submitted — awaiting your review';

  @override
  String get materialsLessonsSubjectCustom => 'New subject';

  @override
  String get materialsLessonsMetaJustAdded => 'Just added — ready for lessons';

  @override
  String materialsLessonsMetaLessonCount(int count) {
    return '$count lessons';
  }

  @override
  String get materialsLessonsAddSubjectPersistedToast =>
      'Subject added to your materials';

  @override
  String get materialsLessonsAddLessonPersistedToast =>
      'Lesson slot added — pick a source next';

  @override
  String get dayBoardPendingQuizSubmittedTitle => 'Child quiz submitted';

  @override
  String get dayBoardPendingJustSubmitted =>
      'Just submitted — open results follow-up';

  @override
  String dayBoardPendingEarnedMinutes(int minutes) {
    return 'Earned +$minutes minutes — review on Results';
  }

  @override
  String get quranProgressSurahMulk => 'Al-Mulk';

  @override
  String get quranProgressCycleSurahCta => 'Switch ward surah';

  @override
  String quranProgressCycleSurahToast(String surah) {
    return 'Ward surah set to $surah — save to send to your child';
  }

  @override
  String get quranProgressPublishPlanCta => 'Save plan to child';

  @override
  String quranProgressPublishPlanToast(String surah, int minutes) {
    return 'Ward plan sent — $surah · +$minutes minutes reward';
  }

  @override
  String get childQuranWardAyahNaba1 => 'عَمَّ يَتَسَاءَلُونَ ﴿١﴾';

  @override
  String get sys3MockHonesty =>
      'This local prototype updates in-memory identity data. Server sync is not connected yet.';

  @override
  String get sys3SessionRestoreTitle => 'Restore session';

  @override
  String get sys3SessionRestoreBody =>
      'Restore this expired session on this device.';

  @override
  String get sys3SessionRestoreAction => 'Restore session';

  @override
  String get sys3SessionExpiredTitle => 'Session expired';

  @override
  String get sys3SessionExpiredBody =>
      'Your sign-in session ended. Restore it or sign in again.';

  @override
  String get sys3SignInAgain => 'Sign in again';

  @override
  String get sys3LogoutTitle => 'Log out';

  @override
  String get sys3LogoutBody => 'End the current adult session on this device?';

  @override
  String get sys3LogoutAction => 'Log out now';

  @override
  String get sys3RecoveryTitle => 'Account recovery';

  @override
  String get sys3RecoveryBody =>
      'Enter your email. This prototype confirms the request locally without claiming an email was sent.';

  @override
  String get sys3RecoveryAction => 'Request recovery';

  @override
  String get sys3RecoverySuccess => 'Recovery request recorded locally.';

  @override
  String get sys3DeactivateTitle => 'Deactivate account';

  @override
  String get sys3DeactivateBody =>
      'Deactivate this account and revoke all of its sessions?';

  @override
  String get sys3DeactivateAction => 'Deactivate account';

  @override
  String get sys3DeactivateSuccess =>
      'Account deactivated and sessions revoked.';

  @override
  String get sys3FamilySelectTitle => 'Choose family';

  @override
  String get sys3FamilySelectBody =>
      'Select the family context you want to open.';

  @override
  String get sys3FamilySingle =>
      'Only one family is available. Opening it now.';

  @override
  String get sys3RemoveAdultTitle => 'Remove adult';

  @override
  String get sys3RemoveAdultBody =>
      'Remove this co-parent from the active family?';

  @override
  String get sys3RemoveAdultAction => 'Remove member';

  @override
  String get sys3TransferTitle => 'Transfer ownership';

  @override
  String get sys3TransferBody =>
      'Choose an eligible adult. They will become the primary owner.';

  @override
  String get sys3TransferAction => 'Transfer ownership';

  @override
  String get sys3LeaveTitle => 'Leave family';

  @override
  String get sys3LeaveBody =>
      'Leave the active family? Primary owners must transfer ownership first.';

  @override
  String get sys3LeaveAction => 'Leave family';

  @override
  String get sys3InviteStatusTitle => 'Invite status';

  @override
  String get sys3InviteStatusBody =>
      'Enter an invite token to inspect its current lifecycle.';

  @override
  String get sys3InviteTokenLabel => 'Invite token';

  @override
  String get sys3InviteLookupAction => 'Check status';

  @override
  String get sys3InviteUnknown => 'No invite matches this token.';

  @override
  String get sys3AdultSessionsTitle => 'Adult sessions';

  @override
  String get sys3ChildSessionsTitle => 'Child sessions';

  @override
  String get sys3SessionsEmpty => 'No sessions are available.';

  @override
  String get sys3RevokeAction => 'Revoke';

  @override
  String get sys3RemoteEndTitle => 'End child session';

  @override
  String get sys3RemoteEndBody =>
      'End this child session remotely? This does not remove the device enrollment.';

  @override
  String get sys3RemoteEndAction => 'End session';

  @override
  String get sys3RevokeTitle => 'Confirm revocation';

  @override
  String get sys3RevokeBody => 'Revoke the selected session or enrollment?';

  @override
  String get sys3DeniedTitle => 'Primary owner required';

  @override
  String get sys3DeniedBody =>
      'Only the primary owner can perform this action.';

  @override
  String get sys3SuccessTitle => 'Completed';

  @override
  String get sys3SuccessBody => 'The identity change was applied locally.';

  @override
  String get sys3ErrorTitle => 'Unable to complete';

  @override
  String get sys3ErrorBody =>
      'The requested identity change could not be applied.';

  @override
  String sys3MemberLabel(String id) {
    return 'Member $id';
  }

  @override
  String sys3SessionLabel(String id) {
    return 'Session $id';
  }

  @override
  String sys3EnrollmentLabel(String id) {
    return 'Enrollment $id';
  }

  @override
  String get sys3SettingsLogout => 'Log out';

  @override
  String get sys3SettingsAdultSessions => 'Adult sessions';

  @override
  String get sys3SettingsChildSessions => 'Child sessions';

  @override
  String get sys3SettingsRecovery => 'Account recovery';

  @override
  String get sys3SettingsDeactivate => 'Deactivate account';

  @override
  String get sys3SettingsFamilySelector => 'Switch family';

  @override
  String get sys3FamilyTransferCta => 'Transfer family ownership';

  @override
  String get sys3FamilySelectorCta => 'Open family selector';

  @override
  String get sys3FamilyLeaveCta => 'Leave this family';

  @override
  String get sys3FamilyRemoveCta => 'Remove adult';

  @override
  String get sys3InviteStatusCta => 'View invite status';

  @override
  String get capabilityStatusImplemented => 'IMPLEMENTED';

  @override
  String get capabilityStatusMockRemote => 'MOCK-REMOTE';

  @override
  String get capabilityStatusDegraded => 'DEGRADED';

  @override
  String get capabilityStatusUnsupported => 'UNSUPPORTED';

  @override
  String get capabilityStatusNotImplemented => 'NOT IMPLEMENTED';

  @override
  String get locationGpsCapabilityLabel => 'Device GPS';

  @override
  String get locationGpsNotImplementedBanner =>
      'Device GPS is NOT IMPLEMENTED in this build — maps are decorative; fixes must be injected honestly. Never treat this screen as live tracking.';

  @override
  String get createSafeZoneAssignHeading => 'Assign to children';

  @override
  String get createSafeZoneAssignHint =>
      'Select at least one child before saving (required).';

  @override
  String get createSafeZoneNeedAssignment =>
      'Select at least one child for this zone.';

  @override
  String createSafeZoneChildChipSemantics(String name) {
    return 'Assign zone to $name';
  }

  @override
  String get silentLocateTitle => 'Silent location request';

  @override
  String silentLocateBody(String name) {
    return 'Request a quiet locate for $name. The child will not see an interactive prompt.';
  }

  @override
  String get silentLocateConfirmCta => 'Request locate';

  @override
  String get silentLocateDismissCta => 'Done';

  @override
  String get silentLocateResultPending => 'Pending — acquire in progress';

  @override
  String get silentLocateResultLocated => 'Located — last honest fix available';

  @override
  String get silentLocateResultStale => 'Stale last-known — not a fresh fix';

  @override
  String get silentLocateResultUnavailable => 'Unavailable — no usable fix';

  @override
  String get silentLocateResultGpsNotImplemented =>
      'Device GPS is NOT IMPLEMENTED — cannot claim a live silent locate.';

  @override
  String get locationMapSilentLocateCta => 'Silent locate';

  @override
  String get childArrivalSilentBanner =>
      'Check-in only — named places. No live map or coordinates on the child side.';

  @override
  String get fs004ParentPanelTitle => 'Screen & Camera (FS-004)';

  @override
  String get fs004PlanesHonestyHint =>
      'Camera OS & capture planes — not device-enforced yet';

  @override
  String get fs004PreventCameraOs => 'Restrict device camera';

  @override
  String get fs004PreventCameraOsSub =>
      'OS/device intent — not the Camera app package block';

  @override
  String get fs004PreventCapture => 'Capture prevention';

  @override
  String get fs004PreventCaptureSub =>
      'Where the platform can — not a universal screenshot block';

  @override
  String get fs004MonitorScreenshots => 'Screenshot monitoring';

  @override
  String get fs004MonitorScreenshotsSub =>
      'Child sees a clear notice — policy owned here, not a second Smart Alerts store';

  @override
  String get fs004ProtectSurfaces => 'Protect Family OS surfaces';

  @override
  String get fs004ProtectSurfacesSub =>
      'Protects Family OS screens where supportable';

  @override
  String get fs004PackageVsOsNote =>
      'Blocking the Camera app is App Control (FS-003). Device camera restriction is separate.';

  @override
  String get fs004MicOutOfScope =>
      'Microphone and SOS audio are not controlled here.';

  @override
  String get fs004ChildPreviewHeading => 'What your child sees';

  @override
  String get fs004ChildTransparencyTitle => 'Camera & capture status';

  @override
  String get fs004ChildMonitorNotice =>
      'Screenshot / capture monitoring is ON for configured apps. Your family can be notified when a capture is observed (when supported).';

  @override
  String get fs004ChildNotSecret => 'This is not a secret.';

  @override
  String get fs004StatusCameraLabel => 'Device camera';

  @override
  String get fs004StatusCaptureLabel => 'Capture prevention';

  @override
  String get fs004StatusMonitorLabel => 'Monitoring';

  @override
  String get fs004StatusRestricted => 'Restricted';

  @override
  String get fs004StatusOff => 'Off';

  @override
  String get fs004StatusOnLimited => 'On (limited)';

  @override
  String get fs004StatusOnSeeNotice => 'On — see notice';

  @override
  String get fs004SmartAlertsPolicyOwned =>
      'Screenshot monitoring policy is owned by Screen & Camera (FS-004). This screen is entry / notify only.';

  @override
  String get fs005ModesOwnershipBanner =>
      'Lifestyle scheduling is owned by Modes (FS-005). Screen Time minutes stay separate. ScheduleWindow is not a second Mode authority.';

  @override
  String get fs005OsWakeHonestyHint => 'Device wake / Focus scheduling';

  @override
  String get fs005ExamsMapsToStudyHint =>
      'Exams uses Study Mode (not a separate catalog entry).';

  @override
  String get fs005ChildModeIdle => 'No Mode is on right now.';

  @override
  String fs005ChildModeOn(String modeName) {
    return '$modeName Mode is on';
  }

  @override
  String fs005ChildModesOn(String modeNames) {
    return 'Modes on: $modeNames';
  }

  @override
  String get fs005ChildModeLimited => 'Some apps and sites are limited now.';

  @override
  String get fs005ChildModesStricter =>
      'Stricter rules apply while more than one Mode is on.';

  @override
  String get fs005ChildReachability =>
      'SOS · Family Chat · Quran stay reachable.';

  @override
  String get fs007TicketPanelTitle => 'Safety review tickets';

  @override
  String get fs007SuggestOnlyBanner =>
      'AI classification is a safety signal only. Suggestions need your approval — lists, apps, and Modes are not changed automatically.';

  @override
  String get fs007NotPolicyExecutor =>
      'AI is not a policy executor on this screen.';

  @override
  String get fs007TicketEmpty => 'No open safety review tickets.';

  @override
  String get fs007TicketDetailHeading => 'Ticket detail';

  @override
  String get fs007TicketMetaMissing => 'Metadata unavailable';

  @override
  String get fs007PreviewUnavailable => 'Preview unavailable — metadata only.';

  @override
  String get fs007ActionResolve => 'Resolve';

  @override
  String get fs007ActionDismissFp => 'Dismiss as false positive';

  @override
  String get fs007ActionSuggestWf =>
      'Suggest Web Filter review (human approve)';

  @override
  String get fs007CategorySexual => 'Sexual content';

  @override
  String get fs007CategorySensitiveVisual => 'Sensitive visual';

  @override
  String get fs007CategoryViolence => 'Violence or threat';

  @override
  String get fs007CategorySelfHarm => 'Self-harm signal';

  @override
  String get fs007CategoryPredatory => 'Predatory or grooming signal';

  @override
  String get fs007CategorySubstance => 'Substance or gambling';

  @override
  String get fs007CategorySuspicious => 'Suspicious language';

  @override
  String get fs007CategoryUncategorized => 'Uncategorized concern';

  @override
  String get fs007CertaintyUnknown => 'Unknown';

  @override
  String get fs007CertaintyPreliminary => 'Preliminary';

  @override
  String get fs007CertaintyAnalysis => 'Analysis';

  @override
  String get fs007CertaintyConfirmed => 'Confirmed';

  @override
  String get fs007SeverityLow => 'Low';

  @override
  String get fs007SeverityElevated => 'Elevated';

  @override
  String get fs007SeverityHigh => 'High';

  @override
  String get fs007ChildTransparencyTitle => 'On-device safety tools';

  @override
  String get fs007ChildOnDeviceNote =>
      'When analysis is on, it runs offline on this device — not a secret always-watching claim.';

  @override
  String get fs007ToolSearch => 'Search analysis';

  @override
  String get fs007ToolImage => 'Image classification';

  @override
  String get fs007ToolScreenshot => 'Screenshot monitoring';

  @override
  String get fs007ToolStateOff => 'Off';

  @override
  String get fs007ToolStateOnDevice => 'On (on-device)';

  @override
  String get fs007ToolStateDegraded => 'Degraded';

  @override
  String get fs007ToolStateUnsupported => 'Unsupported';

  @override
  String get fs007SmartAlertsEntry =>
      'Offline AI Safety tickets (FS-007) — signals only; never auto-blocks.';
}
