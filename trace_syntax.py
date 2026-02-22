import re
import sys

def analyze(filename):
    try:
        with open(filename, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"Error: {e}")
        return
        
    # Save original lines for accurate error reporting later
    orig_lines = content.split('\n')
        
    # 1. Strip multi-line comments and strings FIRST (requires full text)
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    content = re.sub(r'\[\[.*?\]\]', '""', content, flags=re.DOTALL)
    
    # 2. Strip single-line strings SECOND (handles escaped quotes)
    content = re.sub(r'"(?:\\.|[^"\\])*"', '""', content)
    content = re.sub(r"'(?:\\.|[^'\\])*'", "''", content)
    
    # 3. Strip single-line comments LAST
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)

    # Now split the sanitized content into lines
    lines = content.split('\n')
    
    stack = []
    for i, line in enumerate(lines, 1):
        # Tokenize (ignoring then/else/elseif since they don't push/pop the stack)
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
                    print(f"Error: Extra 'end' at line {i}: {orig_lines[i-1].strip()}")
                else:
                    stack.pop()
            elif t == 'until':
                if not stack:
                    print(f"Error: Extra 'until' at line {i}: {orig_lines[i-1].strip()}")
                else:
                    last_t, last_i = stack.pop()
                    if last_t != 'repeat':
                        print(f"Error: 'until' at line {i} mismatches '{last_t}' at line {last_i}")

    if stack:
        print("Unclosed blocks:")
        for t, i in stack:
            print(f"  {t} started at line {i}: {orig_lines[i-1].strip()}")
    else:
        print("Success: All blocks closed!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python analyze.py <script.lua>")
    else:
        analyze(sys.argv[1])