---
name: describe-object
description: Write or revise Baldur's Gate II item lore for a mod item. Use when asked to "describe object", "write description", "write lore", "scrivi descrizione", "descrivi", or "scrivi lore", followed by an item resref or displayed name.
---

# Describe Object

Create a lore paragraph for the requested item, suitable for its `SAY DESC`
entry in this repository's WeiDU `.tpa` files. The item may be identified by
its resref (for example, `TB#LEPR`) or displayed name (for example,
`Protector of the Second +4`).

## Locate the item

1. Search only `lib/items/`, case-insensitively, for both forms of the
   supplied identifier:
   - resref: search the `COPY` source path, allowing for an optional `.itm`
     suffix;
   - displayed name: search `SAY NAME2`.
2. Confirm that the matching result belongs to a `COPY` block. Read the whole
   block, from `COPY` through the next `COPY` command or the end of the file.
3. Extract the item's source resref, `SAY NAME1`, `SAY NAME2`, existing
   `SAY DESC` (if present), restrictions, equipped effects, charge/use
   abilities, penalties, armor class, weight, and any useful nearby comment.
4. If the supplied name finds multiple items, show the matching `NAME2`,
   resref, and file for each and ask the user to choose. Do not invent a
   description until the item is unambiguous.
5. If no item is found, state that clearly and do not guess a file or item.

Useful searches from the repository root:

```powershell
rg -in -g "*.tpa" 'TB#LEPR|Protector of the Second \+4' lib\items
```

For a resref, also search the filename form:

```powershell
rg -in -g "*.tpa" 'COPY .*TB#LEPR\.itm' lib\items
```

## Decide the item story

Build the description from the item data rather than treating mechanics as
unrelated flavor.

1. If there is an existing description, ask the user if they want to:
    - ignore it completely and start from zero (see the next section for guidance)
    - or revise it (ask the user for instructions according to the options in the next section).
2. If there is no existing description, ask the user if they want to guide the
   skill in any meaningful way. Offer the following options:
   - is the item tied to a specific class/alignment?
   - is the item tied to a specific person (for example dropped by a key foe)?
   - is there a specific item appearance they want to emphasize? for example a multicolered cloak or mirrored shield
   - is the item the result of an upgrade? If so, the description must be on two lines (separated by a blank in the middle):
     - first line is the original description
     - second line is a description of the upgrade process and its consequences (no more than 20 words)
  - What is the power level of the item? Make the description more grandiose for a powerful item, or more humble for a minor item. Avoid generic praise.
  - Is this item coming from other media?
    - case 1 - it is based on a power metal album/saga/group - fit many song titles in the description, making them still make sense
    - case 2 - it is based on a fantasy novel, game... or on real life - keep the description mysterious and vague, only mention the key name and legend
2. Select one central premise that explains the item's most distinctive
   benefit. Examples: stealth effects imply scouts, spies, assassins, or
   wardens; elemental protection implies a maker, foe, or place tied to that
   element; castable magic implies deliberate enchantment, training, or a
   patron.
3. Treat a meaningful drawback as a plot element, cost, flaw, curse, or
   exploitable weakness. Do not omit it merely because it is negative.
4. Use the item type, appearance, weight, and restrictions to constrain the
   story. An evil-only item may have a malicious provenance; a class-restricted
   item should have a believable reason its design favors that class.
5. Prefer a specific person, group, or place only when it makes the premise
   stronger. New proper nouns must be plausible for the Forgotten Realms and
   must not contradict existing lore in the block (and must not be tied to real
   world places or people unless the user asked to).
6. End with an unresolved fate, consequence, irony, or warning when it gives
   the object a lived-in history. Avoid explaining every detail.

## Style and formatting

- Write in English.
- Match Baldur's Gate II item-text voice: concise, third-person, atmospheric,
  and grounded in a small historical anecdote rather than modern exposition.
- Write one prose paragraphs, normally no more than 125 words, unless the user asked
  differently, if the item is an upgrade (see above), or if the user said that the item
  is of max power level.
- Mention mechanics indirectly through narrative if you will mention them. Do not
  repeat numerical bonuses, spell names, charges, armor class, weight, or
  the game's exact statistics in the lore paragraph.
- Use simple past for the item's history. Reserve present tense for enduring
  curses, reputation, or a continuing effect.
- Keep names sparse: normally no more than two newly introduced proper nouns.
  Use established names from the existing description first.
- Avoid modern phrasing, jokes, player-facing instruction, generic praise
  ("legendary", "unmatched"), and claims that exceed the item's capabilities.
- Preserve the file's plain ASCII punctuation when editing it: use `-`, not
  typographic dashes or smart quotation marks. Maintain the blank line before
  `STATISTICS:`.

## Randomized creative choices

When the source material permits several equally valid directions, select one
option at random from each applicable row. Do not show the random choices to the user. Use them to guide the story, but do not mention them in the lore paragraph.

Only describe the item's abilities 30% of the time. If so, use no more than 20 words to describe the item's abilities.
Do not always put this in the end of the paragraph, 30% of the time place it in a key place of the description (for example, "Grimbad commissioned this cloak
to aid him in his raids by paralyzing any foe who dared attack him").

| Element | Random choices |
| --- | --- |
| Former owner | ranger/scout, assassin/spy, soldier/guard, mage/artificer, priest/zealot, noble/outlaw |
| Item origin | commissioned reward, battlefield salvage, guild work, inherited heirloom, failed experiment, funeral or vow offering |
| Story conflict | betrayal, ambition, mistaken trust, broken oath, siege or hunt, curse with a hidden cost |
| Ending | owner vanished, object was looted, allies concealed the truth, foe exploited its flaw, lineage lost it, fate remains unknown |
| Tone | melancholy, ominous, austere, bitterly ironic, quietly heroic, cautionary |
| Descriptive focus | appearance, craftsmanship, elemental power, magical effect, historical significance, personal connection |

Do not randomize facts already supplied by the item description. If an existing
description names Raroh and Avlorm (and the user asked to preserve the original story), for example, keep them and use the poison
vulnerability as the central irony instead of replacing the story with a new
one.

## Deliver the result

Return the proposed lore text first. Ask the user for feedback, and if the user accepts it then replace the description in the TPA file.

