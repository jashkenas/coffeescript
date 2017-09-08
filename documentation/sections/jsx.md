## JSX

[JSX](https://facebook.github.io/react/docs/introducing-jsx.html) is JavaScript containing interspersed XML elements. While conceived for [React](https://facebook.github.io/react/), it is not specific to any particular library or framework.

CoffeeScript supports interspersed XML elements, without the need for separate plugins or special settings. The XML elements will be compiled as such, outputting JSX that could be parsed like any normal JSX file, for example by [Babel with the React JSX transform](https://babeljs.io/docs/plugins/transform-react-jsx/). CoffeeScript does _not_ output `React.createElement` calls or any code specific to React or any other framework. It is up to you to attach another step in your build chain to convert this JSX to whatever function calls you wish the XML elements to compile to.

Just like in JSX and HTML, denote XML tags using `<` and `>`. You can interpolate CoffeeScript code inside a tag using `{` and `}`. To avoid compiler errors, when using `<` and `>` to mean “less than” or “greater than,” you should wrap the operators in spaces to distinguish them from XML tags. So `i < len`, not `i<len`. The compiler tries to be forgiving when it can be sure what you intend, but always putting spaces around the “less than” and “greater than” operators will remove ambiguity.

```
codeFor('jsx')
```

Older plugins or forks of CoffeeScript supported JSX syntax and referred to it as CSX or CJSX. They also often used a `.cjsx` file extension, but this is no longer necessary; regular `.coffee` will do.
