'use client';
import dynamic from 'next/dynamic';
import Veil from './Veil';
import ParticleText from './ParticleText';
import Glass from './Glass';
import StarBorder from './StarBorder';
export default function Hero() {
  return (
    <section className="hero" id="top">
      <Veil strength={1.15} />
      <div className="wrap hero-in" id="hin">
        <p className="eye rv">IT infrastructure simulator</p>
        <h1 className="sr">DCLab</h1>
        <ParticleText text="DCLab" />
        <p className="lead rv" style={{ '--d': '.15s' }}>Place routers, switches, firewalls and servers on a canvas. Wire them together. Then open a terminal and watch a real network come alive.</p>
        <div className="cta rv" style={{ '--d': '.3s' }}>
          <Glass as="a" className="btn p mag" href="https://github.com/skye7x/DCLab">View on GitHub <b aria-hidden="true">→</b><StarBorder color="#9ecbff" speed={6} /></Glass>
          <Glass as="a" className="btn mag" href="#features">Explore features</Glass>
        </div>
        <p className="meta rv" style={{ '--d': '.45s' }}><span>Godot 4.7.2</span><span>GDScript</span><span>AGPL-3.0</span><span>50+ features</span></p>
      </div>
      <div className="cue" aria-hidden="true">Scroll</div>
    </section>
  );
}
