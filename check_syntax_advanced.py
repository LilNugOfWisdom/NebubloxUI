import re
import sys

def check_lua_advanced(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    orig_lines = content.split('\n')

    # Stripping comments and strings to avoid false positives
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"', '""', content)
    content = re.sub(r'\'[^\'\\\\]*(?:\\\\.[^\'\\\\]*)*\'', "''", content)
    content = re.sub(r'\[\[.*?\]\]', '""', content, flags=re.DOTALL)

    lines = content.split('\n')
    stack = []
    
    starters = ['function', 'if', 'for', 'while', 'repeat', 'do']

    for i, line in enumerate(lines, 1):
        tokens = re.findall(r'\b(function|if|for|while|repeat|do|end|until)\b', line)
        for t in tokens:
            if t in ['function', 'if', 'for', 'while', 'repeat']:
                stack.append((t, i, orig_lines[i-1]))
            elif t == 'do':
                if not stack or stack[-1][0] not in ['for', 'while']:
                    stack.append(('do', i, orig_lines[i-1]))
            elif t == 'end':
                if not stack:
                    print(f"EXTRA 'end' at line {i}: {orig_lines[i-1].strip()}")
                    continue
                stack.pop()
            elif t == 'until':
                if not stack:
                    print(f"EXTRA 'until' at line {i}: {orig_lines[i-1].strip()}")
                    continue
                last_t, last_ln, last_txt = stack.pop()
                if last_t != 'repeat':
                    print(f"MISMATCH: 'until' at line {i} vs '{last_t}' from line {last_ln}")
    
    if stack:
        print("UNCLOSED BLOCKS:")
        for t, ln, txt in stack:
            print(f"  {t} at line {ln}: {txt.strip()}")
    else:
        print("SYNTAX OK")

if __name__ == "__main__":
    check_lua_advanced(sys.argv[1])
