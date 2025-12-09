const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const crypto = require('crypto');
admin.initializeApp();
console.log('Functions starting up. GCLOUD_PROJECT=', process.env.GCLOUD_PROJECT, 'admin.app().options.projectId=', admin.app().options && admin.app().options.projectId);
const REGION = 'asia-southeast2';
const MEMORY = '256MiB';

setGlobalOptions({
    region: REGION,
    memory: MEMORY,
    timeoutSeconds: 60,
});

const eventOptions = {
    region: REGION,
    memory: MEMORY,
    maxInstances: 1,
};

const requestOptions = {
    region: REGION,
    memory: MEMORY,
    timeoutSeconds: 60,
    maxInstances: 1,
    concurrency: 1,
};

const callableOptions = {
    region: REGION,
    memory: MEMORY,
    timeoutSeconds: 60,
    maxInstances: 1,
    concurrency: 1,
};

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;
const rawAdminEmails = (process.env.ADMIN_EMAILS || 'anandasubing190305@gmail.com,sulthonabdulhakim2@gmail.com,hakim123@gmail.com')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
const ADMIN_EMAILS = new Set(rawAdminEmails);

function isAdminContext(auth) {
    if (!auth) return false;
    const token = auth.token || {};
    const email = (token.email || '').trim().toLowerCase();
    if (email && ADMIN_EMAILS.has(email)) return true;
    if (token.admin === true) return true;
    if ((token.role || '').toLowerCase() === 'admin') return true;
    return false;
}

function isModeratorContext(auth) {
    if (!auth) return false;
    const token = auth.token || {};
    if (isAdminContext(auth)) return true;
    if (token.moderator === true) return true;
    if ((token.role || '').toLowerCase() === 'moderator') return true;
    return false;
}

