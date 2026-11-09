# Helium

Helium is a memory-safe systems language with no heap, no garbage collector and no lifetime annotations. Its compiler, `hc`, is written in Helium and builds itself. It writes native executables, C and WebAssembly.

## Install

```
git clone https://github.com/Amnibro/helium
cd helium
hc/bootstrap.sh
```

This compiles the included seed once with `cc`, then has the compiler rebuild itself until its output stops changing.

## Your first program

Save this as `hello.amni`:

```amni
fn main() {
	print("hello, world");
}
```

Then run it:

```
build/hc hello.amni
```

## Two ways to write it

Helium has two syntaxes with the same meaning. `.amni` files use braces and semicolons. `.he` files use indentation, like the compiler and library themselves. Both can import each other.

## Writing it in plain English

[Gold](/api-library/gold/) writes checked Helium from plain English. You can use everything on this site from Gold by naming the module on a `use` line.

## More

- [Formal specification draft](https://github.com/Amnibro/helium/tree/main/spec)
- [Source code](https://github.com/Amnibro/helium)
