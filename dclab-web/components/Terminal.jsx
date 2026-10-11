'use client';
import { useEffect, useRef, useState } from 'react';
const SESSIONS = {
  Network: [['k', '$ traceroute web-01'], ['o', '1  core-router    0.4 ms\n2  sw-access-02   0.9 ms\n3  web-01         1.3 ms'], ['k', '$ iperf -c db-01'], ['o', 'Bandwidth test across 2 hops\nLink utilisation tracked live']],
  Services: [['k', '$ nslookup intranet.lab'], ['o', 'Server:  dns-01\nAddress: 10.0.1.53'], ['k', '$ apt install nginx'], ['o', 'Simulated APT: package installed']],
  Access: [['k', '$ ssh admin@db-01'], ['o', 'Connected to db-01'], ['k', '$ journalctl'], ['o', 'Reading system log on db-01']],
};
export default function Terminal() {
  const [tab, setTab] = useState('Network'), [out, setOut] = useState([]), [seen, setSeen] = useState(false), box = useRef(null);
  useEffect(() => { const io = new IntersectionObserver(([e]) => { if (e.isIntersecting) { setSeen(true); io.disconnect(); } }, { threshold: .4 }); io.observe(box.current); return () => io.disconnect(); }, []);
  useEffect(() => {
    if (!seen) return; const lines = SESSIONS[tab]; let dead = false; const wait = ms => new Promise(r => setTimeout(r, ms));
    if (matchMedia('(prefers-reduced-motion:reduce)').matches) { setOut(lines.map(([t, s]) => ({ t, s }))); return; }
    (async () => {
      setOut([]);
      for (let i = 0; i < lines.length && !dead; i++) {
        const [t, s] = lines[i];
        if (t === 'k') { for (let c = 1; c <= s.length && !dead; c++) { setOut(o => [...o.slice(0, i), { t, s: s.slice(0, c), cur: true }]); await wait(34); } setOut(o => [...o.slice(0, i), { t, s }]); }
        else setOut(o => [...o.slice(0, i), { t, s }]);
        await wait(t === 'k' ? 260 : 420);
      }
    })();
    return () => { dead = true; };
  }, [tab, seen]);
  return (
    <div className="term rv tilt" ref={box}>
      <header><i /><i /><i /><div className="tabs" role="tablist" aria-label="Example sessions">{Object.keys(SESSIONS).map(k => <button key={k} role="tab" aria-selected={tab === k} onClick={() => setTab(k)}>{k}</button>)}</div></header>
      <pre aria-hidden="true">{out.map((l, i) => <span key={i} className={`${l.t}${l.cur ? ' c' : ''}`}>{l.s + '\n'}</span>)}</pre>
      <p className="sr">Illustrative session. {SESSIONS[tab].map(([, s]) => s).join(' ')}</p>
    </div>
  );
}
