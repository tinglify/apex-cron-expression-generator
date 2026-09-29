# apex-cron-expression-generator

Apex helpers for building Salesforce cron expressions, so scheduling code reads
as intent rather than as a string of asterisks.

Salesforce expects seven space-separated fields, the last optional:

```
Seconds Minutes Hours Day_of_month Month Day_of_week Year
```

Day of week runs 1 (Sunday) through 7 (Saturday), and day-of-month and
day-of-week are mutually exclusive — whichever is unused must be `?`.

## Usage

```apex
System.schedule('Nightly sync', CronExpressionGenerator.dailyAt(2, 30), new NightlySync());
```

| Call                                          | Expression            |
| --------------------------------------------- | --------------------- |
| `dailyAt(2, 30)`                              | `0 30 2 * * ?`        |
| `weekdaysAt(6, 0)`                            | `0 0 6 ? * 2,3,4,5,6` |
| `weeklyOn(Weekday.SUNDAY, 23, 15)`            | `0 15 23 ? * 1`       |
| `monthlyOnDay(15, 1, 0)`                      | `0 0 1 15 * ?`        |
| `lastDayOfMonth(22, 45)`                      | `0 45 22 L * ?`       |
| `nthWeekdayOfMonth(2, Weekday.TUESDAY, 9, 0)` | `0 0 9 ? * 3#2`       |
| `everyNHours(4, 0, 0)`                        | `0 0 0/4 * * ?`       |
| `everyNMinutes(15, 5)`                        | `0 5/15 * * * ?`      |

Out-of-range arguments throw `CronExpressionGenerator.CronExpressionException`.

## Development

```sh
sf org create scratch --definition-file config/project-scratch-def.json --alias cron --set-default
sf project deploy start
npm test
```

Formatting is handled by Prettier with `prettier-plugin-apex`:

```sh
npm install
npm run prettier
```
