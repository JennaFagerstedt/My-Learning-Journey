# PowerShell: the three questions

> Intro exercise in PowerShell on Windows (run in my own Windows terminal, user `lizzn`).
> The goal was not to memorize commands but to learn how to **ask the system** myself.

PowerShell has thousands of commands, and more appear with every role or module you install. Nobody knows them all by heart. What you need instead are three commands, each answering one question:

| Question | Command |
|---|---|
| What commands exist? | `Get-Command` |
| How does this command work? | `Get-Help` |
| What do I get back, and what can I do with it? | `Get-Member` |

The numbers (how many commands there are) differ between machines, depending on what is installed. **The command is the answer, not the number.**

## The most important idea: Verb-Noun
Every PowerShell command is named **Verb-Noun**, for example `Get-Process`, `Stop-Service`, `Read-Host`.

- **Verb** = what the command *does* (Get, Stop, Start, Read ...)
- **Noun** = what it does it *to* (Process, Service, Content ...)

Because of this, command names can be searched in two dimensions at once. That idea came back in almost every question, and mixing up the two was my most common mistake.

## Part 1: What exists? (`Get-Command`)

### 1. How many commands are there in total?
```powershell
(Get-Command).Count
```
**My first attempt:** `Get-Command -Count`. That fails, because `Get-Command` has no parameter called `-Count`.

**What I learned:**
- A **dash** (`-Name`) means *a parameter* of the command.
- A **dot** (`.Count`) means *a property* of the object you got back.
- `Get-Command` returns a list, and the list has a `Count` property. The **parentheses** make PowerShell run the command first and treat the whole result as one thing, so `.Count` has something to count. Same idea as parentheses in maths: "work this out first".

### 2. Which commands do something with processes?
```powershell
Get-Command -Noun Process
```
Returns a handful: `Debug-Process`, `Get-Process`, `Start-Process`, `Stop-Process`, `Wait-Process`.
Searching on the **noun** is more precise than `Get-Command *process*`, which also drags in anything that happens to contain the word.

### 3. How many commands use the verb Get?
```powershell
(Get-Command -Verb Get).Count
```
Same counting trick as question 1, with a filter added.

### 4. Approved verbs, and Get vs Read
```powershell
Get-Verb
Get-Verb | Where-Object Verb -in 'Get','Read'
```
**My first attempt:** `Get-Verb | Where-Object -in 'Get','Read'`. That was missing the word `Verb`. `Where-Object` must be told **which property (column)** to compare. Each row has several (`Verb`, `Group`, `Description`), so without it PowerShell does not know what to check.

**Get vs Read:**
- **Get** retrieves a resource that already exists as an object in the system (`Get-Process`, the processes are already there).
- **Read** takes in data from a source outside, such as a file, a stream or a user typing (`Read-Host` waits for input).

`-in` means "is one of these".

### 5. How many commands come from the module Microsoft.PowerShell.Utility?
```powershell
(Get-Command -Module Microsoft.PowerShell.Utility).Count
```
Pattern: **`(command with filter).Count`**, the same as in questions 1 and 3.
`-Module` is useful after installing a new role, to see what it actually gave you (e.g. `Get-Command -Module ActiveDirectory`).

### 6. Find every command to do with services
```powershell
Get-Command -Noun Serv*
```
**My attempts and what was wrong:**

| Attempt | Problem |
|---|---|
| `Get-Verb -Serv*` | Wrong command (`Get-Verb` only lists verbs), and `-Serv*` was read as a *parameter name* because of the dash. Error: `A parameter cannot be found that matches parameter name 'Serv*'` |
| `Get-Command -Verb Serv*` | Right command and right form, but wrong parameter. "Service" is the **noun** (after the dash in `Stop-Service`), not the verb |

The wildcard `*` matches both `Service` and `Services`.
**Rule:** `Command -Parameter Value`, with a space between the parameter and its value.

## Part 2: How does it work? (`Get-Help`)

