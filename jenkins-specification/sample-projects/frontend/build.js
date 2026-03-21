const fs = require('fs');
const path = require('path');

console.log('Building frontend application...');

const distDir = path.join(__dirname, 'dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const indexContent = `
<!DOCTYPE html>
<html>
<head>
  <title>Jenkins Sample App</title>
</head>
<body>
  <h1>Jenkins Sample Frontend</h1>
  <p>Build: ${process.env.BUILD_NUMBER || 'local'}</p>
  <p>Timestamp: ${new Date().toISOString()}</p>
</body>
</html>
`;

fs.writeFileSync(path.join(distDir, 'index.html'), indexContent);
console.log('Build completed successfully!');