async function assertAdmin(context) {
    if (!context.auth) {
        throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    // First check Firestore user role
    try {
        const uid = context.auth.uid;
        const snap = await db.collection('users').doc(uid).get();
        const role = (snap.exists && snap.get('role')) || '';
        if (String(role).toLowerCase() === 'admin') return context.auth;
    } catch (err) {
        console.warn('assertAdmin Firestore role check failed', err);
    }
    // Fallback: check custom claims
    if (isAdminContext(context.auth)) return context.auth;
    throw new HttpsError('permission-denied', 'Admin role required.');
}

async function assertModerator(context) {
    if (!context.auth) {
        throw new HttpsError('unauthenticated', 'Authentication is required.');
    }
    // First check Firestore user role
    try {
        const uid = context.auth.uid;
        const snap = await db.collection('users').doc(uid).get();
        const role = (snap.exists && snap.get('role')) || '';
        const v = String(role).toLowerCase();
        if (v === 'admin' || v === 'moderator') return context.auth;
    } catch (err) {
        console.warn('assertModerator Firestore role check failed', err);
    }
    // Fallback: check custom claims
    if (isModeratorContext(context.auth)) return context.auth;
    throw new HttpsError('permission-denied', 'Moderator role required.');
}

function hashPasscode(passcode) {
    return crypto.createHash('sha256').update(passcode).digest('hex');
}

async function logAudit({
    actorId,
    actorName,
    action,
    objectType,
    objectId,
    details = {},
}) {
    await db.collection('audit_logs').add({
        actorId,
        actorName,
        action,
        objectType,
        objectId,
        details,
        createdAt: FieldValue.serverTimestamp(),
    });
}

async function appendSanction({
    userId,
    type,
    reason,
    metadata = {},
    actorId,
    actorName,
    expiresAt = null,
}) {
    const payload = {
        userId,
        type,
        reason: reason || '',
        metadata,
        createdAt: FieldValue.serverTimestamp(),
        createdBy: actorId,
        createdByName: actorName,
        active: true,
    };
    if (expiresAt) {
        payload.expiresAt = Timestamp.fromDate(expiresAt);
    }
    await db.collection('users').doc(userId).collection('sanctions').add(payload);
    await db.collection('users').doc(userId).set({
        sanctionCount: FieldValue.increment(1),
        lastSanctionReason: reason || '',
    }, { merge: true });
}

async function updateCustomClaims(userId, updates) {
    const user = await admin.auth().getUser(userId);
    const claims = user.customClaims || {};
    const next = {...claims, ...updates };
    await admin.auth().setCustomUserClaims(userId, next);
}

async function getUserLabel(uid) {
    try {
        const snap = await db.collection('users').doc(uid).get();
        if (!snap.exists) return 'Admin';
        const data = snap.data() || {};
        return data.username || data.handle || data.email || 'Admin';
    } catch (error) {
        console.error('Failed to load user label', error);
        return 'Admin';
    }
}

function normalizeRole(role) {
    if (!role) return 'user';
    const value = String(role).toLowerCase();
    if (value === 'admin') return 'admin';
    if (value === 'moderator') return 'moderator';
    return 'user';
}

function pickPositiveMinutes(raw, fallback = 15) {
    const value = Number(raw);
    if (!Number.isFinite(value) || value <= 0) return fallback;
    return Math.round(value);
}

function futureFromMinutes(minutes) {
    return new Date(Date.now() + minutes * 60 * 1000);
}

async function deleteCollection(query, batchSize = 250) {
    const snapshot = await query.limit(batchSize).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    if (snapshot.size >= batchSize) {
        await deleteCollection(query, batchSize);
    }
}

async function sendToUser(uid, payload) {
    const snap = await db.collection('users').doc(uid).get();
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
        const res = await admin.messaging().sendEachForMulticast ?
            await admin.messaging().sendEachForMulticast(message) :
            await admin.messaging().sendMulticast(message);

        // Clean up invalid tokens
        try {
            const invalid = [];
            const responses = res.responses || res.successCount !== undefined ? res.responses : [];
            responses.forEach((r, i) => {
                if (!r.success) {
                    const code = r.error && (r.error.code || (r.error.errorInfo && r.error.errorInfo.code));
                    if (code && (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token'))) {
                        invalid.push(tokens[i]);
                    }
                }
            });
            if (invalid.length) {
                await db.collection('users').doc(uid).set({
                    fcmTokens: FieldValue.arrayRemove(...invalid),
                }, { merge: true });
            }
        } catch (_) {}
    }
}

exports.onChatMessageCreate = onDocumentCreated({
    ...eventOptions,
    document: 'chat_messages/{messageId}',
}, async(event) => {
    const snap = event.data;
    if (!snap) return;
    const m = snap.data();
    if (!m) return;
    const chat = await db.collection('chats').doc(m.chatId).get();
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

exports.onCommentLikeCreate = onDocumentCreated({
    ...eventOptions,
    document: 'comment_likes/{likeId}',
}, async(event) => {
    const snap = event.data;
    if (!snap) return;
    const like = snap.data();
    if (!like) return;
    const comment = await db.collection('comments').doc(like.commentId).get();
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

exports.onFollowCreate = onDocumentCreated({
    ...eventOptions,
    document: 'follows/{followId}',
}, async(event) => {
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
exports.onMentionNotificationCreate = onDocumentCreated({
    ...eventOptions,
    document: 'notifications/{notificationId}',
}, async(event) => {
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
    await db.collection('notifications').doc(snap.id).update({
        sent: true,
        sentAt: FieldValue.serverTimestamp()
    });
});

// Backfill lastSeen for all users (call this once via HTTP)
exports.backfillLastSeen = onRequest(requestOptions, async(req, res) => {
    try {
        const usersSnapshot = await db.collection('users').get();
        const batch = db.batch();
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

// Backfill usernameLower, handleLower, and searchKeywords for existing users
exports.backfillUserSearchFields = onRequest(requestOptions, async(req, res) => {
    try {
        const snap = await db.collection('users').get();
        let updated = 0;
        let batch = db.batch();
        const BATCH_SIZE = 400;

        function addTokens(set, v) {
            const n = String(v || '').trim().toLowerCase();
            if (!n) return;
            for (let i = 1; i <= n.length; i++) set.add(n.substring(0, i));
        }

        for (const doc of snap.docs) {
            const d = doc.data() || {};
            const username = String(d.username || '');
            const handleRaw = String(d.handle || '').replace(/^@/, '');
            const emailLocal = String(d.email || '').split('@')[0] || '';

            const keywords = new Set();
            addTokens(keywords, username);
            addTokens(keywords, handleRaw);
            addTokens(keywords, emailLocal);

            batch.set(doc.ref, {
                usernameLower: username.toLowerCase(),
                handleLower: handleRaw.toLowerCase(),
                searchKeywords: Array.from(keywords),
            }, { merge: true });

            updated++;
            if (updated % BATCH_SIZE === 0) {
                await batch.commit();
                batch = db.batch();
            }
        }
        await batch.commit();
        res.json({ success: true, updated });
    } catch (e) {
        console.error('backfillUserSearchFields error', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

// ---------------------------------------------------------------------------
// Admin callable functions
// ---------------------------------------------------------------------------

exports.adminSetUserRole = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { userId, role, reason } = request.data || {};
    if (!userId) {
        throw new HttpsError('invalid-argument', 'userId is required.');
    }
    const normalizedRole = normalizeRole(role);
    const userRef = db.collection('users').doc(userId);
    await userRef.set({
        role: normalizedRole,
        updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    await updateCustomClaims(userId, {
        role: normalizedRole,
        admin: normalizedRole === 'admin',
        moderator: normalizedRole === 'admin' || normalizedRole === 'moderator',
    });

    const actorName = auth.token.name || auth.token.email || 'Admin';
    await logAudit({
        actorId: auth.uid,
        actorName,
        action: 'set_role',
        objectType: 'user',
        objectId: userId,
        details: { role: normalizedRole, reason: reason || '' },
    });
    return { success: true, role: normalizedRole };
});

exports.adminMuteUser = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { userId, durationMinutes, reason, global = true } = request.data || {};
    if (!userId) throw new HttpsError('invalid-argument', 'userId is required.');
    const minutes = pickPositiveMinutes(durationMinutes, 30);
    const expiresAt = futureFromMinutes(minutes);
    const userRef = db.collection('users').doc(userId);

    await userRef.set({
        status: 'muted',
        mutedUntil: Timestamp.fromDate(expiresAt),
        lastSanctionReason: reason || 'Muted by moderator',
    }, { merge: true });

    await appendSanction({
        userId,
        type: 'mute',
        reason,
        metadata: { durationMinutes: minutes, global },
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        expiresAt,
    });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'mute_user',
        objectType: 'user',
        objectId: userId,
        details: { durationMinutes: minutes, reason: reason || '', global },
    });
    return { success: true, mutedUntil: expiresAt.getTime() };
});

exports.adminUnmuteUser = onCall(callableOptions, async(request) => {
    console.log('adminUnmuteUser request.auth =', request.auth);
    try {
        const rawAuthHeader = request && request.rawRequest && request.rawRequest.headers && request.rawRequest.headers.authorization;
        console.log('adminUnmuteUser raw authorization header =', rawAuthHeader);
    } catch (err) {
        console.warn('Could not read rawRequest headers', err);
    }

    console.log('env GCLOUD_PROJECT =', process.env.GCLOUD_PROJECT, 'admin app projectId =', admin.app().options && admin.app().options.projectId);

    const auth = await assertModerator(request);
    const { userId } = request.data || {};
    if (!userId) throw new HttpsError('invalid-argument', 'userId is required.');

    const userRef = db.collection('users').doc(userId);
    await userRef.set({
        status: 'active',
        mutedUntil: FieldValue.delete(),
        lastSanctionReason: FieldValue.delete(),
    }, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'unmute_user',
        objectType: 'user',
        objectId: userId,
        details: {},
    });

    return { success: true };
});


exports.adminBanUser = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { userId, reason, durationMinutes } = request.data || {};
    if (!userId) throw new HttpsError('invalid-argument', 'userId is required.');
    let expiresAt = null;
    if (durationMinutes) {
        expiresAt = futureFromMinutes(pickPositiveMinutes(durationMinutes, 1440));
    }

    const userRef = db.collection('users').doc(userId);
    await userRef.set({
        status: 'banned',
        bannedUntil: expiresAt ? Timestamp.fromDate(expiresAt) : FieldValue.delete(),
        lastSanctionReason: reason || 'Banned by admin',
    }, { merge: true });

    await appendSanction({
        userId,
        type: 'ban',
        reason,
        metadata: { durationMinutes: durationMinutes || null },
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        expiresAt,
    });

    await updateCustomClaims(userId, { banned: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'ban_user',
        objectType: 'user',
        objectId: userId,
        details: { reason: reason || '', durationMinutes: durationMinutes || null },
    });
    return { success: true };
});

exports.adminUnbanUser = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { userId } = request.data || {};
    if (!userId) throw new HttpsError('invalid-argument', 'userId is required.');

    const userRef = db.collection('users').doc(userId);
    await userRef.set({
        status: 'active',
        bannedUntil: FieldValue.delete(),
        lastSanctionReason: FieldValue.delete(),
    }, { merge: true });

    await updateCustomClaims(userId, { banned: false });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'unban_user',
        objectType: 'user',
        objectId: userId,
        details: {},
    });
    return { success: true };
});

exports.adminShadowBanUser = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { userId, enabled = true, reason } = request.data || {};
    if (!userId) throw new HttpsError('invalid-argument', 'userId is required.');
    await db.collection('users').doc(userId).set({
        status: enabled ? 'shadowBanned' : 'active',
        shadowBanned: enabled,
        lastSanctionReason: enabled ? (reason || 'Shadow banned') : FieldValue.delete(),
    }, { merge: true });

    await appendSanction({
        userId,
        type: 'shadowBan',
        reason,
        metadata: { enabled },
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
    });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: enabled ? 'shadow_ban_user' : 'shadow_unban_user',
        objectType: 'user',
        objectId: userId,
        details: { reason: reason || '', enabled },
    });
    return { success: true };
});

