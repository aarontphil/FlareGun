/**
 * DisasterKnowledge — Comprehensive offline knowledge base for disaster situations.
 * All data is stored in-memory — zero network dependency.
 */

const KNOWLEDGE_BASE = {
    first_aid: {
        label: '🩹 First Aid',
        icon: '🩹',
        topics: {
            cpr: {
                title: 'CPR (Cardiopulmonary Resuscitation)',
                keywords: ['cpr', 'heart stopped', 'not breathing', 'cardiac arrest', 'chest compressions', 'resuscitation'],
                steps: [
                    'Check the scene for safety before approaching',
                    'Tap the person\'s shoulder and shout "Are you okay?"',
                    'If unresponsive, call for help from nearby people',
                    'Place the person on their back on a firm surface',
                    'Place the heel of one hand on the center of the chest (between the nipples)',
                    'Place your other hand on top, interlace fingers',
                    'Push hard and fast — at least 2 inches deep, 100-120 compressions per minute',
                    'After 30 compressions, tilt head back, lift chin, give 2 rescue breaths',
                    'Continue 30:2 cycle until help arrives or the person starts breathing',
                    'If an AED is available, follow its voice prompts immediately',
                ],
                tips: 'Push hard — don\'t be afraid of breaking ribs. A rib will heal; death won\'t. Use the beat of "Stayin\' Alive" for compression rhythm.',
            },
            bleeding: {
                title: 'Severe Bleeding Control',
                keywords: ['bleeding', 'blood', 'wound', 'cut', 'hemorrhage', 'laceration', 'gash'],
                steps: [
                    'Put on gloves or use a barrier (plastic bag) if available',
                    'Apply direct pressure with a clean cloth or bandage',
                    'Press firmly and do NOT remove the cloth — add more on top if blood soaks through',
                    'If wound is on a limb, elevate it above the heart level',
                    'For severe limb bleeding: apply a tourniquet 2-3 inches above the wound',
                    'Tighten the tourniquet until bleeding stops — note the time applied',
                    'Keep the person calm, warm, and lying down',
                    'Do NOT remove embedded objects — stabilize them in place',
                    'Monitor for signs of shock: pale skin, rapid pulse, confusion',
                ],
                tips: 'A tourniquet should be a LAST RESORT for life-threatening limb bleeding. Once applied, do not remove it — wait for medical professionals.',
            },
            burns: {
                title: 'Burn Treatment',
                keywords: ['burn', 'burns', 'scalded', 'fire burn', 'hot water', 'thermal'],
                steps: [
                    'Remove the person from the heat source immediately',
                    'Cool the burn with cool (not cold) running water for at least 10 minutes',
                    'Remove jewelry, watches, or tight items near the burn before swelling',
                    'Do NOT apply ice, butter, toothpaste, or oils',
                    'Do NOT pop blisters — they protect against infection',
                    'Cover with a sterile non-stick bandage or clean cloth',
                    'For chemical burns: flush with large amounts of water for 20+ minutes',
                    'For electrical burns: ensure the power source is off before touching the person',
                    'Seek immediate medical help for burns larger than your palm, or on face/hands/joints',
                ],
                tips: 'Do NOT use ice on burns — it causes frostbite on damaged tissue. Cool running water is the gold standard.',
            },
            fractures: {
                title: 'Bone Fractures & Splinting',
                keywords: ['fracture', 'broken bone', 'break', 'splint', 'dislocation', 'sprain'],
                steps: [
                    'Do NOT move the person unless they\'re in immediate danger',
                    'Immobilize the injured area — do NOT try to realign the bone',
                    'Apply a splint: use sticks, boards, rolled newspapers, or cardboard',
                    'Pad the splint with soft material (cloth, clothing)',
                    'Secure the splint above AND below the fracture with bandages or strips',
                    'Apply ice wrapped in cloth to reduce swelling (20 min on, 20 min off)',
                    'Check circulation beyond the splint: pulse, sensation, skin color',
                    'For suspected spine/neck injuries: do NOT move the person at all',
                    'Keep the person calm and still; treat for shock if needed',
                ],
                tips: 'The rule of splinting: immobilize the joint above and below the fracture. If in doubt, splint it.',
            },
            shock: {
                title: 'Recognizing & Treating Shock',
                keywords: ['shock', 'pale', 'cold sweat', 'rapid pulse', 'confused', 'fainting'],
                steps: [
                    'Lay the person down on their back',
                    'Elevate the legs about 12 inches (unless there\'s a head, neck, or back injury)',
                    'Keep them warm with blankets, coats, or body heat',
                    'Do NOT give food or drinks',
                    'Loosen tight clothing, belts, and accessories',
                    'Monitor breathing — if they vomit, turn them on their side',
                    'Talk to them calmly and reassuringly',
                    'If they stop breathing, begin CPR immediately',
                ],
                tips: 'Shock can kill even when the original injury seems survivable. Always monitor and treat for shock after any serious injury.',
            },
        },
    },

    natural_disasters: {
        label: '🌊 Natural Disasters',
        icon: '🌊',
        topics: {
            earthquake: {
                title: 'Earthquake Response',
                keywords: ['earthquake', 'quake', 'tremor', 'shaking', 'seismic'],
                steps: [
                    'DROP to your hands and knees immediately',
                    'Take COVER under sturdy furniture (table, desk) — protect head and neck',
                    'HOLD ON to your shelter until the shaking stops',
                    'If outdoors: move away from buildings, power lines, and trees',
                    'If in a car: pull over, stop, and stay inside with seatbelt on',
                    'After shaking stops: check yourself and others for injuries',
                    'Watch for aftershocks — they can be strong',
                    'Do NOT use elevators',
                    'Check for gas leaks (smell) — if detected, leave the building immediately',
                    'Move to open ground if near the coast — tsunami risk after earthquakes',
                ],
                tips: 'Doorways are NOT safer than other spots in modern buildings. Get under a sturdy table or desk instead.',
            },
            flood: {
                title: 'Flood Safety',
                keywords: ['flood', 'flooding', 'water rising', 'flash flood', 'submerged', 'drowning'],
                steps: [
                    'Move to higher ground IMMEDIATELY — do not wait',
                    'Never walk, swim, or drive through flood waters',
                    'Just 6 inches of moving water can knock you down; 2 feet can carry away a vehicle',
                    'If trapped in a building, go to the highest floor — NOT the attic (you could get trapped)',
                    'Signal for help from a window or rooftop',
                    'Avoid electrical equipment and downed power lines',
                    'If in a car being submerged: unbuckle, open window, swim out',
                    'After flood waters recede: beware of structural damage and contaminated water',
                    'Do NOT eat food that has been in contact with flood water',
                    'Boil water or use purification tablets before drinking',
                ],
                tips: '"Turn around, don\'t drown" — never cross flood water. The depth and current are impossible to judge visually.',
            },
            hurricane: {
                title: 'Hurricane / Cyclone Response',
                keywords: ['hurricane', 'cyclone', 'typhoon', 'storm surge', 'high winds', 'tropical storm'],
                steps: [
                    'Board up windows or use storm shutters',
                    'Move to an interior room on the lowest floor — away from windows',
                    'Stock up: 3 days of water (1 gallon/person/day), non-perishable food, medications',
                    'Fill bathtubs with water (for flushing toilets and cleaning)',
                    'Charge all devices fully; have backup batteries',
                    'During the storm: stay indoors, away from windows and doors',
                    'The "eye" of the storm is calm but TEMPORARY — the other side is coming',
                    'After the storm: avoid downed power lines and standing water',
                    'Document damage with photos for insurance',
                    'Check on neighbors, especially elderly and disabled',
                ],
                tips: 'Storm surge (rising ocean water) kills more people than wind. If you\'re in a surge zone and told to evacuate: LEAVE.',
            },
            tsunami: {
                title: 'Tsunami Response',
                keywords: ['tsunami', 'tidal wave', 'ocean receding', 'coastal flood'],
                steps: [
                    'If near the coast and feel a strong earthquake: move inland and uphill IMMEDIATELY',
                    'A rapid receding of ocean water is a major warning sign — run to high ground',
                    'Move at least 2 miles inland or 100+ feet above sea level',
                    'Do NOT go to the beach to watch — tsunamis move faster than you can run',
                    'If caught by the wave: grab something that floats, hold on',
                    'Multiple waves will come — the first is often NOT the largest',
                    'Wait for official all-clear before returning to coastal areas',
                    'After: avoid flood water (contaminated) and damaged structures',
                ],
                tips: 'Natural warning signs: strong earthquake + ocean rapidly receding = RUN to high ground NOW. Don\'t wait for an official alert.',
            },
        },
    },

    survival: {
        label: '🏕️ Survival Skills',
        icon: '🏕️',
        topics: {
            water_purification: {
                title: 'Finding & Purifying Water',
                keywords: ['water', 'purify', 'purification', 'clean water', 'drinking water', 'dehydrated', 'thirsty', 'boil water'],
                steps: [
                    'BOILING is the most reliable method — bring water to a rolling boil for at least 1 minute',
                    'At high altitudes (above 6500ft): boil for 3 minutes',
                    'If you can\'t boil: use water purification tablets (follow package instructions)',
                    'Solar disinfection (SODIS): fill clear plastic bottles, leave in direct sunlight for 6+ hours',
                    'Finding water: look in valleys, follow animal tracks, dig in dry riverbeds',
                    'Collect rainwater using tarps, plastic sheets, or any clean container',
                    'Collect dew in the early morning using a cloth dragged across grass',
                    'Avoid drinking: saltwater, flood water, stagnant/murky water, water near chemical sources',
                    'Signs of dehydration: dark urine, dizziness, headache, dry mouth — drink immediately',
                ],
                tips: 'You can survive about 3 days without water. Finding clean water is your #1 priority after ensuring safety.',
            },
            shelter: {
                title: 'Building Emergency Shelter',
                keywords: ['shelter', 'build shelter', 'cold', 'hypothermia', 'exposed', 'camp', 'sleep outside'],
                steps: [
                    'Find a location: protected from wind, away from water/flood paths, visible for rescue',
                    'Lean-to shelter: prop a long branch against a tree, layer smaller branches and leaves on one side',
                    'Debris hut: create an A-frame with branches, pile leaves/grass 2-3 feet thick for insulation',
                    'In snow: dig a snow cave or trench — snow is an excellent insulator',
                    'Use plastic bags, tarps, garbage bags, or emergency blankets if available',
                    'Insulate the ground — sleeping on cold ground causes hypothermia faster than cold air',
                    'Use leaves, grass, pine needles, cardboard, or clothing as ground insulation',
                    'Make the shelter small — your body heat warms smaller spaces better',
                    'Block the entrance from wind but keep ventilation for air',
                ],
                tips: 'Rule of 3s: You can survive 3 hours without shelter in harsh conditions. Shelter is higher priority than food.',
            },
            signaling: {
                title: 'Signaling for Rescue',
                keywords: ['rescue', 'signal', 'help signal', 'sos', 'mirror', 'smoke', 'flare', 'found', 'search'],
                steps: [
                    'International distress signal: 3 of anything (3 fires, 3 whistle blasts, 3 gunshots)',
                    'SOS in Morse code: ••• ─── ••• (3 short, 3 long, 3 short) — use light, sound, or taps',
                    'Signal mirror: reflect sunlight toward aircraft or rescuers — visible 50+ miles away',
                    'Ground signals: use rocks/logs to write SOS or HELP — make letters at least 10 feet tall',
                    'Smoke signals: burn green leaves/branches for white smoke (visible against dark ground)',
                    'At night: use bright fire, flashlight, or phone screen',
                    'Whistle: carries farther than voice and uses less energy',
                    'Brightly colored clothing/materials: tie to high points visible from the air',
                    'Stay in one place if possible — moving makes it harder for rescuers to find you',
                ],
                tips: 'A signal mirror is the single most effective daytime rescue signal. Practice aiming reflected sunlight at a target.',
            },
            fire: {
                title: 'Starting a Fire',
                keywords: ['fire', 'start fire', 'warmth', 'cold', 'heat', 'campfire', 'light fire'],
                steps: [
                    'Gather tinder (dry grass, bark shavings, cotton, paper), kindling (small twigs), and fuel (larger wood)',
                    'Build a fire lay: teepee or log cabin structure with tinder in the center',
                    'Lighter/matches: shield from wind with your body or hands',
                    'No lighter: battery + steel wool, flint & steel, friction (bow drill)',
                    'Magnifying glass/water bottle: focus sunlight on tinder to create ember',
                    'Keep fuel dry — store extra wood under cover',
                    'Fire triangle: heat + fuel + oxygen — remove any one to extinguish',
                    'Never leave a fire unattended',
                    'Build fire near your shelter but not too close (prevents accidental ignition)',
                    'Use fire for: warmth, signaling, water purification, cooking, morale',
                ],
                tips: 'The biggest mistake is starting with wood that\'s too large. Start tiny (matchstick size) and gradually increase.',
            },
        },
    },

    communication: {
        label: '📡 Communication',
        icon: '📡',
        topics: {
            sos_protocol: {
                title: 'SOS & Emergency Protocols',
                keywords: ['sos', 'mayday', 'emergency call', 'distress', 'pan pan', 'calling for help'],
                steps: [
                    'Morse Code SOS: ••• ─── ••• (3 short, 3 long, 3 short) — universal distress signal',
                    'Voice distress: "MAYDAY MAYDAY MAYDAY" for life-threatening; "PAN-PAN" for urgent but not life-threatening',
                    'Include in distress message: WHO you are, WHERE you are, WHAT happened, HOW MANY people, WHAT help you need',
                    'Use GPS coordinates if available (share from your phone\'s compass or maps app)',
                    'If no signal: use MeshLink to broadcast to nearby devices',
                    'Send your message with CRITICAL priority for emergency relay',
                    'Repeat distress messages at regular intervals',
                    'Keep messages short and clear — bandwidth is limited in mesh networks',
                ],
                tips: 'A clear, concise distress message saves lives. Format: "MAYDAY — [name], [location], [emergency], [# people], [need]"',
            },
            mesh_tips: {
                title: 'Using MeshLink Effectively',
                keywords: ['mesh', 'meshlink', 'bluetooth', 'connect', 'network', 'how to use', 'app'],
                steps: [
                    'Keep Bluetooth enabled at all times for peer discovery',
                    'Move to higher ground for better Bluetooth range (up to ~100m for BLE)',
                    'Stay within range of at least one other MeshLink user for relay to work',
                    'Use short, clear messages — BLE bandwidth is limited',
                    'Mark emergency messages as CRITICAL priority for faster relay',
                    'The AI assistant can help you draft emergency messages',
                    'Messages are stored locally and relayed when new peers are discovered',
                    'Your messages are encrypted end-to-end — only MeshLink users can read them',
                    'Create a mesh chain: each person in range extends the network',
                ],
                tips: 'BLE range is roughly 100m in open air, less in buildings. Position your group in a chain to extend range.',
            },
        },
    },

    navigation: {
        label: '🧭 Navigation',
        icon: '🧭',
        topics: {
            without_compass: {
                title: 'Navigation Without a Compass',
                keywords: ['lost', 'navigate', 'direction', 'compass', 'north', 'south', 'find way', 'which way'],
                steps: [
                    'Sun method: the sun rises in the East and sets in the West',
                    'Stick shadow: place a stick in the ground, mark shadow tip — wait 15 min, mark again. The line points East-West',
                    'Watch method: point the hour hand at the sun — halfway between it and 12 is roughly South (Northern hemisphere)',
                    'At night: find the North Star (Polaris) — follow the two "pointer stars" at the end of the Big Dipper',
                    'In Southern hemisphere: use the Southern Cross constellation',
                    'Moss tends to grow on the north side of trees (Northern hemisphere) — not always reliable',
                    'Rivers generally flow downhill toward civilization — follow downstream',
                    'Look for signs of civilization: power lines, contrails, distant lights, road noise',
                    'If truly lost: STOP. Sit, Think, Observe, Plan. Don\'t wander aimlessly.',
                ],
                tips: 'The most reliable method is the North Star at night and the stick shadow during the day. Practice before you need them.',
            },
        },
    },
};

