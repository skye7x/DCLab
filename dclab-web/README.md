# DCLab landing page (Next.js, App Router)
npm install && npm run dev  → http://localhost:3000
Copy `icon.svg` from the DCLab repo into /public if you want a favicon (app/icon.svg works too).
Glass = React Bits GlassSurface approach, DitherVeil + ParticleText = vanilla ports (components/). No Tailwind needed.

## React Bits pieces
- GradualBlur: components/GradualBlur.jsx (+ .css) is the official source, no extra dependency needed (it doesn't import mathjs).
- MetallicPaint, StarBorder: local implementations of the effect. To use the originals:
  npx shadcn@latest add @react-bits/MetallicPaint-JS-CSS @react-bits/StarBorder-JS-CSS
  (props differ: StarBorder upstream wraps its children; ours is an overlay placed inside any position:relative parent)
