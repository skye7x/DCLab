'use client';
// DitherVeil - WebGL ordered (Bayer) dither over flowing noise, reacts to pointer.
import { useEffect, useRef } from 'react';
const FS = `precision mediump float;uniform vec2 R,M;uniform float T,D,S;
float m2(vec2 p){p=mod(floor(p),2.);return mod(p.x*2.+p.y*3.,4.);}float bay(vec2 p){return (4.*m2(p)+m2(p*.5))/16.;}
void main(){vec2 u=gl_FragCoord.xy/R;vec2 q=u*vec2(R.x/R.y,1.)*2.2;float t=T*.12;
float v=sin(q.x*1.3+t*2.)+sin(q.y*1.7-t*1.4)+sin((q.x+q.y)*1.1+t)+sin(length(q-vec2(1.6,.9))*3.-t*3.);v=.5+v*.125;
float md=smoothstep(.45,0.,distance(u,M));float f=smoothstep(0.,.9,1.-u.y*.9)*(.4+.6*smoothstep(.2,1.,u.x));
float lv=clamp(v*f*S+md*.35,0.,1.);float d=step(bay(gl_FragCoord.xy/3.),lv);
vec3 c=mix(vec3(0.,.44,.95),vec3(.55,.3,.85),u.x+v*.3);if(D>.5)c=mix(c,vec3(1.),.35);gl_FragColor=vec4(c,d*.42);}`;
export default function Veil({ strength = 1 }) {
  const ref = useRef(null);
  useEffect(() => {
    const cv = ref.current, gl = cv.getContext('webgl', { alpha: true, premultipliedAlpha: false }); if (!gl) return;
    const RM = matchMedia('(prefers-reduced-motion:reduce)').matches, mq = matchMedia('(prefers-color-scheme:dark)');
    const sh = (t, s) => { const o = gl.createShader(t); gl.shaderSource(o, s); gl.compileShader(o); return o; }, p = gl.createProgram();
    gl.attachShader(p, sh(gl.VERTEX_SHADER, 'attribute vec2 a;void main(){gl_Position=vec4(a,0,1);}')); gl.attachShader(p, sh(gl.FRAGMENT_SHADER, FS)); gl.linkProgram(p); gl.useProgram(p);
    gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer()); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
    const a = gl.getAttribLocation(p, 'a'); gl.enableVertexAttribArray(a); gl.vertexAttribPointer(a, 2, gl.FLOAT, false, 0, 0);
    gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    const U = n => gl.getUniformLocation(p, n); let m = [.7, .5], vis = true, raf;
    const io = new IntersectionObserver(e => { vis = e[0].isIntersecting; }); io.observe(cv);
    const mv = e => { const r = cv.getBoundingClientRect(); m = [(e.clientX - r.left) / r.width, 1 - (e.clientY - r.top) / r.height]; }; addEventListener('pointermove', mv);
    const draw = t => {
      if (vis || !t) {
        const d = Math.min(devicePixelRatio, 1.5), w = cv.clientWidth * d | 0, h = cv.clientHeight * d | 0;
        if (cv.width !== w || cv.height !== h) { cv.width = w; cv.height = h; }
        gl.viewport(0, 0, w, h); gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT);
        gl.uniform2f(U('R'), w, h); gl.uniform2f(U('M'), m[0], m[1]); gl.uniform1f(U('T'), t / 1000); gl.uniform1f(U('D'), mq.matches ? 1 : 0); gl.uniform1f(U('S'), strength);
      }
      if (!RM) raf = requestAnimationFrame(draw);
    };
    draw(0); const rs = () => draw(0); if (RM) addEventListener('resize', rs);
    return () => { cancelAnimationFrame(raf); io.disconnect(); removeEventListener('pointermove', mv); removeEventListener('resize', rs); };
  }, [strength]);
  return <canvas ref={ref} className="bg" aria-hidden="true" />;
}
