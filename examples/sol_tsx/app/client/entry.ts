// Client Entry Point
// Registers all island hydrators and runs hydration on page load

import { hydrate as counterHydrate } from './counter.js';

// Island registry
const islands: Record<string, (el: Element, state: unknown, name: string) => void> = {
  counter: counterHydrate,
};

// Hydrate all islands on the page
function hydrateAll() {
  const islandElements = document.querySelectorAll('[data-island]');

  for (const element of islandElements) {
    const name = (element as HTMLElement).dataset.island;
    if (!name) continue;

    const hydrator = islands[name];
    if (!hydrator) {
      console.warn(`Unknown island: ${name}`);
      continue;
    }

    // Parse state from data-state attribute
    const stateStr = (element as HTMLElement).dataset.state;
    let state: unknown = {};
    if (stateStr) {
      try {
        state = JSON.parse(stateStr);
      } catch (e) {
        console.error(`Failed to parse state for island ${name}:`, e);
      }
    }

    hydrator(element, state, name);
  }
}

// Run hydration when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', hydrateAll);
} else {
  hydrateAll();
}
