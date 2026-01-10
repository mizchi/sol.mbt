/**
 * Simple reactive signal system for client-side Luna
 * Minimal implementation for island hydration
 */

type Listener = () => void;
let currentListener: Listener | null = null;

export type Accessor<T> = () => T;
export type Setter<T> = (value: T | ((prev: T) => T)) => void;
export type Signal<T> = [Accessor<T>, Setter<T>];

/**
 * Creates a reactive signal
 */
export function createSignal<T>(initialValue: T): Signal<T> {
  let value = initialValue;
  const listeners = new Set<Listener>();

  const getter: Accessor<T> = () => {
    if (currentListener) {
      listeners.add(currentListener);
    }
    return value;
  };

  const setter: Setter<T> = (newValue) => {
    const nextValue = typeof newValue === 'function'
      ? (newValue as (prev: T) => T)(value)
      : newValue;

    if (nextValue !== value) {
      value = nextValue;
      for (const listener of listeners) {
        listener();
      }
    }
  };

  return [getter, setter];
}

/**
 * Creates a reactive effect
 */
export function createEffect(fn: () => void): void {
  const execute = () => {
    currentListener = execute;
    try {
      fn();
    } finally {
      currentListener = null;
    }
  };
  execute();
}

/**
 * Creates a memoized computed value
 */
export function createMemo<T>(fn: () => T): Accessor<T> {
  const [value, setValue] = createSignal<T>(undefined as T);

  createEffect(() => {
    setValue(fn());
  });

  return value;
}

/**
 * Batch multiple updates
 */
let batchDepth = 0;
let pendingUpdates: Set<Listener> = new Set();

export function batch(fn: () => void): void {
  batchDepth++;
  try {
    fn();
  } finally {
    batchDepth--;
    if (batchDepth === 0) {
      const updates = pendingUpdates;
      pendingUpdates = new Set();
      for (const update of updates) {
        update();
      }
    }
  }
}
