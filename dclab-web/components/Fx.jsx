'use client';
// Scroll reveals, hero exit, card tilt, magnetic buttons, count-up stats.
import { useEffect } from 'react';
export default function Fx() {
  useEffect(() => {
    const $$ = s => [...document.querySelectorAll(s)], RM = matchMedia('(prefers-reduced-motion:reduce)').matches, un = [];
    const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: .12, rootMargin: '0px 0px -6% 0px' });
    $$('.rv').forEach(e => io.observe(e)); un.push(() => io.disconnect());
    const hin = document.getElementById('hin');
    if (!RM && hin) { const f = () => { const p = Math.min(scrollY / innerHeight, 1); hin.style.transform = `translateY(${p * 70}px) scale(${1 - p * .05})`; hin.style.opacity = 1 - p * 1.15; }; addEventListener('scroll', f, { passive: true }); un.push(() => removeEventListener('scroll', f)); }
    if (!RM && matchMedia('(hover:hover)').matches) {
      $$('.tilt').forEach(c => {
        c.onpointermove = e => { const r = c.getBoundingClientRect(), x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height; c.style.setProperty('--mx', x * 100 + '%'); c.style.setProperty('--my', y * 100 + '%'); c.style.transform = `perspective(900px) rotateX(${(.5 - y) * 5}deg) rotateY(${(x - .5) * 7}deg) translateY(-3px)`; };
        c.onpointerleave = () => { c.style.transform = ''; };
      });
      $$('.mag').forEach(b => {
        b.onpointermove = e => { const r = b.getBoundingClientRect(); b.style.transform = `translate(${(e.clientX - r.left - r.width / 2) * .18}px,${(e.clientY - r.top - r.height / 2) * .28}px)`; };
        b.onpointerleave = () => { b.style.transform = ''; };
      });
    }
    const st = document.querySelector('.stats');
    const so = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return; so.disconnect();
      $$('[data-n]').forEach(el => { const n = +el.dataset.n, s = el.dataset.s || '', t0 = performance.now();
        const f = t => { const k = Math.min((t - t0) / 1400, 1); el.textContent = Math.round(n * (1 - (1 - k) ** 4)) + (k === 1 ? s : ''); if (k < 1) requestAnimationFrame(f); };
        RM ? (el.textContent = n + s) : requestAnimationFrame(f); });
    }, { threshold: .4 });
    if (st) so.observe(st); un.push(() => so.disconnect());
    return () => un.forEach(f => f());
  }, []);
  return null;
}
