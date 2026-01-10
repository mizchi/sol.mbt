// js/sol/signal.ts
var currentListener = null;
function createSignal(initialValue) {
  let value = initialValue;
  const listeners = /* @__PURE__ */ new Set();
  const getter = () => {
    if (currentListener) {
      listeners.add(currentListener);
    }
    return value;
  };
  const setter = (newValue) => {
    const nextValue = typeof newValue === "function" ? newValue(value) : newValue;
    if (nextValue !== value) {
      value = nextValue;
      for (const listener of listeners) {
        listener();
      }
    }
  };
  return [getter, setter];
}
function createEffect(fn) {
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

// js/sol/hydration.ts
function createHydrator(fn) {
  const cleanups = /* @__PURE__ */ new WeakMap();
  return (element, state, name) => {
    if (element.dataset.hydrated) {
      return;
    }
    const existingCleanup = cleanups.get(element);
    if (existingCleanup) {
      existingCleanup();
      cleanups.delete(element);
    }
    const cleanup = fn(element, state, name);
    if (typeof cleanup === "function") {
      cleanups.set(element, cleanup);
    }
    element.dataset.hydrated = "true";
  };
}

// examples/sol_tsx/app/client/counter.ts
var hydrate = createHydrator((element, state) => {
  const props = state;
  const [count, setCount] = createSignal(props.initialCount);
  const display = element.querySelector(".count-display");
  const decButton = element.querySelector(".dec");
  const incButton = element.querySelector(".inc");
  if (!display || !decButton || !incButton) {
    console.error("Counter: Missing required elements");
    return;
  }
  createEffect(() => {
    display.textContent = String(count());
  });
  decButton.addEventListener("click", () => setCount((n) => n - 1));
  incButton.addEventListener("click", () => setCount((n) => n + 1));
  return () => {
    decButton.removeEventListener("click", () => {
    });
    incButton.removeEventListener("click", () => {
    });
  };
});

// examples/sol_tsx/app/client/entry.ts
var islands = {
  counter: hydrate
};
function hydrateAll() {
  const islandElements = document.querySelectorAll("[data-island]");
  for (const element of islandElements) {
    const name = element.dataset.island;
    if (!name) continue;
    const hydrator = islands[name];
    if (!hydrator) {
      console.warn(`Unknown island: ${name}`);
      continue;
    }
    const stateStr = element.dataset.state;
    let state = {};
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
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", hydrateAll);
} else {
  hydrateAll();
}
//# sourceMappingURL=client.js.map
