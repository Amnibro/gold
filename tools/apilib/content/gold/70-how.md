# How a build works

1. **Check the cache.** Each paragraph's text, plus `lang` and `use`, is hashed. A paragraph already in `file.gold.lock` reuses its Helium. Only edited paragraphs go to the model.
2. **Find the code.** Gold retrieves the most relevant signatures from the packs you named and from `std`, matching names, files and doc comments. It lists every function of each library module on the `use` line, and adds the product's `notes.md` and a few code samples.
3. **Write the Helium.** One model call translates all the changed paragraphs.
4. **Assemble and check.** Imports are moved to the top and deduplicated. The compiler checks the file, and each error maps back to its paragraph. With `expect:`, the program runs and its output is compared.
5. **Repair.** Missing library imports are added without a model call. Other errors go back to the model for the failing paragraphs only. The last round uses `GOLD_MODEL_HARD`.
6. **Save.** On success, the lock file is saved. When the build writes into a product, that product's pack is indexed again.
