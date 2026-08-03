# `chat_models_test.dart`

## What it covers

That `ChatMessage.fromJson` and `Conversation.fromJson` normalise timestamps at
the parsing boundary: `created_at`, `last_message_at` and
`other_user.last_seen` all land on the correct instant, in **local** time,
whether the API spells them with a trailing `Z` or not.

It also covers `ChatMessage.status`: each value the API sends parses, a missing
or unrecognised field falls back to `sent` (which is the shape the API used to
return for *every* message — the cause of checkmarks resetting to one tick), and
`withStatus` upgrades without dropping the rest of the message.

Also the null/missing paths: a missing `created_at` falls back instead of
throwing, and a missing `last_message_at` / `last_seen` stays null.

## What's mocked

Nothing — plain JSON maps.

## Why it's at the model layer

Normalising here means every `DateTime` inside the app is already local, so the
three formatters that render chat times (`message_bubble._fmt`,
`chats_list_screen._shortTime`, `chat_detail_screen._PresenceSubtitle._fmt`)
can read `.hour`/`.minute` directly and stay correct. Fixing them individually
would have left the next formatter to get it wrong again.

See [app_date_time_test.md](../../../../../core/helpers/app_date_time_test.md)
for the underlying parsing rules and the full description of the three-hour bug.
