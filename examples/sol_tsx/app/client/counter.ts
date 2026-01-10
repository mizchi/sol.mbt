// Counter Client Component
// Uses Luna's reactive system for client-side interactivity

import { createSignal, createEffect, createHydrator } from '@luna_ui/luna';

interface CounterProps {
  initialCount: number;
}

// Hydration function for island architecture
export const hydrate = createHydrator((element, state) => {
  const props = state as CounterProps;
  const [count, setCount] = createSignal(props.initialCount);

  // Find elements
  const display = element.querySelector('.count-display') as HTMLElement;
  const decButton = element.querySelector('.dec') as HTMLButtonElement;
  const incButton = element.querySelector('.inc') as HTMLButtonElement;

  if (!display || !decButton || !incButton) {
    console.error('Counter: Missing required elements');
    return;
  }

  // Update display when count changes
  createEffect(() => {
    display.textContent = String(count());
  });

  // Event handlers
  decButton.addEventListener('click', () => setCount((n) => n - 1));
  incButton.addEventListener('click', () => setCount((n) => n + 1));

  // Cleanup
  return () => {
    decButton.removeEventListener('click', () => {});
    incButton.removeEventListener('click', () => {});
  };
});
