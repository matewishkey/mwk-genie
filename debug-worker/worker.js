// mwk-genie debug log sink. Cloudflare Worker on debug.matewishkey.com.
//
// WHY THIS EXISTS: the kit is tested on a Mac and on Windows, and copying a terminal
// window back to the machine where the code lives is miserable and lossy. Runs in debug
// mode post their own log here instead.
//
// WHO CAN USE IT: whoever holds the token. There is no open write path — a guest running
// the kit has no token, so nothing they do reaches this Worker. That is the whole privacy
// story, and it is enforced here rather than by the client choosing to stay quiet.
//
// WHAT IT KEEPS: text, for 30 days, then it expires itself. Logs are a debugging aid, not
// a record, and an endpoint that accumulates forever becomes something to worry about.
const MAX = 512 * 1024;           // a terminal log that is bigger than this is a bug report
const TTL = 60 * 60 * 24 * 30;

const bad = (s, m) => new Response(m + "\n", { status: s, headers: { "content-type": "text/plain" } });

function authed(req, env) {
  const h = req.headers.get("authorization") || "";
  const t = h.startsWith("Bearer ") ? h.slice(7) : new URL(req.url).searchParams.get("k") || "";
  // Constant-time-ish: compare full length, never short-circuit on the first byte.
  const want = env.MWK_DEBUG_TOKEN || "";
  if (!want || t.length !== want.length) return false;
  let d = 0;
  for (let i = 0; i < want.length; i++) d |= t.charCodeAt(i) ^ want.charCodeAt(i);
  return d === 0;
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (!authed(req, env)) return bad(401, "no");

    // POST /r/<id> — store one run
    if (req.method === "POST" && url.pathname.startsWith("/r/")) {
      const id = url.pathname.slice(3).replace(/[^A-Za-z0-9._-]/g, "");
      if (!id) return bad(400, "bad id");
      const body = await req.text();
      if (body.length > MAX) return bad(413, "too big");
      await env.LOGS.put(id, body, {
        expirationTtl: TTL,
        metadata: { at: new Date().toISOString(), bytes: body.length },
      });
      return new Response("ok\n", { status: 201, headers: { "content-type": "text/plain" } });
    }

    // GET /r/<id> — read one back
    if (req.method === "GET" && url.pathname.startsWith("/r/")) {
      const v = await env.LOGS.get(url.pathname.slice(3));
      return v === null ? bad(404, "no such run")
        : new Response(v, { headers: { "content-type": "text/plain; charset=utf-8" } });
    }

    // GET / — what is here, newest first
    if (req.method === "GET" && url.pathname === "/") {
      const list = await env.LOGS.list({ limit: 100 });
      const rows = list.keys
        .map(k => ({ n: k.name, at: k.metadata?.at || "", b: k.metadata?.bytes ?? "" }))
        .sort((a, b) => (b.at > a.at ? 1 : -1))
        .map(r => `${r.at}  ${String(r.b).padStart(8)}  ${r.n}`)
        .join("\n");
      return new Response((rows || "nothing here yet") + "\n",
        { headers: { "content-type": "text/plain; charset=utf-8" } });
    }

    return bad(404, "no");
  },
};
