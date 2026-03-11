const fs = require('fs');
const code = fs.readFileSync('lib/pages/ai_tools/visa_interview_page.dart', 'utf-8');
const lines = code.split('\n');
let score = 0;
let classStarted = false;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('class _VisaInterviewPageState')) classStarted = true;
    if (!classStarted) continue;

    for (let j = 0; j < line.length; j++) {
        if (line[j] === '{') score++;
        if (line[j] === '}') {
            score--;
            if (score === 0 && classStarted) {
                console.log(`Class ended prematurely at line ${i + 1}: ${line}`);
                process.exit(1);
            }
        }
    }
}
console.log('Class reached end of file with score:', score);
