# Get started with Gold

Gold is programming in plain English. You describe what a program does, one paragraph per piece, and Gold writes checked Helium. It finds the functions your code can call, has a language model write the Helium, checks it with the Helium compiler, repairs what fails, and saves the result so unchanged paragraphs never cost another model call.

## What you need

- A built checkout of [Helium](https://github.com/Amnibro/helium): run `hc/bootstrap.sh` inside it.
- The Claude Code command-line tool, signed in. Gold makes its model calls through `claude -p`.

## Install

```
git clone https://github.com/Amnibro/helium
git clone https://github.com/Amnibro/gold
cd helium
hc/bootstrap.sh
cd ../gold
HC_LIB=../helium/hc/lib ../helium/build/hc build gold.amni -o gold_bin
GOLD_HELIUM=../helium ./gold pack std ../helium/hc/lib lang=he
```

Keep `GOLD_HELIUM` set to that Helium checkout whenever you run Gold.

## Your first program

Save this as `hello.gold`:

```
`main()` prints "hello, world".

expect:
hello, world
```

Then run it:

```
gold run hello.gold
```

Gold writes `hello.amni` next to your file, runs it, and checks that the output matches the `expect:` lines. If it does not match, Gold repairs the code and tries again.

## A real program

```
# word frequency report
A function `top_words` takes a text and a count n and returns the n most common lowercase words with their counts, most common first, ties broken alphabetically. Words are runs of letters; everything else separates them.

The program runs `top_words` on "The cat and the hat. The bat sat on the cat!" with n = 3 and prints each as `word: count`, one per line, then prints the total number of words.

expect:
the: 4
cat: 2
and: 1
total: 11
```

A build prints what it did and what it cost:

```
$ gold build units.gold
gold: translating 6 of 6 blocks with sonnet
gold: repairing 1 block(s), round 1
gold: units.amni ok (6 blocks, 294 Gold words -> 846 Helium words; 2 model calls, $0.19, 36 s)
```

## Where to go next

- [Commands](/api-library/gold/commands): everything the `gold` command can do.
- [File format](/api-library/gold/format): headers, blocks, data tables and `expect:`.
- [Writing good Gold](/api-library/gold/writing): how to get the right program on the first try.
- [Helium library](/api-library/helium/): every function your Gold code can call, grouped by what it does.
