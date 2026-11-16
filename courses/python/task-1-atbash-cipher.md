# Task 1: Decrypting the ransom note

> The attackers left an encrypted message on the company website. Only lowercase letters and digits are encrypted; uppercase letters and other characters are unchanged.

## Finding the cipher
Before writing any code, I looked for the pattern in the example tests:

```
abba  ->  zyyz
24    ->  75
90:99 ->  09:00
```

`a` becomes `z`, `b` becomes `y`: the alphabet is reversed. The digits follow the same rule, `0` becomes `9`, `1` becomes `8`. This is the **Atbash cipher**, one of the oldest known substitution ciphers. Two things make it a poor cipher:

- There is **no key**. Anyone who knows the method can read the message.
- It is **symmetric**: running the same function twice gives back the original text, so encrypting and decrypting are the same operation.

## The idea in code
A letter and its replacement stand at the **same position** in the normal and the reversed alphabet:

```
alphabet:  a b c d e ...
reversed:  z y x w v ...
position:  0 1 2 3 4 ...
```

So the whole solution is: find the character's position in one string, and take the character at the same position in the other.

```python
alfabet = string.ascii_lowercase
omvant = alfabet[::-1]           # "zyxw...cba"

position = alfabet.index("c")    # 2
omvant[position]                 # "x"
```

Everything else (uppercase letters, å/ä/ö, spaces, punctuation) is not in `ascii_lowercase` or `string.digits`, so it falls through both checks and is added unchanged.

## Result
> Era servrar är låsta och backuperna är raderade. Skicka 75 bitcoin före måndag kl 09:00, annars säljer vi kunduppgifterna på nätet!

*(Your servers are locked and the backups are deleted. Send 75 bitcoin before Monday 09:00, or we sell the customer data online.)*

## What I learned

### Terminal vs Python
My first `import string` failed with *"The term 'import' is not recognized"*, because I typed it into PowerShell. Python code goes in the `.py` file, or in Python's interactive mode (`uv run python`, prompt `>>>`), which is great for trying one line at a time before putting it into the solution.

### Building a result in a loop
Start with an empty string, add one character per iteration, and return **after** the loop. I first wanted to write `return "z"` inside an `if`, but `return` exits the whole function immediately, so only the first character would ever be handled.

### Indentation is syntax
Most of my errors in this task were indentation:
- `elif` must stand in **exactly** the same column as its `if`, with nothing in between. Otherwise Python raises `SyntaxError: invalid syntax`.
- The line that adds the character to the result must be *outside* the `if`/`elif` blocks. When it ended up inside, the function only returned the last character (`'abba'` gave `'z'`), which the test report showed clearly.

### A test can be correct and still useless
I first wrote `assert solution("18") == "81"`. It passes, but `"18"` reversed as a string is also `"81"`, so a wrong solution that just does `note[::-1]` would pass too. I changed it to `"123" -> "876"`, which only the correct solution passes. That changed how I think about tests: **a good test is one that a wrong solution would fail.**

### Small things that cost time
- Pytest tests the **saved** file. Several "mysterious" errors were just unsaved changes.
- `__name__` and `"__main__"` have **two** underscores on each side.
- `string.digits`, not `ascii_number`. `dir(string)` lists what a module contains, so there is no need to guess.
