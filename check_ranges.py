import re
import sys

def check_lua_ranges(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Strip strings and comments
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"', '""', content)
    content = re.sub(r'\'[^\'\\\\]*(?:\\\\.[^\'\\\\]*)*\'', "''", content)
    content = re.sub(r'\[\[.*?\]\]', '""', content, flags=re.DOTALL)

    lines = content.split('\n')
    stack = []
    
    starters = ['function', 'if', 'for', 'while', 'repeat', 'do']

    for i, line in enumerate(lines, 1):
        # findall whole words
        tokens = re.findall(r'\b(function|if|for|while|repeat|do|end|until)\b', line)
        for t in tokens:
            if t in ['function', 'if', 'for', 'while', 'repeat']:
                stack.append((t, i))
            elif t == 'do':
                if not stack or stack[-1][0] not in ['for', 'while']:
                    stack.append(('do', i))
            elif t == 'end':
                if not stack:
                    print(f"EXTRA 'end' at line {i}")
                else:
                    stack.pop()
            elif t == 'until':
                if not stack:
                    print(f"EXTRA 'until' at line {i}")
                else:
                    last_t, last_ln = stack.pop()
                    if last_t != 'repeat':
                        print(f"MISMATCH: 'until' at line {i} vs '{last_t}' from line {last_ln}")
        
        if i % 200 == 0:
            print(f"Line {i}: Stack size {len(stack)}")
            if stack:
                print(f"  Last starter: {stack[-1]}")

    if stack:
        print("UNCLOSED BLOCKS AT END:")
        for t, ln in stack:
            print(f"  {t} started at line {ln}")
    else:
        print("SYNTAX OK")

if __name__ == "__main__":
    check_lua_ranges(sys.argv[1])
