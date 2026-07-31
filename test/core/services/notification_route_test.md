# `notification_route_test.dart`

## What it covers

`NotificationRoute.fromData` — the decision of *where a tapped push notification
should take the user*, extracted out of `PushNotificationService` so it can be
tested without Firebase or a running app.

| Payload | Destination |
| --- | --- |
| `chat_message` + `conversation_id` | that conversation |
| `comment_flagged` / `admin_notice` + `comment_id` | flagged-comment screen |
| `post_flagged` / `admin_notice` + `post_id` | flagged-post screen |
| anything else (`like`, `comment`, `follow`, unknown, empty) | notifications list |

Also covered: a `comment_id` wins over a `post_id` on the same admin notice,
numeric *and* string ids parse, and the `notification` block's title/body take
precedence over the data payload's.

## What's mocked

Nothing. `NotificationRoute` is a plain value object with no Flutter or Firebase
dependency — that's the whole point of splitting it out.

## Regressions locked in

- **Force-unwrapped `comment_id`.** The old router did
  `int.tryParse(commentIdStr!)` the moment the type was `comment_flagged`. A
  flagged-comment push that arrived without a `comment_id` threw a null-check
  error inside the tap handler, so the tap silently did nothing. Malformed
  payloads now degrade to the notifications list.
- **Blank-but-present ids.** `conversation_id: "   "` used to be treated as a
  real id and routed to a conversation that doesn't exist.
