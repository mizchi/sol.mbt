/**
 * Client-side JSX Runtime for Luna
 * Produces DOM-compatible VNode structures for the render function
 */

import { createEffect } from './signal';

// VNode type for client-side rendering
export type VNode = {
  tag: string;
  attrs: Record<string, unknown>;
  children: (VNode | string | (() => unknown))[];
};

type Component<P = Record<string, unknown>> = (props: P) => VNode | VNode[];

/**
 * JSX factory function for client-side
 */
export function jsx(
  type: string | Component,
  props: Record<string, unknown> | null
): VNode | VNode[] {
  const { children, ...rest } = props || {};

  // Function component
  if (typeof type === 'function') {
    return type({ ...rest, children });
  }

  // HTML element
  if (typeof type === 'string') {
    const childArray = normalizeChildren(children);
    return {
      tag: type,
      attrs: rest,
      children: childArray,
    };
  }

  throw new Error(`Invalid JSX type: ${type}`);
}

function normalizeChildren(children: unknown): (VNode | string | (() => unknown))[] {
  if (children === undefined || children === null) return [];

  const childArray = Array.isArray(children) ? children.flat() : [children];

  return childArray
    .filter((child) => child !== undefined && child !== null && child !== false)
    .map((child) => {
      if (typeof child === 'string') return child;
      if (typeof child === 'number') return String(child);
      if (typeof child === 'function') return child as () => unknown;
      return child as VNode;
    });
}

export const jsxs = jsx;

export function Fragment({ children }: { children?: unknown }): VNode[] {
  return normalizeChildren(children) as VNode[];
}

export const jsxDEV = jsx;

// JSX namespace for TypeScript
export namespace JSX {
  export type Element = VNode | VNode[];

  export interface IntrinsicElements {
    [key: string]: Record<string, unknown>;
  }

  export interface ElementChildrenAttribute {
    children: {};
  }
}
