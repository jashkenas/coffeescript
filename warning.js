var chalk = require('chalk');
if (require('./package.json').name === 'coffee-script') { 
  // var red, yellow, cyan, reset; red = yellow = cyan = reset = ''; 
  // if (!process.env.NODE_DISABLE_COLORS) { 
  //   red = '\\x1b[31m'; 
  //   yellow = '\\x1b[33m'; 
  //   cyan = '\\x1b[36m'; 
  //   reset = '\\x1b[0m'; 
  // } 
  console.warn(chalk.red('CoffeeScript has moved!') + ' Please update references to ' + chalk.yellow('"coffee-script"') + ' to use ' + chalk.yellow('"coffeescript"') + ' (no hyphen) instead.'); 
  console.warn('Also, a new major version has been released under the ' + chalk.yellow('coffeescript') + ' name on NPM. This new release targets modern JavaScript, with minimal breaking changes. Learn more at ' + chalk.cyan('http://coffeescript.org') + '.'); 
  console.warn(''); 
}