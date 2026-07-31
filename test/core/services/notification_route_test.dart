import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/services/notification_route.dart';

/// See notification_route_test.md for what this covers and why.
void main() {
  NotificationRoute resolve(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) =>
      NotificationRoute.fromData(
        data,
        notificationTitle: title,
        notificationBody: body,
      );

  group('chat messages', () {
    test('routes to the conversation named in the payload', () {
      final route = resolve({
        'notification_type': 'chat_message',
        'conversation_id': 'conv-7',
      });

      expect(route.kind, NotificationRouteKind.chatConversation);
      expect(route.conversationId, 'conv-7');
    });

    test('falls back to the notifications list without a conversation id', () {
      final route = resolve({'notification_type': 'chat_message'});

      expect(route.kind, NotificationRouteKind.notificationsList);
    });

    test('treats a blank conversation id as missing', () {
      final route = resolve({
        'notification_type': 'chat_message',
        'conversation_id': '   ',
      });

      expect(route.kind, NotificationRouteKind.notificationsList);
    });
  });

  group('flagged comments', () {
    test('comment_flagged routes to the comment detail screen', () {
      final route = resolve(
        {
          'notification_type': 'comment_flagged',
          'comment_id': '42',
          'post_id': '9',
        },
        title: 'Comment removed',
        body: 'It broke the rules',
      );

      expect(route.kind, NotificationRouteKind.flaggedComment);
      expect(route.commentId, 42);
      expect(route.postId, 9);
      expect(route.title, 'Comment removed');
      expect(route.body, 'It broke the rules');
    });

    test('admin_notice carrying a comment_id routes to the comment', () {
      final route = resolve({
        'notification_type': 'admin_notice',
        'comment_id': '42',
      });

      expect(route.kind, NotificationRouteKind.flaggedComment);
      expect(route.commentId, 42);
    });

    // Regression: the old router did `int.tryParse(commentIdStr!)` the moment
    // the type was comment_flagged, so a payload without a comment_id threw a
    // null-check error inside the tap handler and the tap did nothing at all.
    test('comment_flagged with no comment_id degrades to the list, not a crash',
        () {
      final route = resolve({'notification_type': 'comment_flagged'});

      expect(route.kind, NotificationRouteKind.notificationsList);
    });

    test('non-numeric comment_id degrades to the list', () {
      final route = resolve({
        'notification_type': 'comment_flagged',
        'comment_id': 'not-a-number',
      });

      expect(route.kind, NotificationRouteKind.notificationsList);
    });
  });

  group('flagged posts', () {
    test('post_flagged routes to the post detail screen', () {
      final route = resolve({
        'notification_type': 'post_flagged',
        'post_id': '15',
      });

      expect(route.kind, NotificationRouteKind.flaggedPost);
      expect(route.postId, 15);
    });

    test('admin_notice with only a post_id routes to the post', () {
      final route = resolve({
        'notification_type': 'admin_notice',
        'post_id': '15',
      });

      expect(route.kind, NotificationRouteKind.flaggedPost);
      expect(route.postId, 15);
    });

    test('a comment_id wins over a post_id on the same admin notice', () {
      final route = resolve({
        'notification_type': 'admin_notice',
        'comment_id': '3',
        'post_id': '15',
      });

      expect(route.kind, NotificationRouteKind.flaggedComment);
      expect(route.commentId, 3);
      expect(route.postId, 15, reason: 'post id is still carried through');
    });

    test('post_flagged with no post_id degrades to the list', () {
      final route = resolve({'notification_type': 'post_flagged'});

      expect(route.kind, NotificationRouteKind.notificationsList);
    });
  });

  group('everything else', () {
    for (final type in ['like', 'comment', 'follow', 'follow_request']) {
      test('$type routes to the notifications list', () {
        expect(
          resolve({'notification_type': type}).kind,
          NotificationRouteKind.notificationsList,
        );
      });
    }

    test('an empty payload routes to the notifications list', () {
      expect(resolve({}).kind, NotificationRouteKind.notificationsList);
    });

    test('an unknown type routes to the notifications list', () {
      expect(
        resolve({'notification_type': 'something_new'}).kind,
        NotificationRouteKind.notificationsList,
      );
    });
  });

  group('payload parsing', () {
    // FCM stringifies data values, but a data-only message composed elsewhere
    // can hand us real ints — don't fall over on either shape.
    test('accepts numeric ids as well as strings', () {
      final route = resolve({
        'notification_type': 'post_flagged',
        'post_id': 15,
      });

      expect(route.postId, 15);
    });

    test('data-only messages fall back to title/body in the data payload', () {
      final route = resolve({
        'notification_type': 'post_flagged',
        'post_id': '1',
        'title': 'Data title',
        'body': 'Data body',
      });

      expect(route.title, 'Data title');
      expect(route.body, 'Data body');
    });

    test('the notification block wins over the data payload', () {
      final route = resolve(
        {
          'notification_type': 'post_flagged',
          'post_id': '1',
          'title': 'Data title',
        },
        title: 'Notification title',
      );

      expect(route.title, 'Notification title');
    });
  });
}
