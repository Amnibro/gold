# Packs

A pack is an index of a product's Helium code. It tells Gold which functions, types and globals exist, so a paragraph can say "using the profile's level rules" and Gold finds the right function.

## The std pack

`std` is the [Helium library](/api-library/helium/). Gold can always see it, and you can name any library module on a `use` line:

```
use os, math, net.sock
```

## Index your own product

```
gold pack shop ~/code/shop/src lang=amni main=main.amni test='./run_tests.sh'
```

Now a Gold file can write into that product:

```
use shop
into cart/total.amni

`cart_total(c Cart) real` adds the line prices and applies the store's tax rule.
```

When a build writes into a product, Gold indexes the product again, so the new code is callable from your next Gold file.

## What a pack holds

| File | What it holds |
|---|---|
| `pack.conf` | The product's folder, language, root file, test command and skip pattern. |
| `api.tsv` | Every top-level function, type and global, with its file, line and doc comment. |
| `notes.md` | Optional conventions you write by hand. Gold shows them to the model on every build. |

## Check what Gold will find

```
gold find shop,std apply the tax rule
```

If the function you meant is missing from the list, name it in your paragraph.
