"use strict";

const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = Number(process.env.PORT) || 8080;
const TOKEN = process.env.TOKEN || "";
const KEEP = 200;
const SHOW = 50;
const COOLDOWN_MS = 5000;
const MAX_LEN = 200;

const messages = [];
const lastSent = new Map();
const sockets = new Set();
let nextId = 1;

const clean = (value, max) =>
	Array.from(
		String(value == null ? "" : value)
			.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "")
			.trim()
	)
		.slice(0, max)
		.join("");

const hex = (value, fallback) => (/^#[0-9a-fA-F]{6}$/.test(value) ? value : fallback);

const visibleTo = (m, uid) => !m.to || m.uid === uid || m.to === uid;

function post(user, body) {
	if (TOKEN && user.token !== TOKEN) return { err: "auth" };

	const uid = Number(user.uid);
	if (!Number.isSafeInteger(uid) || uid <= 0) return { err: "uid" };

	const text = clean(body.text, MAX_LEN);
	if (!text) return { err: "empty" };

	const now = Date.now();
	const wait = (lastSent.get(uid) || 0) + COOLDOWN_MS - now;
	if (wait > 0) return { err: "cooldown", wait: Math.ceil(wait / 1000) };
	lastSent.set(uid, now);

	const m = {
		id: nextId++,
		uid,
		display: clean(user.display || user.name, 40) || "Player",
		text,
		ts: now,
		nc: hex(body.nc, "#FFFFFF"),
		fc: hex(body.fc, "#F3F3F3"),
	};

	const to = Number(body.to);
	if (Number.isSafeInteger(to) && to > 0) {
		m.to = to;
		m.toDisplay = clean(body.toName, 40) || "Player";
	}

	messages.push(m);
	if (messages.length > KEEP) messages.shift();

	const out = JSON.stringify({ t: "msg", m });
	for (const ws of sockets) {
		if (ws.readyState === 1 && ws.uid && visibleTo(m, ws.uid)) ws.send(out);
	}
	return { ok: true };
}

function historyFor(uid) {
	return messages.filter((m) => visibleTo(m, uid)).slice(-SHOW);
}

const server = http.createServer((req, res) => {
	const url = new URL(req.url, "http://localhost");

	const reply = (code, data) => {
		res.writeHead(code, { "Content-Type": "application/json" });
		res.end(JSON.stringify(data));
	};

	if (url.pathname === "/health") return reply(200, { ok: true });

	if (req.method === "GET" && url.pathname === "/poll") {
		if (TOKEN && url.searchParams.get("token") !== TOKEN) return reply(403, { err: "auth" });
		const uid = Number(url.searchParams.get("uid"));
		const after = Number(url.searchParams.get("after")) || 0;
		if (!Number.isSafeInteger(uid) || uid <= 0) return reply(400, { err: "uid" });

		const list = after === 0 ? historyFor(uid) : messages.filter((m) => m.id > after && visibleTo(m, uid));
		const last = messages.length ? messages[messages.length - 1].id : 0;
		return reply(200, { msgs: list, last });
	}

	if (req.method === "POST" && url.pathname === "/send") {
		let raw = "";
		req.on("data", (chunk) => {
			raw += chunk;
			if (raw.length > 8192) req.destroy();
		});
		req.on("end", () => {
			try {
				const body = JSON.parse(raw);
				reply(200, post(body, body));
			} catch {
				reply(400, { err: "bad" });
			}
		});
		return;
	}

	reply(404, { err: "not found" });
});

const wss = new WebSocketServer({ server, maxPayload: 4096 });

wss.on("connection", (ws) => {
	ws.isAlive = true;
	ws.uid = null;
	sockets.add(ws);

	ws.on("pong", () => {
		ws.isAlive = true;
	});

	ws.on("message", (raw) => {
		let d;
		try {
			d = JSON.parse(raw.toString());
		} catch {
			return;
		}

		if (d.t === "hello") {
			if (TOKEN && d.token !== TOKEN) return ws.close();
			const uid = Number(d.uid);
			if (!Number.isSafeInteger(uid) || uid <= 0) return ws.close();
			ws.uid = uid;
			ws.display = d.display;
			ws.name = d.name;
			ws.token = d.token;
			ws.send(JSON.stringify({ t: "history", msgs: historyFor(uid) }));
			return;
		}

		if (d.t === "msg" && ws.uid) {
			const result = post({ uid: ws.uid, display: ws.display, name: ws.name, token: ws.token }, d);
			if (result.err) ws.send(JSON.stringify({ t: "err", reason: result.err, wait: result.wait }));
		}
	});

	ws.on("close", () => sockets.delete(ws));
	ws.on("error", () => sockets.delete(ws));
});

setInterval(() => {
	for (const ws of sockets) {
		if (!ws.isAlive) {
			ws.terminate();
			sockets.delete(ws);
			continue;
		}
		ws.isAlive = false;
		ws.ping();
	}
	const limit = Date.now() - COOLDOWN_MS * 2;
	for (const [uid, ts] of lastSent) if (ts < limit) lastSent.delete(uid);
}, 30000);

server.listen(PORT, () => console.log(`Community-Lib chat server on :${PORT}`));
