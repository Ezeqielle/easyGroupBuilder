# EasyGroupBuilder

World of Warcraft Forever addon that helps you fill your group from the group finder.

## Join requests

While your group is listed in the group finder and you are its leader (or you listed alone),
every player who whispers you is added to the **Join requests** window, which opens by itself:

- **Name** (in class color), **Class**, **Level** and **Zone**, one line per player.
  Five lines are visible; scroll for the others. Hover a line to read their whisper.
- **Level and zone fill in by themselves**: the game only allows a /who right after a key
  press or a click, so the addon sends one on your next key press or click in the world
  (one every 3 seconds, oldest request first, hidden from chat). **Who** does it by hand.
  Class comes straight from the whisper. Turn the automatic lookup off with `/egb autowho off`.
- **Invite** invites them; the line shows *Invited*, then leaves the list when they join.
- **X** removes a line, **Clear** empties the list. Requests older than 30 minutes go away,
  and the list is cleared when your listing ends.

The window can be moved (drag it) and closed with Escape.

## Commands

- `/egb` — show / hide the join requests window.
- `/egb test` — fill the window with fake players, to try it out.
- `/egb clear` — empty the list.
- `/egb autowho on|off` — automatic level / zone lookup (on by default).
- `/egb help` — list the commands.

## Install

Download `EasyGroupBuilder-vX.Y.Z-forever.zip` from the latest GitHub release and unzip it into
`World of Warcraft/_forever_/Interface/AddOns/` (or add the repo as a GitHub source in WowUp).

## Release

Push a `vX.Y.Z` tag: the Release workflow packages the addon (BigWigsMods/packager, version
from the tag into the toc) and publishes the zip and release.json on GitHub.
