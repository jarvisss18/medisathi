import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'medicine_repository.dart';
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

class SavedMedicinesNotifier extends Notifier<List<SavedMedicine>> {
  @override
  List<SavedMedicine> build() {
    final repo = ref.watch(medicineRepositoryProvider);
    return repo.savedMedicines;
  }

  void add(SavedMedicine med) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.addSavedMedicine(med);
    state = List.from(repo.savedMedicines);
  }

  void remove(String id) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.removeSavedMedicine(id);
    state = List.from(repo.savedMedicines);
  }
}

final savedMedicinesProvider = NotifierProvider<SavedMedicinesNotifier, List<SavedMedicine>>(SavedMedicinesNotifier.new);

class RemindersNotifier extends Notifier<List<ReminderItem>> {
  @override
  List<ReminderItem> build() {
    final repo = ref.watch(medicineRepositoryProvider);
    return repo.reminders;
  }

  void add(ReminderItem item) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.addReminder(item);
    state = List.from(repo.reminders);
  }

  void toggle(String id, bool enabled) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.toggleReminder(id, enabled);
    state = List.from(repo.reminders);
  }

  void delete(String id) {
    final repo = ref.read(medicineRepositoryProvider);
    repo.deleteReminder(id);
    state = List.from(repo.reminders);
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