| Form | Gives |
|---|---|
| `Get-Help <cmd>` | Summary and syntax |
| `Get-Help <cmd> -Examples` | Only the examples (start here) |
| `Get-Help <cmd> -Full` | Everything, every parameter explained |
| `Get-Help <cmd> -Parameter <name>` | One parameter in detail |
| `Get-Help <cmd> -Online` | The documentation page in the browser |
| `Get-Help about_*` | Concept topics, not commands |
| `Update-Help` | Downloads the help files (once, as administrator) |

### 7. What does Get-ChildItem do, and which parameters does it take?
```powershell
Get-Help Get-ChildItem
Get-Help Get-ChildItem -Full
```

### 8. Show only the examples for Get-Process
```powershell
Get-Help Get-Process -Examples
```
This was directly in the table. Lesson: in Part 2 and Part 3 the answer is almost always a row in the table above the questions. Find the row that matches the question, then swap in the command name.

### 9. Does Stop-Process accept pipeline input, and on which parameter?
```powershell
Get-Help Stop-Process -Parameter Name
Get-Help Stop-Process -Parameter InputObject
```
Look for the line **`Accept pipeline input?`**. The answer is **yes, on both `-Name` and `-InputObject`**.

**What the pipe needs:** `Get-Process notepad | Stop-Process` only works if the command on the right *can receive* what comes from the left. That line in the help tells you, so you don't have to guess.

| Kind | Parameter | Meaning |
|---|---|---|
| **ByValue** | `-InputObject` | The whole object is passed in as it is ("here, stop this one") |
| **ByPropertyName** | `-Name` | PowerShell looks for a property called `Name` on the object and uses its value ("it is called notepad, so stop notepad") |

### 10. Is there a help topic about operators?
```powershell
Get-Help about_operator*
```
I worked this one out myself. Concept topics are not commands; they all start with the prefix **`about_`**, so a wildcard finds them without knowing the exact name. The topic is `about_Operators`.

- `Get-Help about_*` lists every concept topic (pipeline, variables, if statements ...).
- If you only get "partial help", the help files are not downloaded. Run `Update-Help` once in an administrator PowerShell.

## Part 3: What do I get back? (`Get-Member`)

Commands in PowerShell return **objects**, not plain text. `Get-Member` is the magnifying glass that shows what kind of object it is and what is inside.

| Member type | What it is | Car analogy |
|---|---|---|
| **Property** | What the object *contains / knows about itself* | colour, brand, fuel level |
| **Method** | What the object *can do* | drive, brake, honk |

### 11. Which object type does Get-Service return?
```powershell
Get-Service | Get-Member
Get-Service | Get-Member | Select-Object -First 1 -ExpandProperty TypeName
```
**Answer:** `System.ServiceProcess.ServiceController`

**My first attempt:** `TypeName Get-Service | Get-Member`. `TypeName` is not something you type. It is a heading PowerShell *shows* at the top of the `Get-Member` output. Read what comes after `TypeName:`.

The longer command does the same thing in steps: `Select-Object -First 1` takes only the first row (they all have the same type), and `-ExpandProperty TypeName` shows only that value.

### 12. Which properties does that object have?
```powershell
Get-Service | Get-Member -MemberType Property
```
I got this right myself. The output includes `CanStop`, `DisplayName`, `MachineName`, `ServiceName`, `ServiceType`, `StartType`, `Status` and more.

**Why it matters:** properties are exactly what `Where-Object` can filter on and `Select-Object` can pick out. Seeing `Status` in the list means `Where-Object Status -eq 'Running'` will work, without guessing.

**Detail I noticed:** `Name` is *not* in the list, even though `Get-Service` shows a Name column. `Name` is an **alias** for `ServiceName`, so its MemberType is `AliasProperty`, and the `Property` filter leaves it out. Running `Get-Member` without a filter shows it.

