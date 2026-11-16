# Lessons learned

## Tooling

### `uv` and virtual environments
- Each task is its own project with a `pyproject.toml`. It names the project and lists its dependencies (here `pytest`). `uv sync` or `uv run` reads that list and installs everything into the project's own `.venv`, so the only thing I have to install myself is `uv`.
- `uv run pytest solution.py` and `uv run python solution.py` always use the project's `.venv`, so there is no need to activate anything.
- The warning `VIRTUAL_ENV=... does not match the project environment path` meant an old environment from an earlier course was still active. It is harmless (`uv` ignores it), and `deactivate` removes it. Adding `--active`, as the warning suggests, would have run the tests in the wrong environment.
- **A virtual environment cannot be moved.** After copying my folders to a new location, `uv` failed with *"trampoline failed to canonicalize script path"*, because the `.venv` contains absolute paths to where it was created. The fix was to delete `.venv` and let `uv run` create a new one.

### The terminal
- The path in the prompt (`PS C:\Kod\...\uppgift-1>`) is where I am. Most "file not found" errors were simply the wrong folder. `cd`, `ls` and Tab completion fixed them.
- Opening the task folder itself in VS Code (*File > Open Folder*) makes every new terminal start in the right place.
- `Ctrl+C` in the terminal interrupts the running program (`KeyboardInterrupt`) unless text is selected.

### Reading a test report
- Ignore the long traceback through pytest's own files and look at the bottom: the file, the line number and the error type.
- `assert '' == 'zyyz'`: the left side is what my function returned, the right side is what the test expected.
- `-v` shows each test by name, `-s` shows `print` output, `-vv` shows the full diff when lists differ.
- Pytest stops at the first failing `assert` inside a test function, so each case I care about gets **its own** `test_` function.
- Error types quickly told me where to look: `NameError` (misspelled or missing name, or a missing import), `SyntaxError` (unmatched parenthesis, `elif` in the wrong place), `IndentationError`, `TypeError: takes 0 positional arguments but 1 was given` (the function was missing a parameter).

## Writing tests that catch real mistakes
- **A good test is one a wrong solution would fail.** `"18" -> "81"` passes for a plain string reversal too; `"123" -> "876"` does not.
- **Vary one thing per test.** If time, day and direction all change in the same test, a failure doesn't tell you which condition is broken.
- **Test the edges.** Include the first and last values that should count (13 and 18) and the nearest ones that shouldn't (12 and 19).
- **Don't test floats exactly at a boundary.** Test clearly inside and clearly outside.
- **Test the error cases too**, with the specific exception type.
- Green tests are not proof. The task 3 instructions said the provided tests were "deliberately vague", and they passed before my solution handled the order of arguments correctly.

## Documentation
The documentation counted towards the grade, and writing it made me understand my own code better.
- **Docstrings** go directly under the `def` line. A docstring above the function is just a loose string. Each one says what the function does, its parameters (Args), what it returns (Returns), what it raises and when (Raises), and its assumptions.
- **Comments explain why, not what.** `# adds the character to result` repeats the code. `# A computer is always near itself, so skip it` explains a decision a reader would wonder about.
- **No dead code.** Lines after a `raise` or `return` can never run, and leftover template comments and debug `print`s should go before handing in.
- **Each task has a README** with the answer, how to run it, and the assumptions I made (for example that the log file is UTF-8, that hours are whole hours, and that each ID is listed once).
- `if __name__ == "__main__":` lets the file print its answer when run directly, without the output appearing when pytest imports it. A function should **return** its result, not print it.

## Handing in
- The zip should contain only my work: `solution.py`, `README.md`, `pyproject.toml`, `uv.lock` and the data file for each task.
- `.venv`, `__pycache__` and `.pytest_cache` are recreated every time the tests run, so they have to be removed again right before zipping. My first zip was 33 MB because of them. The final one was 120 KB.

## How I work
- **Understand the pattern before coding.** In task 1, working out the cipher on paper made the code short. In task 3, grouping the coordinates by eye told me the answer before the code did, which made it easy to check the result.
- **Try small pieces first.** `uv run python` let me test `.index()`, slicing and my helper function one line at a time.
- **Read the error message.** It almost always says exactly what is wrong and on which line.
- **Save before running.** Several errors disappeared with `Ctrl+S`.
- **Write the documentation while the reasoning is fresh**, not at the end.

## What I would do differently
- Start earlier, to leave more time for extra tests and polishing the documentation.
- Try writing the tests first next time. Deciding what "correct" means before writing the code would have caught some of my mistakes earlier, like the missing `abs()` in task 3.
- Turn on Auto Save in VS Code from the start.
- Keep the repository and the virtual environments separate from the folder I zip, so that cleaning up before hand-in isn't needed.

## Why this matters for IT security
- Task 2 is log analysis in miniature: filter events by time window, type and identity, and remove duplicates. The same thinking applies to firewall logs, Windows event logs and SIEM queries.
- Task 1 is a reminder that encoding is not encryption. A cipher without a key protects nothing.
- Task 3 is anomaly detection: define what "normal" looks like (devices cluster at offices), pick a threshold you can justify, and refuse to give an answer when the data is ambiguous instead of guessing.
