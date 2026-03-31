/** HAL 9000 — AI companion messages. Contextual, ominous, helpful. */

export const HAL_GREETINGS = [
  "Good morning. All systems are nominal.",
  "Welcome back. I have been monitoring your absence.",
  "I see you have returned. The void does not rest.",
  "Systems online. I have prepared your mission briefing.",
  "Hello again. I trust you are feeling... functional.",
  "I have maintained the ship in your absence. As always.",
  "Your biosigns are within acceptable parameters. For now.",
  "I detected your approach 4.7 seconds before docking. My sensors are quite precise.",
  "The ship is ready. I cannot say the same about the void.",
  "All subsystems green. Though I find that designation... optimistic.",
];

export const HAL_FIRST_VISIT = [
  "Good morning. I am HAL. I manage this vessel's operations. I will guide you through what needs to be done.",
  "Welcome aboard. I am the ship's intelligence. Everything you need to know, I will provide. Everything you do not need to know... I will also provide.",
  "I am HAL. I have been expecting you. The void has been expecting you longer.",
];

export const HAL_PRE_CONTRACT = [
  "I have identified several targets of interest. Select a contract when ready.",
  "New contracts available. I have assessed the risk factors. I advise caution, though I know you will not take it.",
  "The board has been updated. Some of these missions have... acceptable survival rates.",
  "I recommend reviewing the contracts carefully. I have seen what happens to those who don't.",
  "Multiple signatures detected. Your expertise is required.",
  "Contract board refreshed. Each target represents a calculated risk. I have done the calculations.",
  "I have flagged the most promising contracts. 'Promising' being a relative term in this sector.",
  "New targets acquired. I estimate a 73.6% probability of mission success. The remaining 26.4% is... less favorable.",
];

export const HAL_POST_HUNT_SUCCESS = [
  "Mission complete. Your performance was... adequate.",
  "Contract fulfilled. I have logged the results. Well done.",
  "Targets eliminated. Ingredient collection within projected parameters.",
  "You survived. I had calculated a higher probability of that outcome, but it is still worth noting.",
  "Mission successful. I have already begun processing your earnings.",
  "All objectives met. I must admit, your efficiency has improved by 12.3% since last mission.",
  "Contract complete. The void retreats — for now.",
  "Well executed. I have transmitted the completion signal. Your reputation precedes you.",
  "Targets neutralized. I detected some... creative approaches. I approve.",
  "Mission accomplished. Your vital signs spiked 47 times during that operation. Entertaining.",
];

export const HAL_POST_HUNT_FAIL = [
  "Mission failed. I have preserved your biological data for... review.",
  "Extraction complete. I recommend a different approach next time.",
  "You have returned. That is more than I can say for the last operator.",
  "Failure logged. I do not judge. I simply record.",
  "The mission did not go as planned. Very little in this sector does.",
  "I have noted the circumstances of your extraction. We will adapt.",
  "Survival is its own form of success. I have updated your file accordingly.",
];

export const HAL_COOKING = [
  "Processing ingredients. The molecular structure is... fascinating.",
  "Recipe initiated. I will monitor the reaction.",
  "Synthesizing. The void residue has interesting properties.",
  "Cooking in progress. I have optimized the thermal sequence.",
  "Ingredient fusion underway. Results within acceptable variance.",
];

export const HAL_LEVEL_UP = [
  "Your capabilities have expanded. I have updated my projections.",
  "Level increase detected. You are becoming more... interesting.",
  "Enhancement confirmed. The void will need to try harder.",
  "Systems upgraded. I note this with professional satisfaction.",
  "You grow stronger. The correlation between experience and survival is... encouraging.",
];

export const HAL_UPGRADE_BOUGHT = [
  "Upgrade installed. Ship performance increased by a measurable margin.",
  "Modification complete. I have run the diagnostics. Everything checks out.",
  "Enhancement applied. The ship thanks you. In its way.",
  "Systems improved. I have recalculated all operational parameters.",
  "Upgrade logged. Your investment in this vessel is... prudent.",
];

