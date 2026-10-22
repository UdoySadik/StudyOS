import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/calendar_model.dart';

final calendarMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

class MonthYearKey {
  final int year;
  final int month;
  const MonthYearKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

final calendarEventsProvider =
    AsyncNotifierProviderFamily<CalendarEventsNotifier, CalendarMonthEvents, MonthYearKey>(
  CalendarEventsNotifier.new,
);

class CalendarEventsNotifier extends FamilyAsyncNotifier<CalendarMonthEvents, MonthYearKey> {
  @override
  Future<CalendarMonthEvents> build(MonthYearKey arg) async {
    final res = await ApiService().get('/calendar/events', queryParams: {
      'year': arg.year.toString(),
      'month': arg.month.toString(),
    }) as Map<String, dynamic>;
    return CalendarMonthEvents.fromJson(res);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
