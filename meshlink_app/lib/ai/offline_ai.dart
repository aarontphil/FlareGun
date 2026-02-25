class OfflineAI {
  static final _kb = <String, Map<String, String>>{
    'earthquake_during': {
      'title': 'During an Earthquake',
      'content': 'Drop, Cover, and Hold On.\n\n'
          'Drop to your hands and knees.\n'
          'Take cover under a sturdy desk or table.\n'
          'Hold on until the shaking stops.\n'
          'Stay away from windows and heavy furniture.\n'
          'If outdoors, move to an open area away from buildings.\n'
          'Do NOT run outside during shaking.\n'
          'Do NOT stand in doorways.',
    },
    'earthquake_after': {
      'title': 'After an Earthquake',
      'content': 'Check for injuries and hazards.\n\n'
          'Check yourself and others for injuries.\n'
          'Expect aftershocks.\n'
          'Check for gas leaks, fire, and structural damage.\n'
          'Do NOT use elevators.\n'
          'If trapped, tap on pipes or walls to signal rescuers.\n'
          'Use text messages instead of calls.',
    },
    'flood_safety': {
      'title': 'Flood Safety',
      'content': 'Move to higher ground immediately.\n\n'
          'Never walk, swim, or drive through flood waters.\n'
          '6 inches of moving water can knock you down.\n'
          '12 inches of water can carry away a vehicle.\n'
          'Stay off bridges over fast-moving water.\n'
          'If trapped, go to the highest floor.\n'
          'Signal for help from a window or roof.',
    },
    'flood_water': {
      'title': 'Safe Drinking Water',
      'content': 'Assume all water is contaminated after a flood.\n\n'
          'Boil water for at least 1 minute before drinking.\n'
          'Use water purification tablets if available.\n'
          'Collect rainwater in clean containers.\n'
          'Avoid flood water — it contains sewage and chemicals.',
    },
    'fire_escape': {
      'title': 'Fire Escape',
      'content': 'Get out, stay out, call for help.\n\n'
          'Crawl low under smoke.\n'
          'Feel doors before opening — if hot, use another exit.\n'
          'Close doors behind you to slow the fire.\n'
          'If clothes catch fire: Stop, Drop, and Roll.\n'
          'Never go back into a burning building.\n'
          'Meet at a pre-designated meeting point.',
    },
    'medical_firstaid': {
      'title': 'Basic First Aid',
      'content': 'ABCs: Airway, Breathing, Circulation.\n\n'
          'Clear the airway — tilt head back, lift chin.\n'
          'Check for breathing — look, listen, feel.\n'
          'Control bleeding — apply direct pressure with clean cloth.\n'
          'Treat for shock — lay person flat, elevate legs.\n'
          'Keep injured person warm and calm.\n'
          'Do NOT move someone with potential spinal injury.',
    },
    'medical_cpr': {
      'title': 'CPR Guide',
      'content': 'Hands-Only CPR for adults.\n\n'
          'Place heel of hand on center of chest.\n'
          'Push hard and fast — 2 inches deep, 100-120 per minute.\n'
          'Do not stop until help arrives.\n'
          'For children: use one hand.\n'
          'For infants: use two fingers.',
    },
    'shelter_building': {
      'title': 'Emergency Shelter',
      'content': 'Priority: protection from elements.\n\n'
          'Find or create wind protection first.\n'
          'Use any available materials: tarps, branches, debris.\n'
          'Insulate from the ground — use leaves, cardboard.\n'
          'Keep shelter small to retain body heat.\n'
          'Signal location with bright materials on roof.',
    },
    'communication_offline': {
      'title': 'Offline Communication',
      'content': 'Use FlareGun for peer-to-peer messaging.\n\n'
          'Bluetooth mesh works without internet or cell towers.\n'
          'Each connected device extends the network range.\n'
          'Use CRITICAL priority for emergency messages.\n'
          'Keep messages short and clear.\n'
          'Include your location and number of people.',
    },
    'tornado_safety': {
      'title': 'Tornado Safety',
      'content': 'Get to the lowest floor immediately.\n\n'
          'Go to a basement or interior room on the lowest floor.\n'
          'Stay away from windows, doors, and outside walls.\n'
          'Get under a sturdy table and cover your head.\n'
          'If in a vehicle, get out and find a ditch.\n'
          'Do NOT try to outrun a tornado in your car.',
    },
    'wound_care': {
      'title': 'Wound Care',
      'content': 'Stop bleeding and prevent infection.\n\n'
          'Apply direct pressure with a clean cloth.\n'
          'Elevate the injured area above the heart if possible.\n'
          'Clean the wound with clean water when bleeding stops.\n'
          'Apply antibiotic ointment if available.\n'
          'Cover with a sterile bandage.\n'
          'Change the dressing daily.',
    },
    'dehydration': {
      'title': 'Dehydration',
      'content': 'Recognize and treat dehydration.\n\n'
          'Symptoms: dry mouth, dark urine, dizziness, confusion.\n'
          'Drink small sips of water frequently.\n'
          'Avoid caffeine and alcohol.\n'
          'If available, use oral rehydration salts.\n'
          'Stay in shade to reduce water loss.\n'
          'Ration water if supply is limited.',
    },
    'hypothermia': {
      'title': 'Hypothermia',
      'content': 'Recognize and treat hypothermia.\n\n'
          'Symptoms: shivering, slurred speech, confusion, drowsiness.\n'
          'Move to a warm dry shelter.\n'
          'Remove wet clothing and replace with dry layers.\n'
          'Warm the center of the body first: chest, neck, head.\n'
          'Use body heat from another person if needed.\n'
          'Give warm drinks if conscious. No alcohol.',
    },
  };

  static final _emergencyKeywords = <String>[
    'sos', 'help', 'emergency', 'danger', 'trapped', 'rescue',
    'save', 'dying', 'attack', 'shooter', 'bomb', 'fire',
    'collapse', 'drowning', 'bleeding', 'unconscious',
  ];

  static final _categoryKeywords = <String, List<String>>{
    'earthquake': ['earthquake', 'quake', 'tremor', 'seismic', 'aftershock', 'shaking'],
    'flood': ['flood', 'flooding', 'water rising', 'tsunami', 'storm surge', 'rain'],
    'fire': ['fire', 'burning', 'smoke', 'flames', 'wildfire', 'explosion'],
    'medical': ['injured', 'injury', 'bleeding', 'broken', 'cpr', 'first aid', 'wound', 'fracture', 'pain', 'burn', 'choking'],
    'shelter': ['shelter', 'homeless', 'camp', 'tent', 'housing'],
    'communication': ['communicate', 'offline', 'mesh', 'bluetooth', 'signal', 'contact'],
    'tornado': ['tornado', 'twister', 'cyclone', 'funnel'],
    'dehydration': ['dehydration', 'thirsty', 'water', 'drinking', 'hydrate'],
    'hypothermia': ['hypothermia', 'cold', 'freezing', 'frostbite', 'shivering'],
  };

  static String chat(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return 'Ask me about disaster survival, first aid, or emergency procedures.';

    if (_isGreeting(q)) {
      return 'I am your offline AI assistant.\n\n'
          'I can help with:\n'
          'Earthquake safety\n'
          'Flood survival\n'
          'Fire escape\n'
          'First aid and CPR\n'
          'Emergency shelter\n'
          'Offline communication\n\n'
          'Ask me anything about disaster preparedness.';
    }

    if (_isEmergency(q)) {
      return 'EMERGENCY\n\n'
          'Stay calm and assess your surroundings.\n'
          'Use the Chat tab to broadcast an SOS with CRITICAL priority.\n'
          'Include your location and number of people.\n'
          'If trapped, tap on walls or pipes to signal rescuers.\n'
          'Conserve phone battery — reduce brightness.\n'
          'Do NOT move if you suspect spinal injury.';
    }

    final results = _search(q);
    if (results.isNotEmpty) {
      final best = results.first;
      return '${best['title']}\n\n${best['content']}';
    }

    return 'I don\'t have specific info on that topic.\n\n'
        'Try asking about:\n'
        'Earthquake, flood, or fire safety\n'
        'First aid or CPR\n'
        'Emergency shelter building\n'
        'Tornado safety\n'
        'Dehydration or hypothermia\n'
        'How to use FlareGun offline';
  }

  static bool _isGreeting(String q) {
    const greetings = ['hello', 'hi', 'hey', 'help', 'start', 'what can you do'];
    return greetings.any((g) => q.contains(g));
  }

  static bool _isEmergency(String q) {
    int matches = 0;
    for (final kw in _emergencyKeywords) {
      if (q.contains(kw)) matches++;
    }
    return matches >= 1 && (q.contains('sos') || q.contains('emergency') || q.contains('trapped') || matches >= 2);
  }

  static List<Map<String, String>> _search(String query) {
    final results = <Map<String, String>>[];
    final words = query.split(RegExp(r'\s+'));

    String? bestCategory;
    int bestScore = 0;

    for (final entry in _categoryKeywords.entries) {
      int score = 0;
      for (final kw in entry.value) {
        if (query.contains(kw)) score += 2;
      }
      for (final w in words) {
        if (entry.key.contains(w) && w.length > 2) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    if (bestCategory != null && bestScore > 0) {
      for (final entry in _kb.entries) {
        if (entry.key.startsWith(bestCategory)) {
          results.add(entry.value);
        }
      }
    }

    if (results.isEmpty) {
      for (final entry in _kb.entries) {
        final title = entry.value['title']!.toLowerCase();
        final content = entry.value['content']!.toLowerCase();
        for (final w in words) {
          if (w.length > 2 && (title.contains(w) || content.contains(w))) {
            results.add(entry.value);
            break;
          }
        }
      }
    }

    return results;
  }
}
