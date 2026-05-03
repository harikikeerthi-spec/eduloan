const fs = require('fs');
const path = 'c:/flutter/projects/Vidhyaloan/lib/pages/my_loans_page.dart';
let content = fs.readFileSync(path, 'utf8');
const search = '            ],\r\n          ),\r\n        ),\r\n      ),\r\n    );\r\n  }';
const replacement = '            ],\r\n          ),\r\n        ),\r\n      ),\r\n    ),\r\n  );\r\n}';
// If CRLF doesn't work, try LF
if (!content.includes(search)) {
  const searchLF = '            ],\n          ),\n        ),\n      ),\n    );\n  }';
  const replacementLF = '            ],\n          ),\n        ),\n      ),\n    ),\n  );\n}';
  content = content.replace(searchLF, replacementLF);
} else {
  content = content.replace(search, replacement);
}
fs.writeFileSync(path, content);
console.log('Fixed!');
