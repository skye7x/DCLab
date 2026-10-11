import Hero from '../components/Hero';
import Glass from '../components/Glass';
import Veil from '../components/Veil';
import Fx from '../components/Fx';
import Terminal from '../components/Terminal';
import GradualBlur from '../components/GradualBlur';
import StarBorder from '../components/StarBorder';
import MetallicPaint from '../components/MetallicPaint';

const GH = 'https://github.com/skye7x/DCLab';
const R = ({ as: T = 'div', d = 0, className = '', ...p }) => <T className={`rv ${className}`} style={{ '--d': d + 's' }} {...p} />;

const TAGS = ['VLAN-aware pathfinding', 'NAT', 'DNS', 'DHCP', 'FTP', 'SSH', 'Load balancer', 'Reverse proxy', 'VPN tunnel', 'IDS', 'Packet capture', 'iperf', 'Static routes', 'ARP', 'Certificates / HTTPS', 'NAS backup'];
const STEPS = [
  ['01', 'Place', 'Drag routers, switches, firewalls, computers, servers and storage onto the canvas. Auto-layout tidies the topology when it gets busy.'],
  ['02', 'Connect', 'Draw links between devices, then tune each one: bandwidth, latency and packet loss. Congestion is tracked as traffic builds.'],
  ['03', 'Simulate', 'Double-click any machine for a terminal. Run traceroute, query DNS, SSH across the lab and see how the network responds.'],
];
const FEATURES = [
  { big: '70+', chips: ['Multi-tab', 'Aliases', 'Env vars'], h: 'Terminal commands.', p: 'Independent sessions per tab, cron, journalctl and tail, all inside the sim.' },
  { chips: ['DNS', 'FTP', 'Email', 'DHCP', 'Web'], h: 'Services that answer back.', p: 'Run your own DNS and query it with nslookup or dig. Host a site with the website builder and edit its content in-game.' },
  { chips: ['Load balancer'], h: 'Build the architecture.', p: 'Put a load balancer in front of web servers, add a reverse proxy, then back it all up to storage.' },
];
const DEVICES = [
  ['Router', 'Routes between networks with static routes, NAT masquerade and a configurable WAN interface.', ['NAT', 'Static routes', 'ARP']],
  ['Switch', 'Connects segments and understands VLANs, so path-finding respects how you segmented the network.', ['VLAN', 'Links', 'Congestion']],
  ['Firewall', 'Filter traffic and test your rules before they matter, with an IDS device to watch for trouble.', ['Rule tester', 'IDS']],
  ['Computer', 'A full terminal per machine: aliases, environment variables, SSH, scheduled tasks and process control.', ['Terminal', 'SSH', 'Cron']],
  ['Server', 'Host DNS, FTP, email, websites and load-balanced services, protected with certificates and HTTPS.', ['DNS', 'FTP', 'Email', 'HTTPS']],
  ['Storage', 'Keep data on NAS-style storage and practise backups as part of the topology.', ['NAS', 'Backup']],
];
const DRILLS = [
  ['Link outage drill', 'Pull a cable on purpose and watch traffic reroute, or fail to.'],
  ['Time-based events', 'Schedule events so the lab changes while you work, like a real shift.'],
  ['Lab scenarios', 'Guided setups for focused practice instead of an empty canvas.'],
  ['Project templates', 'Start from a ready topology, then save, export a PNG or generate a report.'],
];
const FAQ = [
  ['Is DCLab free and open source?', 'Yes. The source is public on GitHub under AGPL-3.0.'],
  ['What do I need to run it?', 'DCLab is a Godot 4.7.2 project. Open it in the Godot editor and run it, or export a desktop application through Project → Export.'],
  ['Who is it for?', 'Students, self-taught sysadmins and anyone who wants to experiment with IT infrastructure without buying hardware or risking a production network.'],
  ['Can I keep and share my work?', 'Topologies can be exported as PNG, and the sim can produce a report. Project templates help you start fast and reuse good designs.'],
  ['How do I get around the canvas?', 'Drag devices to place them, double-click to open a terminal, right-click for configuration, and use Ctrl+T / Ctrl+W to open and close terminal tabs. A minimap helps in large labs.'],
  ['Can I contribute?', 'Absolutely. Issues and pull requests are welcome on the GitHub repository.'],
];

