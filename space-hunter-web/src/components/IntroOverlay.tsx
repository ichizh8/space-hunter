'use client';

import { useState } from 'react';
import { useSaveStore } from '../store/saveStore';

// HAL narrates the intro — each slide is HAL speaking directly to the player
const SLIDES = [
  {
    label: 'INITIALIZATION',
    body: 'Good morning.\n\nI am HAL. I manage this vessel and its operations. You are a hunter. Together, we will survive the void.\n\nI will explain what you need to know.',
  },
  {
    label: 'MISSION PROTOCOL',
    body: 'The process is simple.\n\n1. I will present contracts on the mission board\n2. You hunt — eliminate void creatures, collect biological samples\n3. Return to the ship\n4. I will synthesize ingredients into reputation\n5. Reputation unlocks new weapons and kit modules\n\nRepeat. Improve. Survive.',
  },
  {
    label: 'VOID CONTAMINATION',
    body: 'Everything in the void corrupts biological tissue. Including yours.\n\nLow corruption grants precision — clean, efficient combat.\nHigh corruption grants power — chaotic, volatile, dangerous.\n\nI do not recommend either path. I simply observe which one you choose.',
  },
  {
    label: 'KIT SYSTEMS',
    body: 'You carry two kit modules per mission. I have pre-loaded Stim Pack and Flash Trap.\n\nKits evolve through three tiers. At Tier 3, you choose a path — Clean or Void.\n\nCommit to your choice. The system penalizes indecision.',
  },
  {
    label: 'READY',
    body: 'Your first contract is waiting on the mission board.\n\nI will be monitoring your progress. I always am.\n\nGood luck. You will need it.',
  },
];

export function IntroOverlay() {
  const [index, setIndex] = useState(0);
  const markIntroSeen = useSaveStore(s => s.markIntroSeen);
  const slide = SLIDES[index];
  const isLast = index === SLIDES.length - 1;

  const close = () => markIntroSeen();
  const next = () => isLast ? close() : setIndex(i => i + 1);

  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center" style={{ background: 'rgba(2,2,4,0.97)' }}>
      <div className="w-[90%] max-h-[85%] flex flex-col gap-4 p-5"
        style={{ background: 'rgba(8,8,14,0.95)', border: '1px solid var(--color-hal-dim)' }}>

        {/* Progress segments */}
        <div className="flex gap-1 justify-center">
          {SLIDES.map((_, i) => (
            <div key={i} className="h-[2px] flex-1 transition-all" style={{
              background: i <= index ? 'var(--color-hal-red)' : 'var(--color-border)',
              opacity: i <= index ? 0.8 : 0.3,
            }} />
          ))}
        </div>

        {/* HAL eye */}
        <div className="flex justify-center mt-2">
          <div className="w-10 h-10 rounded-full border border-[var(--color-hal-red)] flex items-center justify-center hal-pulse"
            style={{ boxShadow: '0 0 25px rgba(255,51,0,0.25), inset 0 0 10px rgba(255,51,0,0.15)' }}>
            <div className="w-4 h-4 rounded-full bg-[var(--color-hal-red)]" style={{ boxShadow: '0 0 12px rgba(255,51,0,0.7)' }} />
          </div>
        </div>

        {/* Label */}
        <p className="text-center text-[10px] tracking-[3px] text-[var(--color-hal-dim)] uppercase">{slide.label}</p>

        {/* Body — HAL speaking */}
        <div className="flex-1 overflow-y-auto">
          <p className="text-[13px] text-[var(--color-text-primary)] leading-6 whitespace-pre-line">{slide.body}</p>
        </div>

        {/* Buttons */}
        <div className="flex gap-3 justify-center mt-2">
          <button className="pixel-btn pixel-btn-ghost min-w-[100px] text-[11px]" onClick={close}>
            {isLast ? 'CLOSE' : 'SKIP'}
          </button>
          <button
            className="pixel-btn pixel-btn-primary min-w-[140px] text-[12px]"
            onClick={next}
          >
            {isLast ? 'BEGIN' : 'CONTINUE'}
          </button>
        </div>
      </div>
    </div>
  );
}
