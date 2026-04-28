const fs = require('fs');
let text = fs.readFileSync('functions/src/index.ts', 'utf8');

// Replace the exact export line while preserving the rest of the file
const updatedText = text.replace(/export\s*\{[^}]*syncUserClaimsOnUpdate[^}]*\}\s*;?/, 'export * from "./admin_roles";\n');

if (text !== updatedText) {
  fs.writeFileSync('functions/src/index.ts', updatedText);
}
