@IsTest
private class CronExpressionGeneratorTest {
  @IsTest
  static void dailyAtBuildsExpression() {
    Assert.areEqual('0 30 2 * * ?', CronExpressionGenerator.dailyAt(2, 30));
  }

  @IsTest
  static void weekdaysAtCoversMondayThroughFriday() {
    Assert.areEqual(
      '0 0 6 ? * 2,3,4,5,6',
      CronExpressionGenerator.weekdaysAt(6, 0)
    );
  }

  @IsTest
  static void weeklyOnSingleDay() {
    Assert.areEqual(
      '0 15 23 ? * 1',
      CronExpressionGenerator.weeklyOn(
        CronExpressionGenerator.Weekday.SUNDAY,
        23,
        15
      )
    );
  }

  @IsTest
  static void monthlyOnDayBuildsExpression() {
    Assert.areEqual(
      '0 0 1 15 * ?',
      CronExpressionGenerator.monthlyOnDay(15, 1, 0)
    );
  }

  @IsTest
  static void lastDayOfMonthBuildsExpression() {
    Assert.areEqual(
      '0 45 22 L * ?',
      CronExpressionGenerator.lastDayOfMonth(22, 45)
    );
  }

  @IsTest
  static void nthWeekdayOfMonthBuildsExpression() {
    Assert.areEqual(
      '0 0 9 ? * 3#2',
      CronExpressionGenerator.nthWeekdayOfMonth(
        2,
        CronExpressionGenerator.Weekday.TUESDAY,
        9,
        0
      )
    );
  }

  @IsTest
  static void everyNHoursBuildsExpression() {
    Assert.areEqual(
      '0 0 0/4 * * ?',
      CronExpressionGenerator.everyNHours(4, 0, 0)
    );
  }

  @IsTest
  static void everyNMinutesBuildsExpression() {
    Assert.areEqual(
      '0 5/15 * * * ?',
      CronExpressionGenerator.everyNMinutes(15, 5)
    );
  }

  @IsTest
  static void invalidHourThrows() {
    try {
      CronExpressionGenerator.dailyAt(24, 0);
      Assert.fail('Expected a CronExpressionException.');
    } catch (CronExpressionGenerator.CronExpressionException e) {
      Assert.areEqual('Hour must be between 0 and 23.', e.getMessage());
    }
  }

  @IsTest
  static void emptyWeekdayListThrows() {
    try {
      CronExpressionGenerator.weeklyOn(
        new List<CronExpressionGenerator.Weekday>(),
        8,
        0
      );
      Assert.fail('Expected a CronExpressionException.');
    } catch (CronExpressionGenerator.CronExpressionException e) {
      Assert.areEqual('At least one weekday is required.', e.getMessage());
    }
  }

  @IsTest
  static void generatedExpressionIsAcceptedByScheduler() {
    String cron = CronExpressionGenerator.dailyAt(3, 0);

    Test.startTest();
    String jobId = System.schedule(
      'CronExpressionGeneratorTest',
      cron,
      new NoOpSchedulable()
    );
    Test.stopTest();

    CronTrigger job = [
      SELECT CronExpression
      FROM CronTrigger
      WHERE Id = :jobId
    ];
    Assert.areEqual(cron, job.CronExpression);
  }

  private class NoOpSchedulable implements Schedulable {
    public void execute(SchedulableContext context) {
      // Intentionally empty; only used to validate the expression parses.
    }
  }
}
