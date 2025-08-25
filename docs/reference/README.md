# Async::Enumerable Reference Documentation

This directory contains detailed reference documentation for the async-enumerable gem.

## Core Components

- [Async::Enumerable Module](enumerable.md) - Main module for adding async capabilities to enumerables
- [Async::Enumerator Class](enumerator.md) - Wrapper class providing async enumerable methods
- [ConcurrencyBounder Module](concurrency_bounder.md) - Bounded concurrency control

## Method Categories

### [Predicate Methods](methods/predicates.md)
- `all?`, `any?`, `none?`, `one?`
- `find`, `find_index`
- `include?`, `member?`

### [Transformer Methods](methods/transformers.md)
- `map`, `select`, `reject`
- `filter_map`, `flat_map`
- `compact`, `uniq`, `sort`, `sort_by`

### [Converter Methods](methods/converters.md)
- `to_a` - Convert to array
- `sync` - Materialize async chain results

## Quick Start

For basic usage, see the main [README](../../README.md). For detailed API documentation, explore the files linked above.

## Note on Documentation Style

The source code contains terse YARD documentation (2-3 lines) for quick reference. These detailed markdown files provide comprehensive documentation including:

- Detailed method descriptions
- Parameter explanations
- Return value documentation
- Usage examples
- Implementation notes
- Performance considerations
- Common patterns

This separation keeps the source code clean and readable while maintaining thorough documentation.