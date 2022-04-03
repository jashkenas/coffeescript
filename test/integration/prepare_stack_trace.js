// This simulates a library hooking into `Error.prepareStackTrace` such as Babel
// via `source-map-support`. This file is used in `../sourcemap.coffee` to test
// that we won't break a previously installed handler.
Error.prepareStackTrace = function (err, frames) {
  return frames.map(function (f) {
    return `^_^ ${f.getFileName()}:${f.getLineNumber()}:${f.getColumnNumber()}\n`;
  }).join("");
};
