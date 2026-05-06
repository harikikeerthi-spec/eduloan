const fs = require('fs');

const content = fs.readFileSync('lib/pages/ai_tools/university_shortlisting_page.dart', 'utf8');

// Find all lines that look like a key-value pair in a map
const lines = content.split('\n');
let currentMap = [];
let inMap = false;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.includes('{')) {
        inMap = true;
        currentMap = [];
    }
    
    if (inMap) {
        const keyMatch = line.match(/['"]([^'"]+)['"]\s*:/);
        if (keyMatch) {
            const key = keyMatch[1];
            if (currentMap.includes(key)) {
                console.log(`Duplicate key "${key}" found on line ${i + 1}`);
            }
            currentMap.push(key);
        }
    }
    
    if (line.includes('}')) {
        inMap = false;
        currentMap = [];
    }
}
