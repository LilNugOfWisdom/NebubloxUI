import re
import sys

def check_lua_advanced(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    orig_lines = content.split('\n')

    # 1. STRIPPING: Order is critical here to prevent false positives.
    # Strip block comments first: --[[ ... ]]
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    # Strip multi-line strings: [[ ... ]]
    content = re.sub(r'\[\[.*?\]\]', '""', content, flags=re.DOTALL)
    # Strip double-quote strings (handling escaped quotes)
    content = re.sub(r'"(?:\\.|[^"\\])*"', '""', content)
    # Strip single-quote strings (handling escaped quotes)
    content = re.sub(r"'(?:\\.|[^'\\])*'", "''", content)
    # Strip single-line comments LAST so they don't break strings
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)

    lines = content.split('\n')
    stack = []
    
    # In Lua, 'while' and 'for' take a 'do'. 
    # The 'do' takes the 'end', so we don't actually need to track 'while' or 'for'.
    for i, line in enumerate(lines, 1):
        # Find exact word boundaries for block keywords
        tokens = re.findall(r'\b(function|if|do|repeat|end|until)\b', line)
        
        for t in tokens:
            if t in ['function', 'if', 'do', 'repeat']:
                stack.append((t, i, orig_lines[i-1]))
            
            elif t == 'end':
                if not stack:
                    print(f"❌ EXTRA 'end' at line {i}: {orig_lines[i-1].strip()}")
                    return
                last_t, last_ln, last_txt = stack.pop()
                if last_t == 'repeat':
                    print(f"❌ MISMATCH: 'end' at line {i} tried to close 'repeat' from line {last_ln}")
                    return

            elif t == 'until':
                if not stack:
                    print(f"❌ EXTRA 'until' at line {i}: {orig_lines[i-1].strip()}")
                    return
                last_t, last_ln, last_txt = stack.pop()
                if last_t != 'repeat':
                    print(f"❌ MISMATCH: 'until' at line {i} tried to close '{last_t}' from line {last_ln}")
                    return
    
    if stack:
        print("⚠️ UNCLOSED BLOCKS:")
        for t, ln, txt in stack:
            print(f"  -> '{t}' at line {ln}: {txt.strip()}")
    else:
        print("✅ SYNTAX OK! All Lua blocks are perfectly balanced.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python lua_linter.py <your_script.lua>")
    else:
        check_lua_advanced(sys.argv[1])