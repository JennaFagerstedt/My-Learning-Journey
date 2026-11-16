# Task 2: Who left the server room?

> The attackers stole the computer holding all account credentials. There was no sign of forced entry, so it was probably someone with a badge. Every entry and exit is logged in `access.log`. The theft happened on the 14th between 13:00 and 18:59.

This is the task closest to real SOC work: a plain-text log, a time window, and a question about who was there.

## The log format

```
DAY HOUR in|out ID
14 15 out id013
```

`HOUR` is a whole hour, so the line `14 18 out id012` means the person left sometime between 18:00 and 18:59.

## The idea
1. Read the file with `with open(path, encoding="utf-8")`.
2. Split each line into its four parts.
3. Keep the lines where **all three** conditions hold: day 14, direction `out`, hour 13-18.
4. Add each ID only once.

```python
dag, tid, riktning, person_id = rad.split()
dag = int(dag)
tid = int(tid)
if dag == 14 and riktning == "out" and 13 <= tid <= 18:
    ...
```

## Result
Four people left the server room in the time window: **`id001`, `id009`, `id007`, `id015`**.

## What I learned

### Why `with`?
`with` closes the file automatically when the block ends, **even if an error occurs** inside it. I read the lines inside the block and did the filtering after it, so the file is only open while it is actually being read.

### `encoding="utf-8"` on Windows
`open()` on Windows does not always default to UTF-8, which can turn å/ä/ö into garbage or crash. Stating the encoding explicitly is a habit I'll keep, and it belongs in the list of assumptions.

### Lines end with `\n`
Printing the first lines showed `'1 8 in id008\n'`. Without handling it, the ID would be `'id008\n'`. `split()` with no arguments splits on all whitespace, including the newline, so it solves this for free.

### Strings compare as text
After `split()`, the day and hour are still strings, and `'9' > '13'` is **True**, because strings are compared character by character and `'9'` comes after `'1'`. Converting with `int()` is not optional.

### Quotes matter
`riktning == out` gave `NameError: name 'out' is not defined`: without quotes Python looks for a variable. The value to compare with is the text `"out"`.

### Precise beats clever
I first wrote `13 <= tid <= 18.59` to mean "up to 18:59". It happens to work, but `18.59` is the number 18.59, not a time. Since the log only has whole hours, `<= 18` already covers 18:00-18:59, and a comment explains it. Code that *looks* like it means something else is a bug waiting to happen.

### Duplicates
One of the provided tests failed with `['id011', 'id013', 'id013', ...]`: `id013` left twice within the window. The question is *who* left, not how many times, so I only add an ID if it is not already in the list (`if person_id not in ids`).

## My own tests
The provided tests were described as "deliberately picky". I added three of my own, each varying **only one thing** so that a failure points to exactly one condition:

| Test | What varies | Why |
|---|---|---|
| Time boundaries | Hours 12, 13, 18, 19 on day 14 | The interval must include both ends, and nothing outside |
| Wrong day | Days 14, 13, 15, 1 and 4 | Day 1 and 4 contain digits from "14" and catch a solution that compares text instead of numbers |
| Direction | `in` and `out`, including one person who goes in and then out | Only exits count, and a person who leaves should be counted once |

Each test writes a small log file with pytest's `tmp_path` fixture, so the tests never depend on the real data file.