### 13. Which methods does it have?
```powershell
Get-Service | Get-Member -MemberType Method
```
Only one word changes from question 12. Methods include `Start()`, `Stop()`, `Refresh()`, called with a dot and parentheses.

Note: `(Get-Service spooler).Stop()` works, but `Stop-Service spooler` is the right way. The cmdlet has error handling, `-WhatIf` and works against remote computers.

### 14. What do ls, cat and dir really run?
```powershell
Get-Alias ls, cat, dir
```
| Alias | Real cmdlet |
|---|---|
| `ls` | `Get-ChildItem` |
| `cat` | `Get-Content` |
| `dir` | `Get-ChildItem` |

An alias is a **nickname** for a command. Three names, two commands. Fine to type interactively, but never use aliases in scripts. They make scripts harder to read and can differ between machines.
The other direction: `Get-Alias -Definition Get-ChildItem` shows every alias for a command.

## Challenges

### 15. Commands that start with Get *and* have to do with services
```powershell
Get-Command -Verb Get -Noun *Service*
```
**My attempts:**
- `Get-Command | Get-Member about_serv*`
- `Get-Command -Verb Get | Get -<parameter> about_serv*`

The first half of the second attempt (`Get-Command -Verb Get`) was right. What went wrong:
- **No pipe needed.** Both filters go in the *same* command, one after the other.
- **`Get-Member` does not belong here.** It describes objects; it does not search for commands.
- **`about_` only belongs with `Get-Help`** (question 10), never with `Get-Command`.
- `<parameter>` was a blank I was meant to fill in, not something to type.

| Part | Means |
|---|---|
| `Get-Command` | Search among commands |
| `-Verb Get` | ...where the verb is Get |
| `-Noun *Service*` | ...and the noun contains "Service" |

### 16. Measure filtered vs unfiltered Get-Command
```powershell
Measure-Command { Get-Command }
Measure-Command { Get-Command -Noun Process }
```
`Measure-Command` is a stopwatch: put a command inside `{ }` and it reports how long it took (compare the `TotalMilliseconds` line).

**Expected result:** the filtered search is much faster.

**Why:** without a filter, `Get-Command` goes through every module on the machine and builds every command object. With `-Noun` the filtering happens *during* the search. Library analogy: carrying home every book and then looking for the one you want, versus asking the librarian for only the books on processes.

**Rule: filter in the command, not afterwards.** `Get-Command *hash*` is faster than `Get-Command | Where-Object Name -like '*hash*'`. Same principle as in bash: filter as early as possible in the chain.

## Mistakes I made, and the rule behind each
| Mistake | Rule |
|---|---|
| `Get-Command -Count` | Dash = parameter, dot = property. Use `(command).Count` |
| `Where-Object -in ...` without a property | Tell `Where-Object` which property to compare |
| `Get-Verb -Serv*` | Use the right command, and the value comes *after* a parameter name |
| `-Verb Serv*` | Verb = what it does, Noun = what it does it to |
| Typing `TypeName` as a command | `TypeName` is a heading in the output, not something to type |
| Using `Get-Member` / `about_` to search commands | `Get-Command` searches, `Get-Help` explains, `Get-Member` describes objects |
| Using a pipe to combine two filters | Several parameters can go in the same command |

## Quick reference
```powershell
(Get-Command).Count                         # count everything
Get-Command -Noun Process                   # what it does it to
Get-Command -Verb Get                       # what it does
Get-Command -Verb Get -Noun *Service*       # both at once
Get-Command -Module <ModuleName>            # what a module gave me
Get-Verb                                    # approved verbs
Get-Help <cmd> -Examples                    # start here
Get-Help <cmd> -Parameter <name>            # one parameter, incl. pipeline input
Get-Help about_*                            # concept topics
<cmd> | Get-Member                          # type, properties, methods
<cmd> | Get-Member -MemberType Property     # only properties
Get-Alias ls, cat, dir                      # what an alias really runs
Measure-Command { <cmd> }                   # time a command
```
