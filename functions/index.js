const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

async function sendToUser(uid, payload) {
  const snap = await admin.firestore().collection('users').doc(uid).get();
  const token = snap.exists ? snap.get('fcmToken') : null;
  if (!token) return;
  await admin.messaging().send({ token, notification: payload.notification, data: payload.data || {} });
}

exports.onChatMessageCreate = functions.firestore
  .document('chat_messages/{messageId}')
  .onCreate(async (snap, context) => {
    const m = snap.data();
    if (!m) return;
    const chat = await admin.firestore().collection('chats').doc(m.chatId).get();
    if (!chat.exists) return;
    const participants = chat.get('participants') || [];
    const targets = participants.filter((p) => p !== m.senderId);
    await Promise.all(targets.map((uid) => sendToUser(uid, {
      notification: { title: 'New message', body: m.text ? m.text : 'Sent an image' },
      data: { type: 'dm', chatId: m.chatId }
    })));
  });

exports.onCommentLikeCreate = functions.firestore
  .document('comment_likes/{likeId}')
  .onCreate(async (snap, context) => {
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

exports.onFollowCreate = functions.firestore
  .document('follows/{followId}')
  .onCreate(async (snap, context) => {
    const f = snap.data();
    if (!f) return;
    const target = f.followingId;
    if (!target || target === f.followerId) return;
    await sendToUser(target, {
      notification: { title: 'New follower', body: 'You have a new follower' },
      data: { type: 'follow', followerId: f.followerId }
    });
  });


