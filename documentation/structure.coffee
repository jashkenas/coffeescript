exports.structure = [
    id: "overview"
    href: "#top"
    title: "Overview"
    html: ["introduction", "overview"]
  ,
    id: "coffeescript-2"
    title: "CoffeeScript 2"
    html: ["coffeescript_2"]
    children: [
        id: "whats-new-in-coffeescript-2"
        title: "What’s New in CoffeeScript 2"
        html: ["whats_new_in_coffeescript_2"]
      ,
        id: "compatibility"
        title: "Compatibility"
        html: ["compatibility"]
    ]
  ,
    id: "installation"
    title: "Installation"
    html: ["installation"]
  ,
    id: "usage"
    title: "Usage"
    html: ["usage"]
    children: [
        id: "cli"
        title: "Command Line"
        html: ["command_line_interface"]
      ,
        id: "nodejs_usage"
        title: "Node.js"
        html: ["nodejs_usage"]
      ,
        id: "transpilation"
        title: "Transpilation"
        html: ["transpilation"]
    ]
  ,
    id: "language"
    title: "Language Reference"
    html: ["language"]
    children: [
        id: "functions"
        title: "Functions"
        html: ["functions"]
      ,
        id: "strings"
        title: "Strings"
        html: ["strings"]
      ,
        id: "objects-and-arrays"
        title: "Objects and Arrays"
        html: ["objects_and_arrays"]
      ,
        id: "comments"
        title: "Comments"
        html: ["comments"]
      ,
        id: "lexical-scope"
        title: "Lexical Scoping and Variable Safety"
        html: ["lexical_scope"]
      ,
        id: "conditionals"
        title: "If, Else, Unless, and Conditional Assignment"
        html: ["conditionals"]
      ,
        id: "splats"
        title: "Splats, or Rest Parameters/Spread Syntax"
        html: ["splats"]
      ,
        id: "loops"
        title: "Loops and Comprehensions"
        html: ["loops"]
      ,
        id: "slices"
        title: "Array Slicing and Splicing"
        html: ["slices"]
      ,
        id: "expressions"
        title: "Everything is an Expression"
        html: ["expressions"]
      ,
        id: "operators"
        title: "Operators and Aliases"
        html: ["operators"]
      ,
        id: "existential-operator"
        title: "Existential Operator"
        html: ["existential_operator"]
      ,
        id: "destructuring"
        title: "Destructuring Assignment"
        html: ["destructuring"]
      ,
        id: "chaining"
        title: "Chaining Function Calls"
        html: ["chaining"]
      ,
        id: "fat-arrow"
        title: "Bound (Fat Arrow) Functions"
        html: ["fat_arrow"]
      ,
        id: "generators"
        title: "Generator Functions"
        html: ["generators"]
      ,
        id: "async-functions"
        title: "Async Functions"
        html: ["async_functions"]
      ,
        id: "classes"
        title: "Classes"
        html: ["classes"]
      ,
        id: "prototypal-inheritance"
        title: "Prototypal Inheritance"
        html: ["prototypal_inheritance"]
      ,
        id: "switch"
        title: "Switch and Try/Catch"
        html: ["switch", "try"]
      ,
        id: "comparisons"
        title: "Chained Comparisons"
        html: ["comparisons"]
      ,
        id: "regexes"
        title: "Block Regular Expressions"
        html: ["heregexes"]
      ,
        id: "tagged-template-literals"
        title: "Tagged Template Literals"
        html: ["tagged_template_literals"]
      ,
        id: "modules"
        title: "Modules"
        html: ["modules"]
      ,
        id: "embedded"
        title: "Embedded JavaScript"
        html: ["embedded"]
      ,
        id: "jsx"
        title: "JSX"
        html: ["jsx"]
    ]
  ,
    id: "type-annotations"
    title: "Type Annotations"
    html: ["type_annotations"]
  ,
    id: "literate"
    title: "Literate CoffeeScript"
    html: ["literate"]
  ,
    id: "source-maps"
    title: "Source Maps"
    html: ["source_maps"]
  ,
    id: "cake"
    title: "Cake, and Cakefiles"
    html: ["cake"]
  ,
    id: "scripts"
    title: "<code>\"text/coffeescript\"</code> Script Tags"
    html: ["scripts"]
  ,
    id: "test"
    title: "Browser-Based Tests"
    href: "test.html"
  ,
    id: "resources"
    title: "Resources"
    html: ["resources"]
    children: [
        id: "books"
        title: "Books"
        html: ["books"]
      ,
        id: "screencasts"
        title: "Screencasts"
        html: ["screencasts"]
      ,
        id: "examples"
        title: "Examples"
        html: ["examples"]
      ,
        id: "chat"
        title: "Chat"
        html: ["chat"]
      ,
        id: "annotated-source"
        title: "Annotated Source"
        html: ["annotated_source"]
      ,
        id: "contributing"
        title: "Contributing"
        html: ["contributing"]
    ]
  ,
    id: "github"
    title: "GitHub"
    href: "https://github.com/jashkenas/coffeescript/"
    className: "nav-item d-md-none"
  ,
    id: "unsupported"
    title: "Unsupported ECMAScript Features"
    html: ["unsupported"]
    children: [
        id: "unsupported-let-const"
        title: "<code>let</code> and <code>const</code>"
        html: ["unsupported_let_const"]
      ,
        id: "unsupported-named-functions"
        title: "Named Functions and Function Declarations"
        html: ["unsupported_named_functions"]
      ,
        id: "unsupported-get-set"
        title: "<code>get</code> and <code>set</code> Shorthand Syntax"
        html: ["unsupported_get_set"]
    ]
  ,
    id: "breaking-changes"
    title: "Breaking Changes From 1.x"
    html: ["breaking_changes"]
    children: [
        id: "breaking-change-fat-arrow"
        title: "Bound (Fat Arrow) Functions"
        html: ["breaking_change_fat_arrow"]
      ,
        id: "breaking-changes-default-values"
        title: "Default Values"
        html: ["breaking_changes_default_values"]
      ,
        id: "breaking-changes-bound-generator-functions"
        title: "Bound Generator Functions"
        html: ["breaking_changes_bound_generator_functions"]
      ,
        id: "breaking-changes-classes"
        title: "Classes"
        html: ["breaking_changes_classes"]
      ,
        id: "breaking-changes-super-this"
        title: "<code>super</code> and <code>this</code>"
        html: ["breaking_changes_super_this"]
      ,
        id: "breaking-changes-super-extends"
        title: "<code>super</code> and <code>extends</code>"
        html: ["breaking_changes_super_extends"]
      ,
        id: "breaking-changes-jsx-and-the-less-than-and-greater-than-operators"
        title: "JSX and the <code>&lt;</code> and <code>&gt;</code> Operators"
        html: ["breaking_changes_jsx_and_the_less_than_and_greater_than_operators"]
      ,
        id: "breaking-changes-literate-coffeescript"
        title: "Literate CoffeeScript Parsing"
        html: ["breaking_changes_literate_coffeescript"]
      ,
        id: "breaking-changes-argument-parsing-and-shebang-lines"
        title: "Argument Parsing and <code>#!</code> Lines"
        html: ["breaking_changes_argument_parsing_and_shebang_lines"]
    ]
  ,
    id: "changelog"
    title: "Changelog"
    html: ["changelog"]
  ,
    id: "v1"
    title: "Version 1.x Documentation"
    href: "/v1/"
]
