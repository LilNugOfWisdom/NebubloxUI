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
    
    # Advanced state machine for Lua syntax
    in_string = None
    in_single_comment = False
    in_block_comment = False
    in_multi_string = False
    
    i = 0
    while i < len(content):
        char = content[i]
        
        # Track line and column
        if char == '\n':
            line += 1
            col = 0
            if in_single_comment:
                in_single_comment = False  # Reset single-line comments on newline
        else:
            col += 1
            
        # 1. Handle Block Comments: --[[ ... ]]
        if in_block_comment:
            if content[i:i+2] == ']]':
                in_block_comment = False
                i += 1 # Skip the second ']'
            i += 1
            continue
            
        # 2. Handle Multi-line Strings: [[ ... ]]
        if in_multi_string:
            if content[i:i+2] == ']]':
                in_multi_string = False
                i += 1 # Skip the second ']'
            i += 1
            continue
            
        # 3. Handle Single-line Comments: --
        if in_single_comment:
            i += 1
            continue

        # 4. Handle Standard Strings: "..." or '...'
        if in_string:
            # Check for closing quote, ensuring it's not escaped (e.g., \")
            if char == in_string and content[i-1] != '\\':
                in_string = None
            i += 1
            continue

        # --- WE ARE IN ACTIVE CODE ---

        # Check for state changes
        if content[i:i+4] == '--[[':
            in_block_comment = True
            i += 3 # Skip the rest of the sequence
        elif content[i:i+2] == '--':
            in_single_comment = True
            i += 1
        elif content[i:i+2] == '[[':
            in_multi_string = True
            i += 1
        elif char in ['"', "'"]:
            in_string = char
            
        # Check brackets
        elif char in pairs:
            stack.append((char, line, col))
        elif char in pairs.values():
            if not stack:
                print(f"❌ EXTRA '{char}' found at line {line}, col {col}")
                return
            
            last, l_line, l_col = stack.pop()
            if pairs[last] != char:
                print(f"❌ MISMATCH: '{last}' (line {l_line}, col {l_col}) closed with '{char}' at line {line}, col {col}")
                return
                
        i += 1
        
    # Final Validation
    if stack:
        print("⚠️ UNCLOSED BRACKETS FOUND:")
        for b, l, c in stack:
            print(f"  -> '{b}' started at line {l}, col {c}")
    else:
        print("✅ BRACKETS BALANCED! Your Lua script is structurally sound.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python check_brackets.py <your_script.lua>")
    else:
        check_brackets(sys.argv[1])