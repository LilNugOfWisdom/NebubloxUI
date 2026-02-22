import re
import sys

def check_lua_ranges(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    # 1. STRIP MULTI-LINE COMMENTS FIRST
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    
    # 2. STRIP STRINGS SECOND (So comments inside strings are ignored)
    content = re.sub(r'\[\[.*?\]\]', '""', content, flags=re.DOTALL)
    content = re.sub(r'\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"', '""', content)
    content = re.sub(r'\'[^\'\\\\]*(?:\\\\.[^\'\\\\]*)*\'', "''", content)
    
    # 3. STRIP SINGLE LINE COMMENTS LAST
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)

    lines = content.split('\n')
    stack = []

    for i, line in enumerate(lines, 1):
        # findall whole words
        tokens = re.findall(r'\b(function|if|for|while|repeat|do|end|until)\b', line)
        for t in tokens:
            if t in ['function', 'if', 'for', 'while', 'repeat']:
                stack.append((t, i))
            elif t == 'do':
                # Ignore 'do' if it belongs to a for/while loop we already tracked
                if not stack or stack[-1][0] not in ['for', 'while']:
                    stack.append(('do', i))
            elif t == 'end':
                if not stack:
                    print(f"❌ EXTRA 'end' at line {i}")
                else:
                    last_t, last_ln = stack.pop()
                    if last_t == 'repeat':
                        print(f"❌ MISMATCH: 'end' at line {i} tried to close 'repeat' from line {last_ln}")
            elif t == 'until':
                if not stack:
                    print(f"❌ EXTRA 'until' at line {i}")
                else:
                    last_t, last_ln = stack.pop()
                    if last_t != 'repeat':
                        print(f"❌ MISMATCH: 'until' at line {i} vs '{last_t}' from line {last_ln}")
        
        # Your awesome checkpoint logger
        if i % 200 == 0:
            print(f"Line {i}: Stack size {len(stack)}")
            if stack:
                print(f"  Last starter: {stack[-1]}")

    if stack:
        print("\n⚠️ UNCLOSED BLOCKS AT END:")
        for t, ln in stack:
            print(f"  {t} started at line {ln}")
    else:
        print("\n✅ SYNTAX OK! No missing ends.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python check_lua_ranges.py <script.lua>")
    else:
        check_lua_ranges(sys.argv[1])