exports.adminSaveRoom = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { room } = request.data || {};
    if (!room || !room.name) {
        throw new HttpsError('invalid-argument', 'Room payload with name is required.');
    }
    let roomId = room.id;
    let docRef;
    if (roomId) {
        docRef = db.collection('rooms').doc(roomId);
    } else {
        docRef = db.collection('rooms').doc();
        roomId = docRef.id;
    }

    const payload = {
        name: room.name,
        visibility: (room.visibility || 'public').toLowerCase(),
        updatedAt: FieldValue.serverTimestamp(),
    };
    if (room.description) payload.description = room.description;
    if (room.coverUrl || room.coverImage) payload.coverUrl = room.coverUrl || room.coverImage;
    if (room.requiresPasscode === true) payload.requiresPasscode = true;
    if (Array.isArray(room.moderatorIds)) {
        payload.moderatorIds = room.moderatorIds.filter(Boolean);
    }
    if (room.stats) payload.stats = room.stats;
    if (!room.createdAt) {
        payload.createdAt = FieldValue.serverTimestamp();
    }
    if (!room.createdBy) {
        payload.createdBy = auth.uid;
    }
    if (room.passcode && String(room.passcode).trim().length >= 4) {
        payload.passcodeHash = hashPasscode(String(room.passcode).trim());
        payload.requiresPasscode = true;
    } else if (room.clearPasscode === true) {
        payload.passcodeHash = FieldValue.delete();
        payload.requiresPasscode = false;
    }

    await docRef.set(payload, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'save_room',
        objectType: 'room',
        objectId: roomId,
        details: { name: room.name, visibility: payload.visibility },
    });
    return { success: true, roomId };
});

