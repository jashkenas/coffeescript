### JSX and the `<` and `>` operators

With the addition of [JSX](#jsx), the `<` and `>` characters serve as both the “less than” and “greater than” operators and as the delimiters for XML tags, like `<div>`. For best results, in general you should always wrap the operators in spaces to distinguish them from XML tags: `i < len`, not `i<len`. The compiler tries to be forgiving when it can be sure what you intend, but always putting spaces around the “less than” and “greater than” operators will remove ambiguity.
