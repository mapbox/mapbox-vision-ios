# Coding style guide

## Swift

We follow the [Google Swift Style Guide](https://google.github.io/swift/).

Please note that [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) are considered as a part of the style guide.

There're following items that can differ a bit from Style Guide above:
- We do NOT have limit on line length, but it's recommended to have lines less than 120 characters
- We do have limit on closure body length (50 lines)
- We do have limit on function body length (100 lines)
- We do have limit on type body length (500 lines)
- We do have limit on file length (1000 lines)
- We do NOT have empty vertical whitespace after opening braces
- We use Javadoc-style block comments `/** ... */` for multiline doc comments
- We use `///` comments for single-line doc comments
- All work that we can't finish right away must be marked appropriately (`// TODO: description` or `// FIXME: description`)
- We write our code without warnings!

We use automation tools to enforce formatting (see [corresponding section](https://github.com/mapbox/mapbox-vision-ios/blob/master/CODESTYLE.md#enforcing-formatting-and-linting) below).

If you have any issues with linting/formatting, please let iOS mobile team know.

# Enforcing formatting and linting

## Tooling

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to enforce Swift style and conventions.

Rules for `SwiftFormat` are configured in `.swiftformat` file.

You can find an updated list of rules and more information about regarding all available rules in [Rules.md](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md).

- [Swift Lint](https://github.com/realm/SwiftLint) to enforce Swift style and perfrorm some lint checks.

All rules for `SwiftLint` are configured in `.swiftlint.yml` file. Additionally `SwiftLint` has some custom rules. 

You can find an updated list of rules and more information about regarding all available rules in [Rules.md](https://github.com/realm/SwiftLint/blob/master/Rules.md).

You can also check [Source/SwiftLintFramework/Rules directory](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules) to see their implementation.

## Installation and usage

Please note we're using `Swift 4.2` as a minimal version, thus make sure you install appropriate toolchain or switch to it in case you have more than one. Otherwise you might face some false positivis triggers or build errors.

Please do NOT add new rules into config files without explicit approve from mobile team!

### Install Swiftlint

Preferred way to install Swiftlint is using `Homebrew`. Open terminal and run following commands:

```
brew update
brew install swiftlint
```

You can find more information about installation at [Swiftlint's GitHub page](https://github.com/realm/SwiftLint#installation).

### How to use Swiftlint:

- Xcode

In our projects we integrated Swiftlint into an Xcode build phase, so you'll get warnings and errors displayed in the IDE each time you hit `Cmd + B`  or `Cmd + R`.

- AppCode

To integrate SwiftLint with AppCode, install [this plugin](https://plugins.jetbrains.com/plugin/9175) and configure SwiftLint's installed path in the plugin's preferences. The autocorrect action is available via `⌥⏎.`

- Running manually as a command-line tool

You can run swiftlint in the directory containing the Swift files to lint:
```
swiftlint
```
Directories will be searched recursively.

### Install Swiftformat

Preferred way to install Swiftlint is using `Homebrew`. Open terminal and run following commands:

```
brew update
brew install swiftformat
```

You can find more information about installation at [Swiftformat's GitHub page](https://github.com/nicklockwood/SwiftFormat#command-line-tool).

### How to use Swiftformat:

- Xcode

In our projects we integrated Swiftformat into an Xcode build phase, so you'll get warnings displayed in the IDE each time you hit `Cmd + B`  or `Cmd + R`.

- Running manually as a command-line tool

You can just run:
```
swiftformat .
```
to format any Swift files in the current directory. In place of the `.`, you can instead type an absolute or relative path to the file or directory that you want to format.

If you prefer, you can use unix pipes to include SwiftFormat as part of a command chain. For example, this is an alternative way to format a file:
```
cat /path/to/file.swift | swiftformat --output /path/to/file.swift
```
Omitting the --output /path/to/file.swift will print the formatted file to stdout.
