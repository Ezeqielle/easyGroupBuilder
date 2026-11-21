# EasyGroupBuilder

World of Warcraft Forever addon that helps you fill your group from the group finder.

## Join requests

While your group is listed in the group finder and you are its leader (or you listed alone),
every player who whispers you is added to the **Join requests** window, which opens by itself:

- **Name** (in class color), **Class**, **Level** and **Zone**, one line per player.
  Five lines are visible; scroll for the others. Hover a line to read their whisper.
- **Who** looks up the player's level and zone (the game only allows a /who from a click,
  and about one every few seconds). Class comes straight from the whisper.
- **Invite** invites them; the line shows *Invited*, then leaves the list when they join.
- **X** removes a line, **Clear** empties the list. Requests older than 30 minutes go away,
  and the list is cleared when your listing ends.

The window can be moved (drag it) and closed with Escape.

## Commands

- `/egb` — show / hide the join requests window.
- `/egb test` — fill the window with fake players, to try it out.
- `/egb clear` — empty the list.
- `/egb help` — list the commands.

## Install

Download `EasyGroupBuilder-vX.Y.Z-forever.zip` from the latest GitHub release and unzip it into
`World of Warcraft/_forever_/Interface/AddOns/` (or add the repo as a GitHub source in WowUp).

## Release

Push a `vX.Y.Z` tag: the Release workflow packages the addon (BigWigsMods/packager, version
from the tag into the toc) and publishes the zip and release.json on GitHub.
