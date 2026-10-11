'use client';
// ParticleText - canvas particles that spring home and scatter away from the pointer. Real text lives in an sr-only <h1>.
import { useEffect, useRef } from 'react';
export default function ParticleText({ text = 'DCLab' }) {
  const ref = useRef(null);
  useEffect(() => {
    const cv = ref.current, x = cv.getContext('2d'), dpr = Math.min(devicePixelRatio, 2), RM = matchMedia('(prefers-reduced-motion:reduce)').matches;
    let P = [], m = { x: -1e4, y: -1e4 }, col = '#171717', vis = true, raf, dead = false;
    const build = () => {
      const r = cv.getBoundingClientRect(); cv.width = r.width * dpr; cv.height = r.height * dpr;
      const o = document.createElement('canvas'); o.width = cv.width; o.height = cv.height; const c = o.getContext('2d');
      const ff = getComputedStyle(cv).fontFamily; let fs = o.height * .98; const f = () => { c.font = `600 ${fs}px ${ff}`; }; f();
      const tw = c.measureText(text).width; if (tw > o.width * .98) { fs *= o.width * .98 / tw; f(); }
      c.textBaseline = 'middle'; c.fillText(text, 0, o.height / 2);
      const g = Math.max(3, Math.round(3.4 * dpr)), d = c.getImageData(0, 0, o.width, o.height).data; P = [];
      for (let y = 0; y < o.height; y += g) for (let i = 0; i < o.width; i += g) if (d[(y * o.width + i) * 4 + 3] > 140)
        P.push({ ox: i, oy: y, x: RM ? i : i + (Math.random() - .5) * 500 * dpr, y: RM ? y : y + (Math.random() - .5) * 300 * dpr, vx: 0, vy: 0 });
      col = getComputedStyle(document.documentElement).getPropertyValue('--ink').trim() || '#171717';
    };
    const R = 120 * dpr, s = Math.max(1.7, 1.9 * dpr);
    const loop = () => {
      if (vis) {
        x.clearRect(0, 0, cv.width, cv.height); x.fillStyle = col;
        for (const p of P) {
          if (!RM) {
            const dx = p.x - m.x, dy = p.y - m.y, d = Math.hypot(dx, dy);
            if (d < R) { const f = (1 - d / R) * 5; p.vx += dx / d * f; p.vy += dy / d * f; }
            p.vx += (p.ox - p.x) * .055; p.vy += (p.oy - p.y) * .055; p.vx *= .86; p.vy *= .86; p.x += p.vx; p.y += p.vy;
          }
          x.fillRect(p.x, p.y, s, s);
        }
      }
      if (!RM) raf = requestAnimationFrame(loop);
    };
    document.fonts.ready.then(() => { if (dead) return; build(); loop(); });
    const ro = new ResizeObserver(() => { if (P.length) { build(); if (RM) loop(); } }); ro.observe(cv);
    const io = new IntersectionObserver(e => { vis = e[0].isIntersecting; }); io.observe(cv);
    const mv = e => { const r = cv.getBoundingClientRect(); m.x = (e.clientX - r.left) * dpr; m.y = (e.clientY - r.top) * dpr; }; addEventListener('pointermove', mv);
    return () => { dead = true; cancelAnimationFrame(raf); ro.disconnect(); io.disconnect(); removeEventListener('pointermove', mv); };
  }, [text]);
  return <canvas ref={ref} id="pt" aria-hidden="true" />;
}
