# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 3)

# Mastering `try`, `except`, `else`, and `finally`: Surviving Failure Correctly

> *"Most developers think `try/except` catches errors.*
>
> *Professional engineers know that `try/except/finally` is really about preserving system correctness during failure."*

---

# Introduction

Consider this code:

```python
file = open("data.txt")

data = file.read()

process(data)

file.close()
```

Looks fine.

Until:

```text
process()
```

throws an exception.

Now what happens?

```text
file.close()
```

never executes.

You just leaked a resource.

Now imagine the resource was:

* a database transaction,
* a network socket,
* a file lock,
* a payment authorization,
* a distributed lock,
* a GPU context.

This is why error handling exists.

Not because Python likes exceptions.

But because systems must remain correct when things fail.

---

# Chapter 21 — The Anatomy of `try`

The simplest form:

```python
try:
    dangerous()
except:
    recover()
```

Execution model:

```text
Enter try
     |
     V
Execute code
     |
     +--- Success ----> Continue
     |
     +--- Failure ----> Search handler
                           |
                           V
                      Execute except
```

---

# Example

```python
try:
    print("A")

    raise ValueError()

    print("B")

except:
    print("C")
```

Output:

```text
A
C
```

Why?

Because:

```text
raise
    |
    destroys current execution path
    |
    jumps to handler
```

---

# Exercise 1

Predict:

```python
try:
    print("one")

    raise Exception()

    print("two")

except:
    print("three")

print("four")
```

---

# Chapter 22 — Exception Matching

Consider:

```python
try:
    int("abc")

except ValueError:
    print("bad")
```

Python asks:

```text
Exception type?
       |
       V
ValueError?
       |
       YES
       |
       execute handler
```

---

# Example

```python
try:
    int("abc")

except TypeError:
    print("type")

except ValueError:
    print("value")
```

Output:

```text
value
```

---

# Exercise 2

Predict:

```python
try:
    {}["x"]

except KeyError:
    print("key")

except Exception:
    print("generic")
```

---

# Chapter 23 — Exception Inheritance Matters

Suppose:

```python
ZeroDivisionError
```

inherits from:

```text
ArithmeticError
        |
        Exception
```

Then:

```python
try:
    1/0

except ArithmeticError:
    print("caught")
```

works.

---

# Visualization

```text
BaseException
       |
       Exception
       |
 ArithmeticError
       |
ZeroDivisionError
```

---

# Rule

Python checks:

```text
isinstance(
    exception,
    handler_type
)
```

not:

```text
exact type equality
```

---

# Exercise 3

Will this work?

```python
try:
    1/0

except Exception:
    print("yes")
```

Why?

---

# Chapter 24 — Multiple Exceptions

Instead of:

```python
try:
    dangerous()

except ValueError:
    recover()

except TypeError:
    recover()
```

You can write:

```python
try:
    dangerous()

except (ValueError, TypeError):
    recover()
```

---

# Example

```python
try:
    int(None)

except (TypeError, ValueError):
    print("failed")
```

Output:

```text
failed
```

---

# Exercise 4

Handle:

```text
ValueError
TypeError
KeyError
```

using a single handler.

---

# Chapter 25 — Capturing Exceptions

Example:

```python
try:
    int("abc")

except ValueError as e:
    print(e)
```

Output:

```text
invalid literal for int()
```

---

# Why?

Because exceptions are objects.

```python
except Exception as e:
```

means:

```text
bind exception object to e
```

---

# Example

```python
try:
    1/0

except Exception as e:

    print(type(e))

    print(e)
```

Output:

```text
<class 'ZeroDivisionError'>
division by zero
```

---

# Exercise 5

Print:

* exception type
* exception message

for:

```python
int(None)
```

---

# Chapter 26 — The Dangerous Bare Except

This:

```python
try:
    dangerous()

except:
    pass
```

is one of the worst things you can write.

Why?

Because it catches:

```text
Exception
KeyboardInterrupt
SystemExit
GeneratorExit
```

---

# Example

```python
try:
    while True:
        pass

except:
    pass
```

Press:

```text
CTRL+C
```

Nothing happens.

You trapped:

```python
KeyboardInterrupt
```

---

# Professional Rule

Never write:

```python
except:
```

Write:

```python
except Exception:
```

or better:

```python
except SpecificError:
```

---

# Exercise 6

Find the bug:

```python
try:
    deploy()

except:
    print("deployment failed")
```

---

# Chapter 27 — The Else Clause

Most developers never use:

```python
else:
```

But it's incredibly useful.

---

Example:

```python
try:
    result = divide()

except ZeroDivisionError:
    recover()

else:
    print(result)
```

