import sys

def check_brackets(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error opening file: {e}")
        return

    stack = []
    pairs = {'(': ')', '{': '}', '[': ']'}
    line = 1
    col = 0
    
    # Simple state machine to skip strings and comments
    in_string = None
    in_comment = False
    
    i = 0
    while i < len(content):
        char = content[i]
        
        if char == '\n':
            line += 1
            col = 0
        else:
            col += 1
            
        # Handle strings
        if not in_comment:
            if in_string:
                if char == in_string and content[i-1] != '\\':
                    in_string = None
            elif char in ['"', "'"]:
                in_string = char
        
        # Handle comments
        if not in_string:
            if content[i:i+2] == '--':
                in_comment = True
            elif in_comment and char == '\n':
                in_comment = False
        
        if not in_string and not in_comment:
            if char in pairs:
                stack.append((char, line, col))
            elif char in pairs.values():
                if not stack:
                    print(f"EXTRA {char} at line {line}, col {col}")
                    return
                last, l_line, l_col = stack.pop()
                if pairs[last] != char:
                    print(f"MISMATCH: {last} (line {l_line}, col {l_col}) with {char} at line {line}, col {col}")
                    return
        i += 1
        
    if stack:
        print("UNCLOSED BRACKETS:")
        for b, l, c in stack:
            print(f"  {b} started at line {l}, col {c}")
    else:
        print("BRACKETS BALANCED!")

if __name__ == "__main__":
    check_brackets(sys.argv[1])
