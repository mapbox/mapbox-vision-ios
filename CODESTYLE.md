# Coding style guide
===

## Objective-C

We follow the [Google Objective-C Style Guide](https://google.github.io/styleguide/objcguide.html).
Make sure your code is also follows [Cocoa Coding Guidelines](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).

We use automation tools to enforce formatting (see `Enforcing formatting and linting` section below).

## Swift

We follow the [Google Swift Style Guide](https://google.github.io/swift/)
Please note that [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) are considered as a part of the style guide.

There're following items that can differ a bit from Style Guide above:
- We do NOT have limit on line length, but it's recommended to have lines less than 100 characters
- We do NOT have limit on closure body length
- We do NOT have limit on function body length less than 400 lines
- We do NOT have limit on type body length
- We do NOT have limit on file length, but we strongly recommend to have files less than 1000 lines
- We have one empty vertical whitespace in the beginning of ... (propose custom: protocols/classes/functions)
- All work that we can't finish right away must be marked appropriately (`// TODO: description` or `// FIXME: description`)
- We write our code without warnings

We use automation tools to enforce formatting (see `Enforcing formatting and linting` section below).

# Enforcing formatting and linting
===

## Tooling

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to enforce Swift style and conventions.

Rules for `SwiftFormat` are configured in `.swiftformat` file.
You can find an updated list of rules and more information about regarding all available rules in [Rules.md](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md).


- [Swift Lint](https://github.com/realm/SwiftLint) to enforce Swift style and perfrorm some lint checks.

All rules for `SwiftLint` are configured in `.swiftlint.yml` file. Additionally `SwiftLint` has some custom rules. 
You can find an updated list of rules and more information about regarding all available rules in [Rules.md](https://github.com/realm/SwiftLint/blob/master/Rules.md).
You can also check [Source/SwiftLintFramework/Rules directory](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules) to see their implementation.

- We use [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) to handle formatting for Obj-C/Obj-C++ code (`.h`/`.m`/`.mm` file extensions).

## Installation and usage

Please note we're using `Swift 4.2` as a minimal version, thus make sure you install appropriate toolchain or switch to it in case you have more than one. Otherwise you might face some false positivis triggers or build errors.

### Install Swiftlint

Following options to install tools are available:

1. Using Homebrew:

```
brew update
brew install swiftlint
```

2. Using a pre-built package:

Install SwiftLint by downloading SwiftLint.pkg from the [latest GitHub release](https://github.com/realm/SwiftLint/releases/) and running it.

3. Compiling from source:

You can also build from source by cloning [Swiftlint project](https://github.com/realm/SwiftLint) and running (Xcode 10.0 or later):
```
git submodule update --init --recursive; make install
```

## How to use Swiftlint:

- Xcode

Swiftlint is integrated into an Xcode build phase, so you'll get warnings and errors displayed in the IDE each time you hit `Cmd + B`  or `Cmd + R`.

- AppCode

To integrate SwiftLint with AppCode, install [this plugin](https://plugins.jetbrains.com/plugin/9175) and configure SwiftLint's installed path in the plugin's preferences. The autocorrect action is available via `⌥⏎.`

- Running manually as a command-line tool

You can run swiftlint in the directory containing the Swift files to lint:
```
swiftlint
```
Directories will be searched recursively.

### Install Swiftformat

1. Using Homebrew:

```
brew update
brew install swiftformat
```

2. Compiling from source:

If you prefer, you can check out and build SwiftFormat manually on macOS or Linux as follows:
```
git clone https://github.com/nicklockwood/SwiftFormat   
cd SwiftFormat
swift build -c release
```
You can find more details at [Swiftformat page](https://github.com/nicklockwood/SwiftFormat#command-line-tool)

## How to use Swiftformat:

- Xcode

Swiftlint is integrated into an Xcode build phase, so you'll get warnings displayed in the IDE each time you hit `Cmd + B`  or `Cmd + R`.

- Running manually as a command-line tool

You can now just run:
```
swiftformat .
```
to format any Swift files in the current directory. In place of the `.`, you can instead type an absolute or relative path to the file or directory that you want to format.

If you prefer, you can use unix pipes to include SwiftFormat as part of a command chain. For example, this is an alternative way to format a file:
```
cat /path/to/file.swift | swiftformat --output /path/to/file.swift
```
Omitting the --output /path/to/file.swift will print the formatted file to stdout.
