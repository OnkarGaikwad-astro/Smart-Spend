import React from 'react';

// Recreated Original 'S' with 3D Glassmorphism
export const LogoOriginal3D = ({ className = '', size = 100 }: { className?: string; size?: number | string }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" className={className}>
    <defs>
      {/* Background Box Gradient */}
      <linearGradient id="bgGlass" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#447A9C" stopOpacity="0.85"/>
        <stop offset="100%" stopColor="#2A4B61" stopOpacity="0.95"/>
      </linearGradient>
      
      {/* Top Hook Gradient (Glassy) */}
      <linearGradient id="topHook" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#95BEE8" stopOpacity="0.95"/>
        <stop offset="100%" stopColor="#7DA2C8" stopOpacity="0.8"/>
      </linearGradient>
      
      {/* Bottom Hook Gradient (Glassy) */}
      <linearGradient id="bottomHook" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#AED8F7" stopOpacity="0.95"/>
        <stop offset="100%" stopColor="#8DBEDE" stopOpacity="0.8"/>
      </linearGradient>

      {/* Drop Shadow for 3D effect */}
      <filter id="shadow3d" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="2" dy="5" stdDeviation="4" floodColor="#0B1115" floodOpacity="0.5"/>
      </filter>
      
      {/* Box Drop Shadow */}
      <filter id="boxShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="8" stdDeviation="8" floodColor="#2A4B61" floodOpacity="0.3"/>
      </filter>
    </defs>

    {/* Glassy Background Square */}
    <rect x="5" y="5" width="90" height="90" rx="28" fill="url(#bgGlass)" filter="url(#boxShadow)" />
    {/* White Glowing Border */}
    <rect x="5" y="5" width="90" height="90" rx="28" fill="none" stroke="rgba(255,255,255,0.25)" strokeWidth="1.5" />

    {/* 3D "S" Shape */}
    <g filter="url(#shadow3d)">
      {/* Top Hook */}
      <path d="M 65,42 L 35,42 A 16,16 0 0,1 35,10 L 65,10" fill="none" stroke="url(#topHook)" strokeWidth="14" strokeLinecap="round" />
      {/* Top Hook Glass Highlight */}
      <path d="M 65,42 L 35,42 A 16,16 0 0,1 35,10 L 65,10" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" transform="translate(0, -2)" />

      {/* Bottom Hook */}
      <path d="M 35,58 L 65,58 A 16,16 0 0,1 65,90 L 35,90" fill="none" stroke="url(#bottomHook)" strokeWidth="14" strokeLinecap="round" />
      {/* Bottom Hook Glass Highlight */}
      <path d="M 35,58 L 65,58 A 16,16 0 0,1 65,90 L 35,90" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" transform="translate(0, -2)" />
    </g>
  </svg>
);

// Option: The Spark (4 Curves)
export const LogoSpark = ({ className = '', size = 40 }: { className?: string; size?: number | string }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M 50,15 Q 50,50 15,50" fill="none" stroke="#447A9C" strokeWidth="12" strokeLinecap="round"/>
    <path d="M 85,50 Q 50,50 50,15" fill="none" stroke="#8DBEDE" strokeWidth="12" strokeLinecap="round"/>
    <path d="M 50,85 Q 50,50 85,50" fill="none" stroke="#447A9C" strokeWidth="12" strokeLinecap="round"/>
    <path d="M 15,50 Q 50,50 50,85" fill="none" stroke="#8DBEDE" strokeWidth="12" strokeLinecap="round"/>
  </svg>
);

// Option: The Surge (3 Curves)
export const LogoSurge = ({ className = '', size = 40 }: { className?: string; size?: number | string }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M 15,85 A 70,70 0 0,1 85,15" fill="none" stroke="#447A9C" strokeWidth="14" strokeLinecap="round"/>
    <path d="M 40,85 A 45,45 0 0,1 85,40" fill="none" stroke="#8DBEDE" strokeWidth="14" strokeLinecap="round"/>
    <path d="M 65,85 A 20,20 0 0,1 85,65" fill="none" stroke="#447A9C" strokeWidth="14" strokeLinecap="round" strokeOpacity="0.6"/>
  </svg>
);

// Option: The Prism (3 Lines)
export const LogoPrism = ({ className = '', size = 40 }: { className?: string; size?: number | string }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" className={className}>
    <line x1="55" y1="20" x2="80" y2="65" stroke="#447A9C" strokeWidth="14" strokeLinecap="round"/>
    <line x1="75" y1="75" x2="25" y2="75" stroke="#8DBEDE" strokeWidth="14" strokeLinecap="round"/>
    <line x1="20" y1="65" x2="45" y2="20" stroke="#447A9C" strokeWidth="14" strokeLinecap="round"/>
  </svg>
);

// Option: The Nexus (2 Curves)
export const LogoNexus = ({ className = '', size = 40 }: { className?: string; size?: number | string }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M 20,65 Q 50,10 80,65" fill="none" stroke="#447A9C" strokeWidth="16" strokeLinecap="round"/>
    <path d="M 20,35 Q 50,90 80,35" fill="none" stroke="#8DBEDE" strokeWidth="16" strokeLinecap="round"/>
  </svg>
);