exports.adminDeleteRoom = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { roomId } = request.data || {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId is required.');
    await deleteCollection(db.collection('room_messages').where('roomId', '==', roomId));
    await deleteCollection(db.collection('rooms').doc(roomId).collection('members'));
    await db.collection('rooms').doc(roomId).delete();

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'delete_room',
        objectType: 'room',
        objectId: roomId,
        details: {},
    });
    return { success: true };
});

exports.adminAssignRoomModerator = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { roomId, userId, add = true } = request.data || {};
    if (!roomId || !userId) {
        throw new HttpsError('invalid-argument', 'roomId and userId are required.');
    }
    const roomRef = db.collection('rooms').doc(roomId);
    await roomRef.update({
        moderatorIds: add ? FieldValue.arrayUnion(userId) : FieldValue.arrayRemove(userId),
    });
    await roomRef.collection('members').doc(userId).set({
        role: add ? 'moderator' : 'member',
    }, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: add ? 'assign_room_mod' : 'remove_room_mod',
        objectType: 'room',
        objectId: roomId,
        details: { userId },
    });
    return { success: true };
});

exports.adminMuteRoomMember = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { roomId, userId, durationMinutes, reason } = request.data || {};
    if (!roomId || !userId) throw new HttpsError('invalid-argument', 'roomId and userId are required.');
    const minutes = pickPositiveMinutes(durationMinutes, 30);
    const expiresAt = futureFromMinutes(minutes);
    const memberRef = db.collection('rooms').doc(roomId).collection('members').doc(userId);
    await memberRef.set({
        muted: true,
        mutedUntil: Timestamp.fromDate(expiresAt),
        muteReason: reason || '',
    }, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'mute_room_member',
        objectType: 'room',
        objectId: roomId,
        details: { userId, durationMinutes: minutes, reason: reason || '' },
    });
    return { success: true };
});

