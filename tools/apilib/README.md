# apilib

Builds amni-scient.com/api-library from the Helium library and the guide pages in `content/`, and keeps it up to date.

The `amni-library-angel` user timer runs `apilib sync` every 15 minutes. When public Helium main or this folder changes, it re-indexes the library, asks the model about new symbols only, refreshes the guide pages, rebuilds the site pages and pushes them. Once a day it also refreshes the public Gold repository. Check it with `journalctl --user -u amni-library-angel`. Create `~/.local/state/amni-library-angel/pause` to stop it.

- `data/api.tsv`: every library symbol on public Helium main, re-indexed by `sync`. Gold's own `packs/std` stays separate and follows `GOLD_HELIUM`, and the public Gold repository gets this index as its `packs/std/api.tsv`.
- `data/modules.tsv`, `data/categories.tsv`, `data/pagedesc.tsv`: which category each module is in, plus summaries. `sync` files new modules itself. A new guide page needs a description by hand.
- `data/devonly.txt`: modules not on public Helium main yet. They get a Coming soon notice and no source links. Empty today.
- `data/desc.*.tsv`: the one-line descriptions, topics and public or internal levels.
- `content/helium/language.md`: generated from HELIUM.md by `sync`. Do not edit it here.
- `content/gold/10-commands.md`, `30-settings.md`, `content/helium/10-commands.md`: updated by the model when the tools' help text changes.

After editing this folder, commit it, or `sync` skips the run. To change the tool itself: `gold build apilib.gold`, `gold build search.gold`, then compile `apilib.amni` to `~/.local/bin/amni-library-angel` with hc.
