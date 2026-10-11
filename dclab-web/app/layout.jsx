import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';
const sans = Geist({ subsets: ['latin'], variable: '--sans', display: 'swap' });
const mono = Geist_Mono({ subsets: ['latin'], variable: '--mono', display: 'swap' });
export const metadata = {
  title: 'DCLab - IT Infrastructure Simulator',
  description: 'Place routers, switches, firewalls and servers, wire them together, and run a working network with a real terminal. Open source, built in Godot.',
  openGraph: { title: 'DCLab', description: 'IT infrastructure simulator built in Godot.', type: 'website' },
};
export const viewport = { viewportFit: 'cover', themeColor: [{ media: '(prefers-color-scheme: light)', color: '#fafafa' }, { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' }] };
export default function RootLayout({ children }) {
  return <html lang="en" className={`${sans.variable} ${mono.variable}`}><body>{children}</body></html>;
}
