# Maid Recruiter

A whisper desk for recruiting into **Domestic Catgirl Corp**.

Incoming whispers become tabs. Saved replies go out with one click. Recruitment lines post to yell, say, guild chat, or a joined channel only when you click them. A reminder tells you when it is time to recruit again. It never sends chat for you.

Interface **16001** (`Interface-Camelot`). Version 1.0.0.

## Install

1. Copy the `MaidRecruiter` folder into `Interface/AddOns`. The folder name has to stay `MaidRecruiter`.
2. Log in, or type `/reload`.
3. Type `/maid`.

The first login prints a short hello in chat. After that, the window stays closed until you open it or a whisper arrives.

## Open it

| Command | What it does |
| --- | --- |
| `/maid` or `/mr` | Open or close the window |
| `/maid settings` or `/maid config` | Open the window on Settings |
| `/maid remind` | Show the reminder now, as a test |
| `/maid help` | Print the command list |

Drag the title bar to move the window. Drag the corner to resize it. `_` collapses it to the title bar. `X` closes it, and so does Escape. Size and position are remembered.

## Whispers

The **Recruit** tab is home. Everyone who whispers you gets a tab with their name.

- The window opens on a new whisper, unless you turn that off in Settings. It stays quiet during combat and opens after combat ends.
- An unread tab is marked until you look at it.
- The last 50 lines of each conversation are kept, including whispers you send from the normal chat box.
- Type in **Write a whisper** and press Enter or **Send**.
- Close a tab with the `x` on that tab. That drops its history.

## Quick replies

On a person's tab, the right side lists your whisper buttons.

- Click a button to send that text.
- Shift-click a button to drop the text into the reply box instead, so you can edit it first.
- Hover a button to read the full message.

Three replies are included the first time the addon loads: a greeting, a short description of the guild, and how to join. Add, edit, or remove them in Settings.

## Broadcasts

The Recruit tab shows each recruitment line as a card. Click the card or its **Send** button. The same buttons sit on the right side of that tab.

Each broadcast has its own destination:

| Destination | Where it goes |
| --- | --- |
| Yell | `/yell` |
| Say | `/say` |
| Guild chat | Your guild channel |
| Channel | A joined channel, by name or number |

The starter set is a city yell, a Trade-channel post, and a guild-chat nudge. Change the words and the destination in Settings. A custom channel has to be one you have already joined. If the name cannot be found, put the channel number in that field instead.

Yell and channel messages have to come from a click or a key press. That is a client rule. The addon does not try to post those on a timer.

## Reminder

**Remind me to recruit** is on by default, every **15** minutes. You can set the wait from 1 to 180 minutes.

When the time is up, the window opens, a strip says **Time to recruit**, and a sound plays. Nothing is posted.

- **Snooze** asks again in 5 minutes.
- **Done** starts the full wait over.
- Sending a broadcast also starts the full wait over.
- Changing the minutes starts the wait over, unless the strip is already showing.
- If you are in combat, the reminder waits until combat ends.

## Key bindings

Escape, Options, Key Bindings, AddOns, **Maid Recruiter**.

- Whisper button 1 through 8 send the first eight quick replies to the open person.
- Broadcast button 1 through 6 send the first six recruitment lines.

Buttons past those slots still work from the window. They just cannot take a key.

## Settings

Open **Settings** on the title bar, or type `/maid settings`.

- **Whisper buttons** have a short label and the text that gets sent.
- **Broadcast buttons** also pick Yell, Say, Guild chat, or Channel.
- A counter shows length. Past 255 characters the addon splits the text.
- **Add whisper button** and **Add broadcast button** append a new row. The remove button drops that row.
- **Open this window when a whisper arrives** is on by default.
- **Play an extra sound on a new whisper** is off by default. The reminder sound is separate.

Edits save as you type. They live in the `MaidRecruiterDB` saved variable.

## What gets sent

Chat lines are cleaned before they go out. Line breaks become spaces. A raw `|` becomes `/`, because a bare pipe can disconnect the client.

A message can leave in up to three parts of 255 characters. If anything is still left after that, a whisper keeps the rest in the reply box. A broadcast reports the unsent tail in the status line and does not send it.

## Reset

Log out, then delete `MaidRecruiter.lua` from that character's `SavedVariables` folder. The next login restores the starter replies, the starter broadcasts, and a 15 minute reminder.
