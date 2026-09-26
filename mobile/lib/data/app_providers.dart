import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'medicine_repository.dart';
import 'auth_repository.dart';
import 'models.dart';
import '../core/voice/tts_service.dart';
import '../core/gate/confidence_gate.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final repo = MedicineRepository();
  repo.init();
  return repo;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = AuthRepository();
  auth.init();
  return auth;
});

class CurrentUserNotifier extends Notifier<AuthUser?> {
  @override
  AuthUser? build() {
    final auth = ref.watch(authRepositoryProvider);
    void listener() {
      state = auth.currentUser;
    }
    auth.addListener(listener);
    ref.onDispose(() => auth.removeListener(listener));
    return auth.currentUser;
  }

  void logout() {
    ref.read(authRepositoryProvider).logout();
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AuthUser?>(CurrentUserNotifier.new);


class SavedMedicinesNotifier extends Notifier<List<SavedMedicine>> {
  @override
  List<SavedMedicine> build() {
    final repo = ref.watch(medicineRepositoryProvider);
    void listener() {
      state = List.from(repo.savedMedicines);
    }
    repo.addListener(listener);
    ref.onDispose(() => repo.removeListener(listener));
    return List.from(repo.savedMedicines);
  }

  void add(SavedMedicine med) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.addSavedMedicine(med);
  }

  String addCustom({
    required String name,
    required String brand,
    required String strength,
    required String dosageForm,
    required String timing,
    required String usageInstruction,
    String? customId,
  }) {
    final repo = ref.read(medicineRepositoryProvider);
    return repo.addCustomMedicine(
      name: name,
      brand: brand,
      strength: strength,
      dosageForm: dosageForm,
      timing: timing,
      usageInstruction: usageInstruction,
      customId: customId,
    );
  }

  void remove(String id) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.removeSavedMedicine(id);
  }
}

final savedMedicinesProvider = NotifierProvider<SavedMedicinesNotifier, List<SavedMedicine>>(SavedMedicinesNotifier.new);

class RemindersNotifier extends Notifier<List<ReminderItem>> {
  @override
  List<ReminderItem> build() {
    final repo = ref.watch(medicineRepositoryProvider);
    void listener() {
      state = List.from(repo.reminders);
    }
    repo.addListener(listener);
    ref.onDispose(() => repo.removeListener(listener));
    return List.from(repo.reminders);
  }

  void refresh() {
    final repo = ref.read(medicineRepositoryProvider);
    state = List.from(repo.reminders);
  }

  void add(ReminderItem item) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.addReminder(item);
  }

  void toggle(String id, bool enabled) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.toggleReminder(id, enabled);
  }

  void delete(String id) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.deleteReminder(id);
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, List<ReminderItem>>(RemindersNotifier.new);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool val) => state = val;
}

final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);

class CurrentLangNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  void set(String lang) => state = lang;
}

final currentLangProvider = NotifierProvider<CurrentLangNotifier, String>(CurrentLangNotifier.new);

class ConsecutiveFailuresNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void reset() => state = 0;
}

final consecutiveScanFailuresProvider = NotifierProvider<ConsecutiveFailuresNotifier, int>(ConsecutiveFailuresNotifier.new);

class ActiveDecisionNotifier extends Notifier<VerificationDecision?> {
  @override
  VerificationDecision? build() => null;

  void set(VerificationDecision? decision) => state = decision;
}

final activeVerificationDecisionProvider = NotifierProvider<ActiveDecisionNotifier, VerificationDecision?>(ActiveDecisionNotifier.new);
