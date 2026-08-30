// mwk-genie debug log sink — debug.matewishkey.com.
//
// A ONE-WAY DROP BOX. Anyone running the kit with debug mode on can POST a log; nobody
// can read one back without the token. That asymmetry is the entire design:
//
//   POST /r        open, so a client can turn debug mode on and just say "it's sent"
//                  without anyone reading a token down a phone line
//   GET  /         token only — the list
//   GET  /r/<id>   token only — one run
//
// Why open writing is acceptable here and not in general: nothing is ever served back to
// the public, so a spammer gets no audience and no data. The guards below are about not
// paying for someone's fun, not about secrecy.
//
// What it keeps: text, 30 days, then it expires itself. A debugging aid that accumulates
// forever becomes a thing to worry about.
const MAX = 512 * 1024;
const TTL = 60 * 60 * 24 * 30;
const RATE = 20;                    // posts per IP per hour
const RATE_WINDOW = 60 * 60;

const txt = (s, m) => new Response(m + "\n", { status: s, headers: { "content-type": "text/plain; charset=utf-8" } });

function canRead(req, env) {
  const h = req.headers.get("authorization") || "";
  const got = h.startsWith("Bearer ") ? h.slice(7) : new URL(req.url).searchParams.get("k") || "";
  const want = env.MWK_DEBUG_TOKEN || "";
  if (!want || got.length !== want.length) return false;
  let d = 0;
  for (let i = 0; i < want.length; i++) d |= got.charCodeAt(i) ^ want.charCodeAt(i);
  return d === 0;                   // full-length compare, never short-circuit on byte one
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);

    if (req.method === "POST" && url.pathname === "/r") {
      const body = await req.text();
      if (body.length > MAX) return txt(413, "too big");
      // Shape check: cheap, and it turns a drive-by curl into a 400 without a KV write.
      if (!body.startsWith("=== mwk ")) return txt(400, "not a mwk log");

      const ip = req.headers.get("cf-connecting-ip") || "0";
      const rk = "rl:" + ip;
      const n = parseInt((await env.LOGS.get(rk)) || "0", 10);
      if (n >= RATE) return txt(429, "slow down");
      await env.LOGS.put(rk, String(n + 1), { expirationTtl: RATE_WINDOW });

      // The id is built here, not taken from the caller, so nothing can overwrite an
      // existing run or write outside the keyspace.
      const host = (body.match(/^host {6}(.+)$/m)?.[1] || "unknown")
        .toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 24) || "unknown";
      const now = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 13);
      const rnd = Math.random().toString(36).slice(2, 6).toUpperCase();
      const id = `${now}-${host}-${rnd}`;

      await env.LOGS.put("log:" + id, body, {
        expirationTtl: TTL,
        metadata: { at: new Date().toISOString(), bytes: body.length, host },
      });
      // The code goes back in the body so the person can read it out to whoever is helping.
      return txt(201, id);
    }

    if (!canRead(req, env)) return txt(401, "no");

    if (req.method === "GET" && url.pathname.startsWith("/r/")) {
      const v = await env.LOGS.get("log:" + url.pathname.slice(3));
      return v === null ? txt(404, "no such run")
        : new Response(v, { headers: { "content-type": "text/plain; charset=utf-8" } });
    }

    if (req.method === "GET" && url.pathname === "/") {
      const list = await env.LOGS.list({ prefix: "log:", limit: 200 });
      const rows = list.keys
        .map(k => ({ n: k.name.slice(4), at: k.metadata?.at || "", h: k.metadata?.host || "", b: k.metadata?.bytes ?? "" }))
        .sort((a, b) => (b.at > a.at ? 1 : -1))
        .map(r => `${r.at}  ${String(r.b).padStart(7)}  ${r.h.padEnd(18)}  ${r.n}`)
        .join("\n");
      return txt(200, rows || "nothing here yet");
    }

    return txt(404, "no");
  },
};
