const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
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

  // Ensure all data values are strings (required for Android intent extras)
  const stringifiedData = {};
  if (payload.data) {
    Object.keys(payload.data).forEach(key => {
      stringifiedData[key] = String(payload.data[key] || '');
    });
  }

  // HYBRID: Send both notification + data payload
  // - notification: shown by system when app terminated
  // - data: used for navigation when tapped (must be strings)
  const message = {
    tokens,
    notification: payload.notification,
    data: stringifiedData,
    android: {
      priority: 'high',
      notification: {
        channelId: 'chat_channel',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        tag: stringifiedData.chatId || stringifiedData.forumId || 'default',
        // Pass data to notification intent extras
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          'mutable-content': 1,
        },
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
      apns: message.apns,
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
  
  // Determine message body based on content
  let body;
  if (m.text) {
    body = m.text;
  } else if (m.imageUrl) {
    // Check if it's a GIF (Giphy URLs contain 'giphy')
    const isGif = m.imageUrl.includes('giphy') || m.imageUrl.includes('.gif');
    body = isGif ? 'Sent a GIF 🎬' : 'Sent an image 📷';
  } else {
    body = 'New message';
  }
  
  const targets = participants.filter((p) => p !== m.senderId);
  await Promise.all(targets.map((uid) => sendToUser(uid, {
    notification: { title: `Pesan baru dari ${senderName}`, body },
    data: { type: 'dm', chatId: m.chatId, senderId: m.senderId, senderName },
    tag: m.chatId, // Group notifications by chat
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
  
  // Get titleId (itemId) from comment for navigation
  const titleId = comment.get('titleId') || '';
  
  await sendToUser(owner, {
    notification: { title: 'Someone liked your comment', body: 'Tap to view' },
    data: { 
      type: 'like', 
      commentId: comment.id,
      itemId: titleId // Include itemId for navigation to detail screen
    }
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

// New: Mention notification in forum
exports.onMentionNotificationCreate = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const notif = snap.data();
  if (!notif) return;
  
  // Only handle mention type notifications
  if (notif.type !== 'mention') return;
  
  const recipientUid = notif.recipientUid;
  const senderName = notif.senderName || 'Someone';
  const forumName = notif.forumName || 'a forum';
  const message = notif.message || '';
  const forumId = notif.forumId;
  
  if (!recipientUid) return;
  
  // Send FCM notification
  await sendToUser(recipientUid, {
    notification: { 
      title: `${senderName} mentioned you in ${forumName}`, 
      body: message 
    },
    data: { 
      type: 'mention', 
      forumId: forumId,
      senderUid: notif.senderUid,
      senderName: senderName,
      forumName: forumName
    }
  });
  
  // Mark notification as sent
  await admin.firestore().collection('notifications').doc(snap.id).update({
    sent: true,
    sentAt: admin.firestore.FieldValue.serverTimestamp()
  });
});

// Backfill lastSeen for all users (call this once via HTTP)
exports.backfillLastSeen = onRequest(async (req, res) => {
  try {
    const usersSnapshot = await admin.firestore().collection('users').get();
    const batch = admin.firestore().batch();
    const now = Date.now();
    let count = 0;

    usersSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      // Only update if lastSeen doesn't exist
      if (!data.lastSeen) {
        batch.set(doc.ref, { lastSeen: now }, { merge: true });
        count++;
      }
    });

    if (count > 0) {
      await batch.commit();
    }

    res.json({ 
      success: true, 
      message: `Updated ${count} users with lastSeen field`,
      timestamp: now
    });
  } catch (error) {
    console.error('Error backfilling lastSeen:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});
