// Device pictograms. Shapes come from tools/pictograms.json (shared with the Godot app),
// so the site and the simulator always show the same icons.
import { SHAPES } from './pictogramShapes';

const path = (p) => 'M' + p.reduce((a, v, i) => a + (i % 2 ? ' ' : i ? 'L' : '') + v, '');

function Op({ o }) {
  switch (o.t) {
    case 'rrect': return <rect className="s f" x={o.x} y={o.y} width={o.w} height={o.h} rx={o.r} />;
    case 'frect': return <rect className="f" x={o.x} y={o.y} width={o.w} height={o.h} />;
    case 'circle': return <circle className="s f" cx={o.c[0]} cy={o.c[1]} r={o.r} />;
    case 'ellipse': return <ellipse className="s f" cx={o.c[0]} cy={o.c[1]} rx={o.rx} ry={o.ry} />;
    case 'arc': return <path className="s" d={`M${o.c[0] - o.rx} ${o.c[1]}A${o.rx} ${o.ry} 0 0 0 ${o.c[0] + o.rx} ${o.c[1]}`} />;
    case 'line':
    case 'poly': return <path className="s" d={path(o.p)} />;
    case 'dot': return <circle className="dot" cx={o.c[0]} cy={o.c[1]} r={o.r} />;
    default: return null;
  }
}

export default function Pictogram({ type, size = 44, label }) {
  const ops = SHAPES[type] || SHAPES.generic;
  return (
    <svg className="pg" width={size} height={size} viewBox="0 0 24 24" {...(label ? { role: 'img', 'aria-label': label } : { 'aria-hidden': true })}>
      {ops.map((o, i) => <Op key={i} o={o} />)}
    </svg>
  );
}