Meaning:

```text
if exception:
     except
else:
     execute
```

---

# Why?

Without:

```python
else
```

you often accidentally catch too much.

---

# Bad

```python
try:
    value = parse()

    save(value)

except ValueError:
    recover()
```

Question:

What if:

```python
save()
```

fails?

Oops.

---

# Better

```python
try:
    value = parse()

except ValueError:
    recover()

else:
    save(value)
```

---

# Exercise 7

Rewrite:

```python
try:
    parse()
    upload()

except ParseError:
    recover()
```

using:

```python
else
```

---

# Chapter 28 — Finally: The Most Important Keyword

Consider:

```python
file = open("data.txt")

process(file)

file.close()
```

What if:

```python
process()
```

fails?

---

Solution:

```python
file = open("data.txt")

try:

    process(file)

finally:

    file.close()
```

---

# Rule

`finally` means:

> Execute this no matter what.

---

# Visualization

```text
try
   |
   +--- success
   |        |
   |        V
   |    finally
   |
   +--- exception
            |
            V
        finally
```

---

# Exercise 8

Predict:

```python
try:
    print("A")
finally:
    print("B")
```

---

# Chapter 29 — Finally Runs During Exceptions

Example:

```python
try:

    print("A")

    raise ValueError()

finally:

    print("B")
```

Output:

```text
A
B
ValueError
```

---

Why?

Because Python does:

```text
exception
      |
execute finally
      |
continue unwinding
```

---

# Visualization

```text
raise
    |
finally
    |
resume exception
```

---

# Exercise 9

Predict:

```python
try:
    raise Exception()

finally:
    print("cleanup")
```

---

# Chapter 30 — Finally Runs During Return

Example:

```python
def test():

    try:
        return 1

    finally:
        print("cleanup")
```

Output:

```text
cleanup
```

Result:

```text
1
```

---

# Internal Execution

```text
return 1
      |
save return value
      |
execute finally
      |
return saved value
```

---

# Exercise 10

Predict:

```python
def f():

    try:
        return 10

    finally:
        print("X")

print(f())
```

---

# Chapter 31 — Finally Runs During Break

Example:

```python
while True:

    try:
        break

    finally:
        print("cleanup")
```

Output:

```text
cleanup
```

---

# Chapter 32 — Finally Runs During Continue

Example:

```python
for i in range(2):

    try:
        continue

    finally:
        print(i)
```

Output:

```text
0
1
```

---

# Chapter 33 — The Most Dangerous Thing You Can Do

This code:

```python
def dangerous():

    try:
        return 1

    finally:
        return 2
```

returns:

```text
2
```

---

Why?

Because:

```text
finally
```

overrides:

```text
return
exception
break
continue
```

---

Even worse:

```python
try:
    raise Exception()

finally:
    return
```

Output:

```text
No exception
```

You just destroyed the exception.

---

# Professional Rule

Never do:

```python
return
break
continue
raise
```

inside:

```python
finally
```

unless absolutely necessary.

---

# Exercise 11

Predict:

```python
def test():

    try:
        raise ValueError()

    finally:
        return "hello"

print(test())
```

---

# Chapter 34 — The Execution Order Cheat Sheet

```python
try:
    ...
except:
    ...
else:
    ...
finally:
    ...
```

Execution order:

---

## Success

```text
try
   |
else
   |
finally
```

---

## Exception Caught

```text
try
   |
except
   |
finally
```

---

## Exception Uncaught

```text
try
   |
finally
   |
propagate exception
```

---

# The Most Important Diagram In Error Recovery

```text
Execute
    |
    +--- Success
    |       |
    |       V
    |     Else
    |
    +--- Failure
            |
            V
         Except
            |
            V
         Finally
            |
            V
        Continue
```

---

# Summary

In this article we learned:

✅ `try` controls execution
✅ `except` catches failures
✅ exceptions match inheritance hierarchies
✅ `except as` captures exception objects
✅ `else` separates success paths
✅ `finally` guarantees cleanup
✅ `finally` executes during returns and exceptions
✅ `finally` can accidentally destroy exceptions

---

# Conclusion

Most developers think:

> `try/except` is for handling errors.

Professional engineers think:

> `finally` is for preserving system correctness.

Because the real question isn't:

> "Did an exception occur?"

The real question is:

> **"Regardless of what happened, what absolutely must still be true?"**

In **Part 4**, we'll learn how to throw exceptions professionally:

* `raise`
* re-raising
* exception chaining
* `raise from`
* custom exceptions
* domain exceptions
* exception contracts
* and how to design exception hierarchies like a systems architect.

Because throwing exceptions correctly is often harder than catching them. 🚨
