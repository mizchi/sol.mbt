/**
 * Client-side render function for Luna islands
 */

import { createEffect } from './signal';

type VNode = {
  tag: string;
  attrs: Record<string, unknown>;
  children: (VNode | string | (() => unknown))[];
} | string | (() => unknown);

/**
 * Render a component to a DOM element
 */
export function render(component: () => VNode, container: Element): void {
  container.innerHTML = '';
  const node = renderNode(component());
  if (node) {
    container.appendChild(node);
  }
}

function renderNode(vnode: VNode): Node | null {
  if (vnode === null || vnode === undefined) {
    return null;
  }

  // Text node
  if (typeof vnode === 'string') {
    return document.createTextNode(vnode);
  }

  // Number
  if (typeof vnode === 'number') {
    return document.createTextNode(String(vnode));
  }

  // Reactive accessor
  if (typeof vnode === 'function') {
    const placeholder = document.createTextNode('');
    createEffect(() => {
      const value = (vnode as () => unknown)();
      placeholder.textContent = String(value ?? '');
    });
    return placeholder;
  }

  // Array of nodes
  if (Array.isArray(vnode)) {
    const fragment = document.createDocumentFragment();
    for (const child of vnode) {
      const node = renderNode(child as VNode);
      if (node) fragment.appendChild(node);
    }
    return fragment;
  }

  // Element
  if (typeof vnode === 'object' && 'tag' in vnode) {
    const element = document.createElement(vnode.tag);

    // Set attributes
    for (const [key, value] of Object.entries(vnode.attrs)) {
      if (key === 'children') continue;

      // Event handlers
      if (key.startsWith('on') && typeof value === 'function') {
        const eventName = key.slice(2).toLowerCase();
        element.addEventListener(eventName, value as EventListener);
        continue;
      }

      // Class/className
      if (key === 'class' || key === 'className') {
        if (typeof value === 'function') {
          createEffect(() => {
            element.className = String((value as () => unknown)() ?? '');
          });
        } else {
          element.className = String(value ?? '');
        }
        continue;
      }

      // Style
      if (key === 'style') {
        if (typeof value === 'object' && value !== null) {
          for (const [prop, val] of Object.entries(value)) {
            (element.style as Record<string, string>)[prop] = String(val);
          }
        } else if (typeof value === 'string') {
          element.setAttribute('style', value);
        }
        continue;
      }

      // Regular attributes
      if (typeof value === 'function') {
        createEffect(() => {
          const v = (value as () => unknown)();
          if (v === false || v === null || v === undefined) {
            element.removeAttribute(key);
          } else if (v === true) {
            element.setAttribute(key, '');
          } else {
            element.setAttribute(key, String(v));
          }
        });
      } else if (value !== false && value !== null && value !== undefined) {
        if (value === true) {
          element.setAttribute(key, '');
        } else {
          element.setAttribute(key, String(value));
        }
      }
    }

    // Render children
    for (const child of vnode.children) {
      const node = renderNode(child as VNode);
      if (node) element.appendChild(node);
    }

    return element;
  }

  return null;
}
