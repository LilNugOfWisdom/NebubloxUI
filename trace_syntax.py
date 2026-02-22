import re
import sys

def analyze(filename):
    with open(filename, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    stack = []
    for i, line in enumerate(lines, 1):
        # Strip comments
        clean = re.sub(r'--.*$', '', line)
        # Strip strings
        clean = re.sub(r'\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"', '""', clean)
        clean = re.sub(r'\'[^\'\\\\]*(?:\\\\.[^\'\\\\]*)*\'', "''", clean)
        
        # Tokenize
        tokens = re.findall(r'\b(function|if|for|while|repeat|do|then|end|until|else|elseif)\b', clean)
        
        for t in tokens:
            if t in ['function', 'if', 'for', 'while', 'repeat']:
                stack.append((t, i))
            elif t == 'do':
                if not stack or stack[-1][0] not in ['for', 'while']:
                    stack.append(('do', i))
            elif t == 'then':
                if not stack or stack[-1][0] != 'if':
                     # Standalone then is not a thing in Lua but we can note it
                     pass
            elif t == 'end':
                if not stack:
                    print(f"Error: Extra 'end' at line {i}")
                else:
                    stack.pop()
            elif t == 'until':
                if not stack:
                    print(f"Error: Extra 'until' at line {i}")
                else:
                    last_t, last_i = stack.pop()
                    if last_t != 'repeat':
                        print(f"Error: 'until' at line {i} mismatches '{last_t}' at line {last_i}")

    if stack:
        print("Unclosed blocks:")
        for t, i in stack:
            print(f"  {t} started at line {i}: {lines[i-1].strip()}")
    else:
        print("Success: All blocks closed!")

if __name__ == "__main__":
    analyze(sys.argv[1])