export default function Page() {
  return (
    <>
      <a className="skip" href="#features">Skip to content</a>
      <Glass as="header" className="nav">
        <a className="logo" href="#top" aria-label="DCLab home">
          <img src="/icon.svg" alt="" width="24" height="24" style={{ verticalAlign: 'middle', marginRight: 6 }} />
          DCLab
        </a>
        <nav aria-label="Primary"><a className="l" href="#how">How it works</a><a className="l" href="#features">Features</a><a className="l" href="#devices">Devices</a><a className="l" href="#terminal">Terminal</a><a className="l" href="#faq">FAQ</a></nav>
        <Glass as="a" className="btn p sm" href={GH}>GitHub <b aria-hidden="true">→</b><StarBorder color="#9ecbff" speed={7} /></Glass>
      </Glass>
      <Fx />
      {/* Page-level gradual blur: content melts under the glass nav and out of the bottom edge */}
      <GradualBlur target="page" position="top" height="6rem" strength={1.6} divCount={4} curve="bezier" zIndex={-60} />
      <GradualBlur target="page" position="bottom" height="5rem" strength={1.4} divCount={4} curve="bezier" zIndex={-60} />
      <main>
        <Hero />
        <div className="marq" aria-hidden="true"><div>{[...TAGS, ...TAGS].map((t, i) => <span key={i}>{t}</span>)}</div></div>

        <section><div className="wrap intro">
          <R as="p" className="statement">Learning infrastructure shouldn’t need a rack in your garage. <em>DCLab is a whole data centre on a canvas</em>: draw it, break it, fix it, and understand why.</R>
          <MetallicPaint text="DC" />
        </div></section>

        <section id="how" style={{ paddingTop: 0 }}><div className="wrap">
          <R as="p" className="eye">How it works</R>
          <R as="h2" d={.05}>Three moves from empty canvas<br />to working network.</R>
          <div className="steps">{STEPS.map(([n, h, p], i) => <R key={n} d={i * .1}><span className="mono">{n}</span><h3>{h}</h3><p>{p}</p></R>)}</div>
        </div></section>

        <section id="features" style={{ paddingTop: 0 }}><div className="wrap">
          <R as="p" className="eye">50+ features</R>
          <R as="h2" d={.05}>Everything a small data centre does.<br />None of the hardware.</R>
          <div className="bento">{FEATURES.map((f, i) => (
            <R as="article" key={f.h} d={(i % 3) * .08} className={`card tilt ${f.c || ''}`}>
              <div className="chips">{f.chips.map(c => <span key={c}>{c}</span>)}</div>
              {f.star && <StarBorder color="#0070f3" speed={9} />}
              {f.big && <div className="big">{f.big}</div>}
              <h3>{f.h}</h3><p>{f.p}</p>
            </R>))}</div>
        </div></section>

        <section id="devices" style={{ paddingTop: 0 }}><div className="wrap">
          <R as="p" className="eye">The device lineup</R>
          <R as="h2" d={.05}>Six kinds of machines.<br />Each one behaves like its real counterpart.</R>
          <div className="devlist">{DEVICES.map(([n, p, ch], i) => (
            <R key={n} className="dev"><span className="mono">0{i + 1}</span><h3>{n}</h3><div><p>{p}</p><div className="chips" style={{ margin: 0 }}>{ch.map(c => <span key={c}>{c}</span>)}</div></div></R>))}</div>
        </div></section>

        <section id="terminal" style={{ paddingTop: 0 }}><div className="wrap split">
          <div>
            <R as="p" className="eye">Hands-on</R>
            <R as="h2" d={.05}>Double-click a device.<br />You’re in.</R>
            <R as="p" d={.1} style={{ maxWidth: 440 }}>Every machine has its own shell with independent multi-tab sessions. SSH between devices, query your DNS, trace routes and read logs, all against the topology you drew.</R>
            <R className="cmds" d={.15} aria-label="Sample commands">{['traceroute', 'nslookup', 'dig', 'ssh', 'apt', 'journalctl', 'tail', 'iperf', 'alias', 'groups', 'email'].map(c => <code key={c}>{c}</code>)}</R>
            <R className="keys" d={.2} aria-label="Controls"><kbd>Ctrl + T</kbd><kbd>Ctrl + W</kbd><kbd>Double-click</kbd><kbd>Right-click</kbd></R>
          </div>
          <Terminal />
        </div></section>

        <section style={{ paddingTop: 0 }}><div className="wrap">
          <R className="stats">
            <div><div className="big" data-n="50" data-s="+">50+</div><small>Features</small></div>
            <div><div className="big" data-n="70" data-s="+">70+</div><small>Terminal commands</small></div>
            <div><div className="big" data-n="22">22</div><small>Verified network-layer features</small></div>
            <div><div className="big" data-n="6">6</div><small>Device types</small></div>
          </R>
        </div></section>

        <section style={{ paddingTop: 0 }}><div className="wrap">
          <R as="p" className="eye">Practice</R>
          <R as="h2" d={.05}>Break things on purpose.</R>
          <div className="drills">{DRILLS.map(([h, p], i) => <R as="article" key={h} d={(i % 2) * .08} className="card tilt"><span className="mono">0{i + 1}</span><h3>{h}</h3><p>{p}</p></R>)}</div>
        </div></section>

        <section id="faq" style={{ paddingTop: 0 }}><div className="wrap">
          <R as="p" className="eye">FAQ</R>
          <R as="h2" d={.05}>Good questions.</R>
          <R className="faq" d={.1}>{FAQ.map(([q, a]) => <details key={q}><summary>{q}</summary><p>{a}</p></details>)}</R>
        </div></section>

        <section className="end">
          <Veil strength={.9} />
          <div className="wrap">
            <R as="p" className="eye">Open source · AGPL-3.0</R>
            <R as="h2" d={.05}>Build the network before it breaks.</R>
            <R className="cta" d={.1} style={{ justifyContent: 'center' }}><Glass as="a" className="btn p mag" href={GH}>Get DCLab on GitHub <b aria-hidden="true">→</b><StarBorder color="#9ecbff" speed={7} /></Glass></R>
            <R as="p" d={.15} style={{ marginTop: 26, font: '400 13px var(--mono)', color: 'var(--mute)' }}>Run from the Godot 4.7.2 editor, or export as a desktop app via Project → Export.</R>
          </div>
        </section>
      </main>
      <footer><div className="wrap">
        <div><span className="logo"><img src="/icon.svg" alt="" width="20" height="20" style={{ verticalAlign: 'middle', marginRight: 6 }} />DCLab</span><p>IT infrastructure simulator.<br />Made with Godot.</p></div>
        <div><b>Project</b><a href={GH}>GitHub</a><a href={`${GH}/issues`}>Issues</a><a href={`${GH}/pulls`}>Pull requests</a></div>
        <div><b>Explore</b><a href="#how">How it works</a><a href="#features">Features</a><a href="#devices">Devices</a></div>
        <div><b>Legal</b><a href={`${GH}/blob/main/LICENSE`}>AGPL-3.0</a><span>© skye7x</span></div>
      </div></footer>
    </>
  );
}
