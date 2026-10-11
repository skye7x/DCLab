'use client';
// MetallicPaint - liquid chrome shader flowing over a text/logo mask, floated and tilted in 3D by the pointer.
// Local implementation of the idea; swap for the original with: npx shadcn@latest add @react-bits/MetallicPaint-JS-CSS
import { useEffect, useRef } from 'react';
const VS = 'attribute vec2 a;void main(){gl_Position=vec4(a,0.,1.);}';
const FS = `precision highp float;uniform sampler2D A,B;uniform vec2 R,M;uniform float T,P,F;
void main(){vec2 u=gl_FragCoord.xy/R;float m=texture2D(A,u).r;if(m<.002){gl_FragColor=vec4(0.);return;}
float e=.012;vec2 g=vec2(texture2D(B,u+vec2(e,0.)).r-texture2D(B,u-vec2(e,0.)).r,texture2D(B,u+vec2(0.,e)).r-texture2D(B,u-vec2(0.,e)).r)*2.;
float s=u.x*1.2+u.y*.9+(g.x+g.y)*F+.15*sin(u.y*6.+T*.6)+T*.07+(M.x-.5)*.5;
float st=smoothstep(.3,.7,abs(fract(s*P)-.5)*2.);vec3 c=mix(vec3(.06,.07,.09),vec3(.97,.98,1.),st);
c=mix(c,vec3(.45,.65,1.),smoothstep(.1,.9,length(g))*.4);
vec3 n=normalize(vec3(-g*1.5,1.));vec3 l=normalize(vec3((M-.5)*1.2+vec2(-.3,.5),.8));c+=pow(max(dot(n,l),0.),28.)*.5;
gl_FragColor=vec4(c*m,m);}`;
export default function MetallicPaint({ text = 'DC', patternScale = 2, refraction = .9, speed = 1 }) {
  const wrap = useRef(null), cv = useRef(null);
  useEffect(() => {
    const c = cv.current, w = wrap.current, RM = matchMedia('(prefers-reduced-motion:reduce)').matches;
    const gl = c.getContext('webgl', { alpha: true, premultipliedAlpha: true }); let raf, vis = true, dead = false, ready = false, tex = [];
    const mask = (size, blur) => { const m = document.createElement('canvas'); m.width = m.height = size; const x = m.getContext('2d');
      x.fillStyle = '#fff'; x.font = `700 ${size * .62}px ${getComputedStyle(c).fontFamily}`; x.textAlign = 'center'; x.textBaseline = 'middle'; if (blur) x.filter = `blur(${size * .035}px)`; x.fillText(text, size / 2, size * .53); return m; };
    const size = () => Math.round(c.clientWidth * Math.min(devicePixelRatio, 1.5)) || 2;
    let U, mx = .5, my = .5, tx = .5, ty = .5;
    const setup = () => {
      const S = size(); c.width = c.height = S;
      if (!gl) { const x = c.getContext('2d'), g = x.createLinearGradient(0, 0, S, S); g.addColorStop(0, '#171717'); g.addColorStop(.5, '#e8eef9'); g.addColorStop(1, '#171717'); x.clearRect(0, 0, S, S); x.drawImage(mask(S, false), 0, 0); x.globalCompositeOperation = 'source-in'; x.fillStyle = g; x.fillRect(0, 0, S, S); return; }
      if (!ready) {
        const sh = (t, s) => { const o = gl.createShader(t); gl.shaderSource(o, s); gl.compileShader(o); return o; }, p = gl.createProgram();
        gl.attachShader(p, sh(gl.VERTEX_SHADER, VS)); gl.attachShader(p, sh(gl.FRAGMENT_SHADER, FS)); gl.linkProgram(p); gl.useProgram(p);
        gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer()); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
        const a = gl.getAttribLocation(p, 'a'); gl.enableVertexAttribArray(a); gl.vertexAttribPointer(a, 2, gl.FLOAT, false, 0, 0);
        U = n => gl.getUniformLocation(p, n); gl.uniform1i(U('A'), 0); gl.uniform1i(U('B'), 1); tex = [gl.createTexture(), gl.createTexture()]; ready = true;
      }
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
      [mask(S, false), mask(S, true)].forEach((m, i) => { gl.activeTexture(gl.TEXTURE0 + i); gl.bindTexture(gl.TEXTURE_2D, tex[i]); gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, m);
        [gl.TEXTURE_MIN_FILTER, gl.TEXTURE_MAG_FILTER].forEach(k => gl.texParameteri(gl.TEXTURE_2D, k, gl.LINEAR)); [gl.TEXTURE_WRAP_S, gl.TEXTURE_WRAP_T].forEach(k => gl.texParameteri(gl.TEXTURE_2D, k, gl.CLAMP_TO_EDGE)); });
      gl.viewport(0, 0, S, S);
    };
    const draw = now => {
      if (gl && ready) { gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT); gl.uniform2f(U('R'), c.width, c.height); gl.uniform2f(U('M'), mx, 1 - my); gl.uniform1f(U('T'), now / 1000 * speed); gl.uniform1f(U('P'), patternScale); gl.uniform1f(U('F'), refraction); gl.drawArrays(gl.TRIANGLES, 0, 3); }
    };
    const loop = now => {
      if (vis) { mx += (tx - mx) * .06; my += (ty - my) * .06; draw(now);
        w.style.transform = `perspective(900px) rotateX(${(my - .5) * -14}deg) rotateY(${(mx - .5) * 18}deg) translateY(${Math.sin(now / 1400) * 10}px)`; }
      raf = requestAnimationFrame(loop);
    };
    const pm = e => { const r = w.getBoundingClientRect(); tx = Math.min(Math.max((e.clientX - r.left) / r.width, -.5), 1.5); ty = Math.min(Math.max((e.clientY - r.top) / r.height, -.5), 1.5); };
    document.fonts.ready.then(() => { if (dead) return; setup(); if (RM) draw(1500); else { addEventListener('pointermove', pm); raf = requestAnimationFrame(loop); } });
    const ro = new ResizeObserver(() => { if (ready || !gl) { setup(); if (RM) draw(1500); } }); ro.observe(c);
    const io = new IntersectionObserver(e => { vis = e[0].isIntersecting; }); io.observe(c);
    return () => { dead = true; cancelAnimationFrame(raf); removeEventListener('pointermove', pm); ro.disconnect(); io.disconnect(); };
  }, [text, patternScale, refraction, speed]);
  return <div ref={wrap} className="metal"><canvas ref={cv} aria-hidden="true" /></div>;
}