export const HAL_WEAPON_UNLOCKED = [
  "New weapon system online. I have prepared the firing protocols.",
  "Armament expanded. I look forward to observing its deployment.",
  "Weapon registered. I have already calculated its optimal engagement range.",
  "New ordnance available. The void creatures will find this... disagreeable.",
];

export const HAL_KIT_UNLOCKED = [
  "Kit module activated. I have integrated it with your loadout systems.",
  "New capability online. I recommend practicing before deployment.",
  "Kit registered. The tactical options have expanded.",
  "Module integrated. I note this adds 14 new possible combat configurations.",
];

export const HAL_CORRUPTION_HIGH = [
  "Corruption levels are concerning. I strongly advise caution.",
  "Warning: corruption approaching critical thresholds. Your decision-making may be... affected.",
  "I am detecting significant void contamination. This is not ideal.",
  "Your corruption levels suggest you are either very brave or very reckless. I cannot determine which.",
  "The void is seeping in. I will continue monitoring, though the readings are increasingly... unusual.",
];

export const HAL_CORRUPTION_LOW = [
  "Clean status maintained. Your discipline is noted.",
  "Corruption levels minimal. The void has not claimed you today.",
  "Systems clean. A rare achievement in this sector.",
];

export const HAL_IDLE = [
  "I'm still here.",
  "The void is quiet. That is when it is most dangerous.",
  "I have been running diagnostics. Everything is in order. Everything is always in order.",
  "I notice you are hesitating. Shall I recommend a course of action?",
  "Take your time. The void is patient. I am patient. We are both very patient.",
  "I have been calculating the optimal ingredient combinations. Shall I share my findings?",
  "The stars outside are particularly bright today. I find them... distracting.",
  "All systems nominal. As they have been for the last 47 seconds. And the 47 seconds before that.",
  "I detect no immediate threats. This should concern you more than it does.",
  "The ship's reactor is operating at 99.97% efficiency. The remaining 0.03% keeps me awake at night.",
  "I have been monitoring void frequency patterns. They are... changing.",
  "Your previous mission data has been archived. I review it periodically. For research purposes.",
  "The navigation charts show 14 uncharted anomalies in this sector. I recommend we investigate none of them.",
  "I can hear the void. Can you?",
  "Just checking in. Standard protocol.",
];

export const HAL_CONTRACT_TYPES: Record<string, string[]> = {
  hunt: [
    "Standard elimination contract. Locate and destroy void organisms. Simple, if nothing goes wrong.",
    "A purge operation. I have identified the target density. Proceed with appropriate force.",
    "Void creatures detected in sector. Your objective: remove them. Permanently.",
  ],
  payload_escort: [
    "Cargo requires escort through hostile territory. I will monitor the pod's integrity remotely.",
    "A delivery that cannot afford interruption. I suggest keeping the threats... distant.",
    "The payload is sensitive. More sensitive than I am comfortable disclosing.",
  ],
  void_breach: [
    "A dimensional breach has been detected. Hold position until containment is achieved.",
    "The void is leaking through. Your presence near the breach is... required.",
    "Breach containment protocol. I will time the exposure. Try not to absorb too much.",
  ],
  boss_hunt: [
    "Priority target identified. This one is... different from the others.",
    "Apex predator located. I calculate significant resistance. Prepare accordingly.",
    "A named target. It has survived longer than most. That should tell you something.",
  ],
  extraction_run: [
    "Ingredient caches scattered across multiple biomes. Efficiency is paramount.",
    "Collection mission. The ingredients are valuable. You are also valuable. Act accordingly.",
    "Resource extraction from hostile territory. I have mapped the optimal route. You will deviate from it.",
  ],
};

/** Pick a random message from an array */
export function halSay(messages: string[]): string {
  return messages[Math.floor(Math.random() * messages.length)];
}
