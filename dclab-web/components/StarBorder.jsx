'use client';
// StarBorder - a twinkling star that travels the exact outline of its parent (button, pill or card),
// trailing light and stardust. Drop it inside any `position: relative` element; it reads the parent's size and radius.
import { useEffect, useRef } from 'react';
const NS = 'http://www.w3.org/2000/svg';
export default function StarBorder({ color = '#0070f3', speed = 6, dust = 7, inset = 1 }) {
  const ref = useRef(null);
  useEffect(() => {
    if (matchMedia('(prefers-reduced-motion:reduce)').matches) return;
    const svg = ref.current, host = svg.parentElement; let raf, vis = true, L = 1;
    const mk = (n, a) => { const e = document.createElementNS(NS, n); for (const k in a) e.setAttribute(k, a[k]); svg.appendChild(e); return e; };
    svg.textContent = '';
    const path = mk('path', { fill: 'none', stroke: 'none' });
    const trails = [[.24, .22], [.13, .5], [.05, .95]].map(([l, o]) => ({ l, e: mk('path', { fill: 'none', stroke: color, 'stroke-width': 1.6, 'stroke-linecap': 'round', opacity: o }) }));
    const dots = Array.from({ length: dust }, () => mk('circle', { fill: color, r: 1 }));
    const star = mk('polygon', { points: '0,-7 1.6,-1.6 7,0 1.6,1.6 0,7 -1.6,1.6 -7,0 -1.6,-1.6', fill: '#fff' });
    const build = () => {
      const w = host.offsetWidth, h = host.offsetHeight, r = Math.min(parseFloat(getComputedStyle(host).borderTopLeftRadius) || 0, w / 2, h / 2), i = inset, x1 = w - i, y1 = h - i;
      const d = `M${i + r},${i}H${x1 - r}A${r},${r} 0 0 1 ${x1},${i + r}V${y1 - r}A${r},${r} 0 0 1 ${x1 - r},${y1}H${i + r}A${r},${r} 0 0 1 ${i},${y1 - r}V${i + r}A${r},${r} 0 0 1 ${i + r},${i}Z`;
      svg.setAttribute('viewBox', `0 0 ${w} ${h}`); path.setAttribute('d', d); L = path.getTotalLength() || 1;
      trails.forEach(t => { t.e.setAttribute('d', d); t.e.setAttribute('stroke-dasharray', `${L * t.l} ${L * 2}`); });
    };
    build(); const ro = new ResizeObserver(build); ro.observe(host);
    const io = new IntersectionObserver(e => { vis = e[0].isIntersecting; }); io.observe(host);
    const t0 = performance.now(), at = d => path.getPointAtLength(((d % L) + L) % L);
    const loop = now => {
      if (vis) {
        const p = ((now - t0) / 1000 / speed % 1) * L, pt = at(p);
        trails.forEach(t => t.e.setAttribute('stroke-dashoffset', L * t.l - p));
        star.setAttribute('transform', `translate(${pt.x} ${pt.y}) rotate(${(now - t0) / 12}) scale(${.8 + .35 * Math.sin((now - t0) / 140)})`);
        dots.forEach((c, k) => { const q = at(p - (k + 1) * L * .014), j = Math.sin(k * 2.7 + now / 170) * 1.6; c.setAttribute('cx', q.x + j); c.setAttribute('cy', q.y - j); c.setAttribute('r', Math.max(.35, 1.2 - k * .12)); c.setAttribute('opacity', (1 - k / dust) * .9); });
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => { cancelAnimationFrame(raf); ro.disconnect(); io.disconnect(); };
  }, [color, speed, dust, inset]);
  return <svg ref={ref} aria-hidden="true" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', overflow: 'visible', pointerEvents: 'none', zIndex: 3, filter: `drop-shadow(0 0 5px ${color})` }} />;
}
