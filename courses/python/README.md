# Python: automating log and text analysis

A four-week Python course focused on the kind of scripting an IT security specialist does every day: reading files, filtering logs, parsing structured data and making sure the code actually does what you think it does.

The course was examined with a written exam and an individual assignment, **RANSOM!**: one connected story about a ransomware attack against the fictional company *Anaconda Industries*, told through a series of tasks.
I worked in VS Code on Windows, with one `uv` project per task and `pytest` for testing.

## Results

| Task | What I had to do | Answer | Tests |
|---|---|---|---|
| [1. The ransom note](task-1-atbash-cipher.md) | Identify the cipher and decrypt the attackers' message | Atbash. The note demands 75 bitcoin before Monday 09:00, or the customer data is sold online | 4 test functions (6 asserts), all passing |
| [2. The access log](task-2-access-log.md) | Read the server room's badge log and list everyone who left on the 14th between 13:00 and 18:59 | 4 suspects: `id001`, `id009`, `id007`, `id015` | 4 test functions, all passing |
| [3. The GPS trackers](task-3-gps-tracking.md) | Read the trackers' positions from JSON and find the one computer that is not near any other | `makar`, at 59.8586, 17.6391 (Uppsala) | 5 test functions, all passing |

> I have left the complete solutions out on purpose, since the assignment is reused in later years. The pages show the key ideas and the parts I learned the most from.

## Contents

| Page | What it covers |
|---|---|
| [task-1-atbash-cipher.md](task-1-atbash-cipher.md) | Strings, `string.ascii_lowercase`, slicing with `[::-1]`, `.index()`, building a result in a loop, `if`/`elif` and indentation |
| [task-2-access-log.md](task-2-access-log.md) | Reading files with `with`, `readlines()`, `split()`, `int()`, filtering with `and`, removing duplicates, testing boundaries with `tmp_path` |
| [task-3-gps-tracking.md](task-3-gps-tracking.md) | `json.load`, dictionaries and `.items()`, nested loops, a helper function, comparing floats with `abs()`, a named threshold, `raise ValueError`, `pytest.raises` |
| [lessons-learned.md](lessons-learned.md) | The tooling (`uv`, `pytest`, the terminal), how to write tests that catch real mistakes, documentation, and what I would do differently |

## Skills I practiced
**Python:** strings and slicing, `for` loops, `if`/`elif`, lists, dictionaries, unpacking, file handling with `with`, `json`, `abs()`, f-strings, raising exceptions, helper functions, constants, `if __name__ == "__main__":`

**Testing:** `pytest`, `assert`, separate test functions, `tmp_path`, `pytest.raises`, boundary tests, reading a test report

**Tooling:** `uv` (`uv sync`, `uv run`), `pyproject.toml`, virtual environments, VS Code, PowerShell

**Documentation:** docstrings (Args, Returns, Raises), comments that explain *why*, README files with answer, how to run and assumptions

## Related work
- [Operating Systems: Windows and Linux](../operating-systems-windows-linux/): the terminal and PowerShell skills I relied on here.
- [Nordkap Konsult AB](../../projects/nordkap-it-environment/): my first scripts (Bash and PowerShell), including log monitoring.
