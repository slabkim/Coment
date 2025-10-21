const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
admin.initializeApp();
setGlobalOptions({ region: 'us-central1', memoryMiB: 256, timeoutSeconds: 60 });

async function sendToUser(uid, payload) {
  const snap = await admin.firestore().collection('users').doc(uid).get();
  if (!snap.exists) return;
  const tokensSet = new Set();
  const single = snap.get('fcmToken');
  const multi = snap.get('fcmTokens');
  if (single && typeof single === 'string') tokensSet.add(single);
  if (Array.isArray(multi)) multi.filter(Boolean).forEach((t) => tokensSet.add(String(t)));
  const tokens = Array.from(tokensSet);
  if (tokens.length === 0) return;

  const message = {
    tokens,
    notification: payload.notification,
    data: payload.data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: 'chat_channel',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
  };

  // Use multicast for multiple tokens; fall back to single if only one
  if (tokens.length === 1) {
    await admin.messaging().send({
      token: tokens[0],
      notification: message.notification,
      data: message.data,
      android: message.android,
    });
  } else {
    const res = await admin.messaging().sendEachForMulticast
      ? await admin.messaging().sendEachForMulticast(message)
      : await admin.messaging().sendMulticast(message);

    // Clean up invalid tokens
    try {
      const invalid = [];
      const responses = res.responses || res.successCount !== undefined ? res.responses : [];
      responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error && (r.error.code || r.error.errorInfo?.code);
          if (code && (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token'))) {
            invalid.push(tokens[i]);
          }
        }
      });
      if (invalid.length) {
        await admin.firestore().collection('users').doc(uid).set({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalid),
        }, { merge: true });
      }
    } catch (_) {}
  }
}

exports.onChatMessageCreate = onDocumentCreated('chat_messages/{messageId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const m = snap.data();
  if (!m) return;
  const chat = await admin.firestore().collection('chats').doc(m.chatId).get();
  if (!chat.exists) return;
  const participants = chat.get('participants') || [];
  const senderName = chat.get('lastMessageSenderName') || 'Someone';
  const body = m.text ? m.text : (m.imageUrl ? 'Sent an image' : 'New message');
  const targets = participants.filter((p) => p !== m.senderId);
  await Promise.all(targets.map((uid) => sendToUser(uid, {
    notification: { title: `Pesan baru dari ${senderName}`, body },
    data: { type: 'dm', chatId: m.chatId, senderId: m.senderId, senderName },
  })));
});

exports.onCommentLikeCreate = onDocumentCreated('comment_likes/{likeId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const like = snap.data();
  if (!like) return;
  const comment = await admin.firestore().collection('comments').doc(like.commentId).get();
  if (!comment.exists) return;
  const owner = comment.get('userId');
  if (!owner || owner === like.userId) return;
  await sendToUser(owner, {
    notification: { title: 'Someone liked your comment', body: 'Tap to view' },
    data: { type: 'like', commentId: comment.id }
  });
});

exports.onFollowCreate = onDocumentCreated('follows/{followId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const f = snap.data();
  if (!f) return;
  const target = f.followingId;
  if (!target || target === f.followerId) return;
  await sendToUser(target, {
    notification: { title: 'New follower', body: 'You have a new follower' },
    data: { type: 'follow', followerId: f.followerId }
  });
});


