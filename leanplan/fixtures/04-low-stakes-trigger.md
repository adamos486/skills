# Plan: Birthday Reminder Script

## Goal

I keep forgetting friends' birthdays. Write a script I run on my own laptop that reads my
exported contacts CSV and prints whose birthday is in the next 7 days.

Just for me. Nothing is deployed, nothing is shared, no server. If it breaks I'll notice
because I won't get the reminder, and I'll fix it that evening.

Stack: a single Python file. Standard library only.

## Work

1. Read `~/contacts.csv` (name, birthday columns) with the `csv` module.
2. Compute who has a birthday within 7 days, handling Feb 29 by treating it as Mar 1.
3. Print the list, sorted by date. Print "nothing this week" when empty.
4. I'll add it to my crontab myself.

## Acceptance

- Running it prints the right names for a contacts file I hand-check.
- A contacts file with nobody upcoming prints "nothing this week".
- A birthday on Feb 29 shows up on Mar 1 in a non-leap year.
