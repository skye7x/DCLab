'use client';
// Liquid glass - approximation of React Bits GlassSurface: SVG displacement-map refraction (Chromium), blur fallback elsewhere.
import { useEffect, useId, useRef } from 'react';
const NS = 'http://www.w3.org/2000/svg';
export default function Glass({ as: T = 'div', className = '', children, ...p }) {
  const el = useRef(null), sv = useRef(null), id = 'gf' + useId().replace(/\W/g, '');
  useEffect(() => {
    const e = el.current, s = sv.current, ua = navigator.userAgent;
    if (!/Chrome|Edg/.test(ua) || /OPR|Firefox/.test(ua)) return;
    const up = () => {
      const r = e.getBoundingClientRect(), w = Math.round(r.width) || 2, h = Math.round(r.height) || 2;
      const rad = parseFloat(getComputedStyle(e).borderTopLeftRadius) || h / 2, b = Math.min(w, h) * .06;
      const map = `<svg xmlns="${NS}" viewBox="0 0 ${w} ${h}"><defs><linearGradient id="r" x1="100%" y1="0" x2="0" y2="0"><stop offset="0" stop-color="#0000"/><stop offset="1" stop-color="red"/></linearGradient><linearGradient id="b" x1="0" y1="0" x2="0" y2="100%"><stop offset="0" stop-color="#0000"/><stop offset="1" stop-color="blue"/></linearGradient></defs><rect width="${w}" height="${h}" fill="#000"/><rect width="${w}" height="${h}" rx="${rad}" fill="url(#r)"/><rect width="${w}" height="${h}" rx="${rad}" fill="url(#b)" style="mix-blend-mode:difference"/><rect x="${b}" y="${b}" width="${w - 2 * b}" height="${h - 2 * b}" rx="${rad}" fill="hsl(0 0% 50% / .93)" style="filter:blur(${Math.min(11, b)}px)"/></svg>`;
      const ch = (sc, m, o) => `<feDisplacementMap in="SourceGraphic" in2="m" scale="${sc}" xChannelSelector="R" yChannelSelector="G"/><feColorMatrix values="${m}" result="${o}"/>`;
      s.innerHTML = `<defs><filter id="${id}" color-interpolation-filters="sRGB" x="0" y="0" width="100%" height="100%"><feImage x="0" y="0" width="${w}" height="${h}" preserveAspectRatio="none" result="m" href="data:image/svg+xml,${encodeURIComponent(map)}"/>${ch(-70, '1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0', 'R')}${ch(-80, '0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0', 'G')}${ch(-90, '0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0', 'B')}<feBlend in="R" in2="G" mode="screen" result="RG"/><feBlend in="RG" in2="B" mode="screen"/><feGaussianBlur stdDeviation=".6"/></filter></defs>`;
      e.style.backdropFilter = `url(#${id}) blur(6px) saturate(1.7) brightness(1.04)`;
    };
    up(); let t; const ro = new ResizeObserver(() => { clearTimeout(t); t = setTimeout(up, 120); }); ro.observe(e);
    return () => { ro.disconnect(); clearTimeout(t); };
  }, [id]);
  return <T ref={el} className={`glass ${className}`} {...p}><svg ref={sv} aria-hidden="true" style={{ position: 'absolute', width: 0, height: 0, pointerEvents: 'none' }} />{children}</T>;
}
