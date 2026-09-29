/**
 * Builds Salesforce-compatible cron expressions for use with System.schedule().
 *
 * Salesforce expects seven space-separated fields, the last of which is optional:
 *   Seconds Minutes Hours Day_of_month Month Day_of_week Year
 *
 * Day_of_month and Day_of_week cannot both be specified; whichever is unused
 * must be '?' rather than '*'.
 */
public inherited sharing class CronExpressionGenerator {

  public enum Weekday {
    SUNDAY,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
  }

  private static final Map<Weekday, Integer> WEEKDAY_NUMBER = new Map<Weekday, Integer>{
    Weekday.SUNDAY => 1,
    Weekday.MONDAY => 2,
    Weekday.TUESDAY => 3,
    Weekday.WEDNESDAY => 4,
    Weekday.THURSDAY => 5,
    Weekday.FRIDAY => 6,
    Weekday.SATURDAY => 7
  };

  private static final String ANY = '*';
  private static final String UNUSED = '?';
  private static final String ZERO = '0';

  /**
   * Fires at a specific date and time.
   */
  public static String at(DateTime dateTime) {
    return build(
      ZERO,
      String.valueOf(dateTime.minute()),
      String.valueOf(dateTime.hour()),
      String.valueOf(dateTime.day()),
      String.valueOf(dateTime.month()),
      String.valueOf(dateTime.year())
    );
  }

  /**
   * Fires once a day at the given local time.
   */
  public static String dailyAt(Integer hour, Integer minute) {
    validateTime(hour, minute);
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      ANY,
      ANY,
      UNUSED
    );
  }

  /**
   * Fires Monday through Friday at the given local time.
   */
  public static String weekdaysAt(Integer hour, Integer minute) {
    return weeklyOn(
      new List<Weekday>{
        Weekday.MONDAY,
        Weekday.TUESDAY,
        Weekday.WEDNESDAY,
        Weekday.THURSDAY,
        Weekday.FRIDAY
      },
      hour,
      minute
    );
  }

  public static String weeklyOn(Weekday day, Integer hour, Integer minute) {
    return weeklyOn(new List<Weekday>{ day }, hour, minute);
  }

  /**
   * Fires on each of the given days at the same local time.
   */
  public static String weeklyOn(
    List<Weekday> days,
    Integer hour,
    Integer minute
  ) {
    validateTime(hour, minute);
    if (days == null || days.isEmpty()) {
      throw new CronExpressionException('At least one weekday is required.');
    }
    List<String> numbers = new List<String>();
    for (Weekday day : days) {
      numbers.add(String.valueOf(WEEKDAY_NUMBER.get(day)));
    }
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      UNUSED,
      ANY,
      String.join(numbers, ',')
    );
  }

  public static String semiMonthlyOn(Integer day, Integer hour, Integer minute) {
    validateTime(hour, minute);
    if (day == null || day < 1 || day > 31) {
      throw new CronExpressionException('Day must be between 1 and 31.');
    }
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      String.valueOf(day),
      ANY,
      UNUSED
    );
  }

  /**
   * Fires on a fixed calendar day each month, e.g. the 15th.
   */
  public static String monthlyOnDay(
    Integer dayOfMonth,
    Integer hour,
    Integer minute
  ) {
    validateTime(hour, minute);
    if (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 31) {
      throw new CronExpressionException(
        'Day of month must be between 1 and 31.'
      );
    }
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      String.valueOf(dayOfMonth),
      ANY,
      UNUSED
    );
  }

  /**
   * Fires on the last day of every month.
   */
  public static String lastDayOfMonth(Integer hour, Integer minute) {
    validateTime(hour, minute);
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      'L',
      ANY,
      UNUSED
    );
  }

  /**
   * Fires on the nth occurrence of a weekday each month, e.g. the 2nd Tuesday.
   */
  public static String nthWeekdayOfMonth(
    Integer occurrence,
    Weekday day,
    Integer hour,
    Integer minute
  ) {
    validateTime(hour, minute);
    if (occurrence == null || occurrence < 1 || occurrence > 5) {
      throw new CronExpressionException('Occurrence must be between 1 and 5.');
    }
    String dayOfWeek = WEEKDAY_NUMBER.get(day) + '#' + occurrence;
    return build(
      ZERO,
      String.valueOf(minute),
      String.valueOf(hour),
      UNUSED,
      ANY,
      dayOfWeek
    );
  }

  /**
   * Fires every `interval` hours starting at `startHour`.
   */
  public static String everyNHours(
    Integer interval,
    Integer startHour,
    Integer minute
  ) {
    validateTime(startHour, minute);
    if (interval == null || interval < 1 || interval > 23) {
      throw new CronExpressionException(
        'Hour interval must be between 1 and 23.'
      );
    }
    String hours = startHour + '/' + interval;
    return build(ZERO, String.valueOf(minute), hours, ANY, ANY, UNUSED);
  }

  /**
   * Fires every `interval` minutes. Note that a single scheduled job cannot run
   * more often than hourly, so this is intended for callers that stagger several
   * jobs across the hour.
   */
  public static String everyNMinutes(Integer interval, Integer startMinute) {
    validateTime(0, startMinute);
    if (interval == null || interval < 1 || interval > 59) {
      throw new CronExpressionException(
        'Minute interval must be between 1 and 59.'
      );
    }
    String minutes = startMinute + '/' + interval;
    return build(ZERO, minutes, ANY, ANY, ANY, UNUSED);
  }

  private static String build(
    String seconds,
    String minutes,
    String hours,
    String dayOfMonth,
    String month,
    String dayOfWeek
  ) {
    return String.join(
      new List<String>{ seconds, minutes, hours, dayOfMonth, month, dayOfWeek },
      ' '
    );
  }

  private static void validateTime(Integer hour, Integer minute) {
    if (hour == null || hour < 0 || hour > 23) {
      throw new CronExpressionException('Hour must be between 0 and 23.');
    }
    if (minute == null || minute < 0 || minute > 59) {
      throw new CronExpressionException('Minute must be between 0 and 59.');
    }
  }

  public class CronExpressionException extends Exception {}
}
