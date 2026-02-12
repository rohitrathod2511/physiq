const fs = require('fs');
fs.writeFileSync('test_node_log.txt', 'HELLO FILE SYSTEM');
console.log('File written');
try {
  const admin = require('firebase-admin');
  fs.appendFileSync('test_node_log.txt', '\nFirebase Admin Loaded');
} catch (e) {
  fs.appendFileSync('test_node_log.txt', '\nFailed to load Firebase Admin: ' + e.message);
}
