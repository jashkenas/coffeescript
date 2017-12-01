var fs = require('fs'),
  path = require('path');

function readJsonFile(filePath) {
  try {
    var data = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(data);
  } catch (error) {
    return null;
  }
}

var pkgCoffeeData = readJsonFile('./package.json');

// In npm when a package is installed the 'package.json' is amended and some new fields are added
// one of these fields is '_where' which indicates from where the package was installed.
// in case _where is not defined we cannot determine from where it was installed, thus show the warning.
if (pkgCoffeeData && pkgCoffeeData._where) {
  if (pkgCoffeeData._where.indexOf('node_modules') !== -1) {
    return;
  }

  var pkgData = readJsonFile(path.join(pkgCoffeeData._where, './package.json'));
  if (!pkgData) {
    return;
  }

  var hasOldCoffeeScript = (pkgData.dependencies && pkgData.dependencies['coffee-script'])
    || (pkgData.devDependencies && pkgData.devDependencies['coffee-script']);

  if (!hasOldCoffeeScript) {
    return;
  }
}

var red,
  yellow,
  cyan,
  reset;

red = yellow = cyan = reset = '';

if (!process.env.NODE_DISABLE_COLORS) {
  red = '\x1b[31m';
  yellow = '\x1b[33m';
  cyan = '\x1b[36m';
  reset = '\x1b[0m';
}

console.warn(red + 'CoffeeScript has moved!' + reset + ' Please update references to ' + yellow + 'coffee-script' + reset + ' to use ' + yellow +
  'coffeescript' + reset + ' (no hyphen) instead.');

console.warn('Also, a new major version has been released under the ' + yellow + 'coffeescript' + reset +
  ' name on NPM. This new release targets modern JavaScript, with minimal breaking changes. Learn more at ' + cyan + 'http://coffeescript.org' + reset + '.\n');
