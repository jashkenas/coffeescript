## Block Regular Expressions

Similar to block strings and comments, CoffeeScript supports block regexes — extended regular expressions that ignore internal whitespace and can contain comments and interpolation. Modeled after Perl’s `/x` modifier, CoffeeScript’s block regexes are delimited by `///` and go a long way towards making complex regular expressions readable. To quote from the CoffeeScript source:

```
codeFor('heregexes')
```
