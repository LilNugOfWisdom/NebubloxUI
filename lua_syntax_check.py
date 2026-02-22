import re
import sys

filepath = r"C:\Users\James\.gemini\antigravity\scratch\NebubloxUI\NebubloxUI.lua"

with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

print(f"File has {len(lines)} lines")

# Track block openers/closers
stack = []
openers = {"function", "if", "do", "repeat"}
closers_end = {"end"}
closers_until = {"until"}

for i, raw_line in enumerate(lines):
    lineno = i + 1
    # Strip comments (-- to end of line, but not inside strings)
    # Simple approach: strip from first -- that's not inside a string
    line = raw_line
    # Remove string literals to avoid false matches
    line = re.sub(r'"[^"]*"', '""', line)
    line = re.sub(r"'[^']*'", "''", line)
    # Remove single-line comments
    line = re.sub(r'--.*$', '', line)
    
    # Find keywords
    tokens = re.findall(r'\b(function|if|then|do|repeat|end|until|elseif|else|for|while|return|local)\b', line)
    
    for tok in tokens:
        if tok == "function":
            stack.append((lineno, "function"))
        elif tok == "if":
            # Only count 'if' that has a 'then' (not single-line if-then-end patterns)
            # Actually we should count all ifs
            stack.append((lineno, "if"))
        elif tok == "do":
            stack.append((lineno, "do"))
        elif tok == "repeat":
            stack.append((lineno, "repeat"))
        elif tok == "end":
            if stack:
                opened = stack[-1]
                if opened[1] in ("function", "if", "do"):
                    stack.pop()
                else:
                    print(f"  WARNING line {lineno}: 'end' closing '{opened[1]}' from line {opened[0]}")
                    stack.pop()
            else:
                print(f"  ERROR line {lineno}: unexpected 'end' with empty stack")
        elif tok == "until":
            if stack and stack[-1][1] == "repeat":
                stack.pop()
            else:
                print(f"  ERROR line {lineno}: unexpected 'until'")

if stack:
    print(f"\nERROR: {len(stack)} unclosed blocks:")
    for ln, kw in stack:
        print(f"  Line {ln}: '{kw}' never closed")
else:
    print("Block matching: ALL OK")

# Check parentheses balance
paren_stack = []
for i, raw_line in enumerate(lines):
    lineno = i + 1
    line = raw_line
    line = re.sub(r'"[^"]*"', '""', line)
    line = re.sub(r"'[^']*'", "''", line)
    line = re.sub(r'--.*$', '', line)
    
    for ch in line:
        if ch == '(':
            paren_stack.append(lineno)
        elif ch == ')':
            if paren_stack:
                paren_stack.pop()
            else:
                print(f"  ERROR line {lineno}: unmatched ')'")

if paren_stack:
    print(f"\nERROR: {len(paren_stack)} unclosed parentheses:")
    for ln in paren_stack[-10:]:
        print(f"  Opened on line {ln}")
else:
    print("Parentheses: ALL OK")

# Check curly braces balance  
brace_stack = []
for i, raw_line in enumerate(lines):
    lineno = i + 1
    line = raw_line
    line = re.sub(r'"[^"]*"', '""', line)
    line = re.sub(r"'[^']*'", "''", line)
    line = re.sub(r'--.*$', '', line)
    
    for ch in line:
        if ch == '{':
            brace_stack.append(lineno)
        elif ch == '}':
            if brace_stack:
                brace_stack.pop()
            else:
                print(f"  ERROR line {lineno}: unmatched '}}'")

if brace_stack:
    print(f"\nERROR: {len(brace_stack)} unclosed braces:")
    for ln in brace_stack[-10:]:
        print(f"  Opened on line {ln}")
else:
    print("Braces: ALL OK")

# Check for common Lua syntax issues
for i, raw_line in enumerate(lines):
    lineno = i + 1
    line = raw_line.rstrip()
    # Check for lines with 'then' missing after 'if'
    stripped = re.sub(r'"[^"]*"', '""', line)
    stripped = re.sub(r"'[^']*'", "''", stripped)
    stripped = re.sub(r'--.*$', '', stripped)
    
    # Check for == vs = issues in if statements
    if re.search(r'\bif\b', stripped) and not re.search(r'\bthen\b', stripped):
        # Multi-line if is ok, but flag it
        pass

print("\nDone.")