/**
 * Search the knowledge base for relevant topics.
 */
export function searchKnowledge(query) {
    if (!query || query.trim().length === 0) return [];

    const lowerQuery = query.toLowerCase();
    const results = [];

    for (const [categoryKey, category] of Object.entries(KNOWLEDGE_BASE)) {
        for (const [topicKey, topic] of Object.entries(category.topics)) {
            let relevance = 0;

            // Check title
            if (topic.title.toLowerCase().includes(lowerQuery)) {
                relevance += 10;
            }

            // Check keywords
            for (const keyword of topic.keywords) {
                if (lowerQuery.includes(keyword) || keyword.includes(lowerQuery)) {
                    relevance += 5;
                }
            }

            // Check step content
            for (const step of topic.steps) {
                if (step.toLowerCase().includes(lowerQuery)) {
                    relevance += 1;
                }
            }

            if (relevance > 0) {
                results.push({
                    categoryKey,
                    categoryLabel: category.label,
                    topicKey,
                    topic,
                    relevance,
                });
            }
        }
    }

    return results.sort((a, b) => b.relevance - a.relevance);
}

/**
 * Get all categories for browsing.
 */
export function getAllCategories() {
    return Object.entries(KNOWLEDGE_BASE).map(([key, cat]) => ({
        key,
        label: cat.label,
        icon: cat.icon,
        topicCount: Object.keys(cat.topics).length,
        topics: Object.entries(cat.topics).map(([tKey, t]) => ({
            key: tKey,
            title: t.title,
        })),
    }));
}

/**
 * Get a specific topic by category and topic key.
 */
export function getTopic(categoryKey, topicKey) {
    const category = KNOWLEDGE_BASE[categoryKey];
    if (!category) return null;
    const topic = category.topics[topicKey];
    if (!topic) return null;
    return { ...topic, categoryLabel: category.label };
}

/**
 * Get all topics as a flat list.
 */
export function getAllTopics() {
    const topics = [];
    for (const [categoryKey, category] of Object.entries(KNOWLEDGE_BASE)) {
        for (const [topicKey, topic] of Object.entries(category.topics)) {
            topics.push({
                categoryKey,
                categoryLabel: category.label,
                topicKey,
                title: topic.title,
                keywords: topic.keywords,
            });
        }
    }
    return topics;
}

export { KNOWLEDGE_BASE };