exports.adminKickRoomMember = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { roomId, userId, reason } = request.data || {};
    if (!roomId || !userId) throw new HttpsError('invalid-argument', 'roomId and userId are required.');
    await db.collection('rooms').doc(roomId).collection('members').doc(userId).delete();

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'kick_room_member',
        objectType: 'room',
        objectId: roomId,
        details: { userId, reason: reason || '' },
    });
    return { success: true };
});

exports.adminClearRoomMessages = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { roomId, limit = 50 } = request.data || {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId is required.');
    const batch = await db.collection('room_messages')
        .where('roomId', '==', roomId)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();
    const writeBatch = db.batch();
    batch.docs.forEach((doc) => writeBatch.update(doc.ref, { status: 'deleted', deletedBy: auth.uid, deletedAt: FieldValue.serverTimestamp() }));
    await writeBatch.commit();

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'clear_room_messages',
        objectType: 'room',
        objectId: roomId,
        details: { limit },
    });
    return { success: true, deleted: batch.size };
});

exports.adminAssignReport = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { reportId, adminId } = request.data || {};
    if (!reportId || !adminId) throw new HttpsError('invalid-argument', 'reportId and adminId are required.');
    const adminName = await getUserLabel(adminId);
    await db.collection('reports').doc(reportId).set({
        assignedAdminId: adminId,
        assignedAdminName: adminName,
        status: 'inReview',
        updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'assign_report',
        objectType: 'report',
        objectId: reportId,
        details: { adminId },
    });
    return { success: true };
});

exports.adminResolveReport = onCall(callableOptions, async(request) => {
    const auth = await assertModerator(request);
    const { reportId, status, notes, actions } = request.data || {};
    if (!reportId || !status) throw new HttpsError('invalid-argument', 'reportId and status are required.');
    const normalizedStatus = ['resolved', 'rejected', 'inReview', 'open'].includes(status) ?
        status :
        'resolved';
    await db.collection('reports').doc(reportId).set({
        status: normalizedStatus,
        resolutionNotes: notes || '',
        actions: actions || {},
        updatedAt: FieldValue.serverTimestamp(),
        handledBy: auth.uid,
        handledByName: auth.token.name || auth.token.email || 'Moderator',
    }, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Moderator',
        action: 'resolve_report',
        objectType: 'report',
        objectId: reportId,
        details: { status: normalizedStatus },
    });
    return { success: true };
});

exports.adminSaveAnnouncement = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { announcement } = request.data || {};
    if (!announcement || !announcement.title) {
        throw new HttpsError('invalid-argument', 'Announcement payload with title is required.');
    }
    let announcementId = announcement.id;
    let docRef;
    if (announcementId) {
        docRef = db.collection('announcements').doc(announcementId);
    } else {
        docRef = db.collection('announcements').doc();
        announcementId = docRef.id;
    }

    const payload = {
        title: announcement.title,
        body: announcement.body || '',
        scope: announcement.scope || 'global',
        roomIds: Array.isArray(announcement.roomIds) ? announcement.roomIds : [],
        status: announcement.status || 'draft',
        sendPush: announcement.sendPush === true,
        updatedAt: FieldValue.serverTimestamp(),
    };
    if (!announcement.createdAt) {
        payload.createdAt = FieldValue.serverTimestamp();
    }
    if (announcement.publishAt) {
        payload.publishAt = Timestamp.fromDate(new Date(announcement.publishAt));
    }

    await docRef.set(payload, { merge: true });

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'save_announcement',
        objectType: 'announcement',
        objectId: announcementId,
        details: { scope: payload.scope, status: payload.status },
    });
    return { success: true, announcementId };
});

exports.adminDeleteAnnouncement = onCall(callableOptions, async(request) => {
    const auth = await assertAdmin(request);
    const { announcementId } = request.data || {};
    if (!announcementId) throw new HttpsError('invalid-argument', 'announcementId is required.');
    await db.collection('announcements').doc(announcementId).delete();

    await logAudit({
        actorId: auth.uid,
        actorName: auth.token.name || auth.token.email || 'Admin',
        action: 'delete_announcement',
        objectType: 'announcement',
        objectId: announcementId,
        details: {},
    });
    return { success: true };
});
