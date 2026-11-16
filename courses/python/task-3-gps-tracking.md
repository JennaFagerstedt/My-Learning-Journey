# Task 3: Finding the stolen computer

> The IT security department had hidden GPS trackers in all company computers. Their positions are saved in `tracking.json`. With a bit of luck, the stolen computer is not near any of the others.

Of the three tasks, this was the one with the most design decisions: what counts as "near", what to do when the answer is not clear, and how to test a comparison between floats.

## The data

```json
{"link": [57.7092, 11.9742], "zelda": [59.3291, 18.0681], "ganon": [59.3292, 18.0689], ...}
```

A dictionary: the computer's name is the key and `[latitude, longitude]` is the value. `json.load` turns the text into real Python objects, so the coordinates are numbers I can calculate with.

Before writing any logic I printed the data and grouped the computers by eye. They form clusters (Stockholm, Gothenburg, Malmö) where the coordinates differ only in the third or fourth decimal, while the clusters are far apart. One computer did not belong to any cluster, so I knew the answer to look for before the code was done.

## The design

**A helper function** answers one question: are two positions at the same place?

```python
def ar_nara(position_a, position_b):
    lat_a, lon_a = position_a
    lat_b, lon_b = position_b
    return abs(lat_a - lat_b) < TROSKEL and abs(lon_a - lon_b) < TROSKEL
```

**The main function** compares every computer with every *other* computer (two nested loops) and collects the ones with no neighbour.
- Exactly one lonely computer: return its name.
- None, or more than one: `raise ValueError(...)` with a message saying how many were found. The function must not guess, and returning `""` or `None` would hide the problem.

## Result
The stolen computer is **`makar`**, at latitude 59.8586, longitude 17.6391, which is **Uppsala**. All the other computers are in Stockholm, Gothenburg or Malmö.

## Choosing the threshold
The threshold is a named constant, `TROSKEL = 0.01`, defined in one place with a comment explaining it. One degree is about 111 km.

| | Difference | About |
|---|---|---|
| Within a cluster (same office) | at most ≈ 0.001° | 100 m |
| Between clusters (different cities) | at least ≈ 0.5° | 55 km |
| **My threshold** | **0.01°** | **1.1 km** |

0.01 is ten times larger than the variation within an office and fifty times smaller than the distance between cities, so there is a wide margin on both sides. It also matches what "stolen" means: the computer has been moved away from the office, not just to another desk.

To see why the value matters, I ran the program with other thresholds:

| Threshold | Result | Why |
|---|---|---|
| 0.0001 (≈ 11 m) | `ValueError`: 15 lonely computers | Smaller than the small variations within an office, so almost nothing counts as near |
| 0.01 (≈ 1.1 km) | `makar` | |
| 1 (≈ 111 km) | `ValueError`: no lonely computer | So large that cities count as near. Uppsala is only ≈ 0.5° from Stockholm |

The threshold has to be larger than the variation within one place but smaller than the distance between places.

## What I learned

### `abs()` makes the order irrelevant
My first version was `lat_a - lat_b < TROSKEL`. That gives the right answer for `ar_nara(zelda, link)` (1.62 is not less than 0.01) but the **wrong** answer for `ar_nara(link, zelda)`, because -1.62 *is* less than 0.01. A negative difference is always "small". `abs()` fixed it, and I wrote a test that calls the function in both orders.

### Both coordinates must be close
Two computers on the same latitude can be hundreds of kilometres apart. The helper needs `and` between the latitude and longitude checks, and I tested a position with exactly the same latitude but a different longitude.

### Skip yourself
A computer is always near itself. Without `if dator == annan_dator: continue` in the inner loop, every computer has a "neighbour" and none is ever lonely.

### Floats are not exact
```python
>>> abs(59.3291 - 59.329)
9.999999999621423e-05
```
The difference *should* be exactly 0.0001, but it is stored as slightly less. With the threshold set to 0.0001, this rounding error decided that four computers counted as near each other. That is why my boundary test does **not** test exactly at the threshold, but at 90 % and 110 % of it, and calculates those values from the constant so the test still works if the threshold changes.

### Testing errors
`pytest.raises(ValueError)` passes only if that exact exception is raised. The provided test accepted any exception for the "no lonely computer" case, so my own test covered the other case (two lonely computers) and required `ValueError` specifically.

### Constants and naming
Constants are written in uppercase (`TROSKEL`), which tells the reader the value should not change while the program runs. Renaming a variable with F2 in VS Code changes every occurrence, which is handy but also changed variables in the provided tests that I had not meant to touch.
