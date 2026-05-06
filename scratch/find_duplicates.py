import re

def find_duplicate_keys(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all map-like structures: { key: value, key2: value2 }
    # This is a bit complex for regex, so we'll look for blocks of 'key': or "key":
    
    # Let's try to find all maps
    # This regex matches things like { 'a': 1, 'b': 2 }
    # We'll just look for sequences of 'key': within braces
    
    map_regex = re.compile(r'\{[^{}]+\}')
    matches = map_regex.findall(content)
    
    for match in matches:
        # Find all keys in this match
        keys = re.findall(r"['\"]([^'\"]+)['\"]\s*:", match)
        if len(keys) != len(set(keys)):
            seen = set()
            for k in keys:
                if k in seen:
                    print(f"Duplicate key '{k}' found in map: {match[:100]}...")
                seen.add(k)

find_duplicate_keys('lib/pages/ai_tools/university_shortlisting_page.dart')
