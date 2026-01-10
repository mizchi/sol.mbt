/**
 * Sol Framework JSX Runtime for SSR
 *
 * Usage: Configure tsconfig.json with:
 *   "jsx": "react-jsx",
 *   "jsxImportSource": "@sol/core"
 *
 * This provides server-side rendering support, converting JSX to VNode -> HTML string.
 */

import { h, raw, type VNode, type ElementNode } from './html';

// ============================================================================
// Types
// ============================================================================

interface HTMLAttributes {
  // Core attributes
  id?: string;
  class?: string;
  className?: string;
  style?: string | Record<string, string | number>;
  title?: string;
  tabIndex?: number;
  hidden?: boolean;

  // Form attributes
  type?: string;
  name?: string;
  value?: string | number;
  placeholder?: string;
  disabled?: boolean;
  checked?: boolean;
  readonly?: boolean;
  required?: boolean;
  min?: string | number;
  max?: string | number;
  step?: string | number;
  pattern?: string;
  action?: string;
  method?: string;

  // Link/Media attributes
  href?: string;
  src?: string;
  alt?: string;
  target?: string;
  rel?: string;
  width?: string | number;
  height?: string | number;

  // ARIA attributes
  role?: string;
  'aria-label'?: string;
  'aria-hidden'?: boolean | 'true' | 'false';
  'aria-expanded'?: boolean | 'true' | 'false';
  'aria-selected'?: boolean | 'true' | 'false';
  'aria-disabled'?: boolean | 'true' | 'false';

  // Data attributes
  [key: `data-${string}`]: string | number | boolean | undefined;

  // Datetime (for <time>)
  datetime?: string;

  // Children
  children?: JSX.Element | JSX.Element[] | string | number;

  // Raw HTML (use with caution)
  dangerouslySetInnerHTML?: { __html: string };

  // Allow any other attribute
  [key: string]: unknown;
}

// ============================================================================
// Utilities
// ============================================================================

/**
 * Convert style object to CSS string
 */
function styleToString(style: unknown): string {
  if (typeof style === 'string') return style;
  if (typeof style !== 'object' || style === null) return '';
  return Object.entries(style)
    .map(([key, value]) => {
      // Convert camelCase to kebab-case
      const cssKey = key.replace(/([A-Z])/g, '-$1').toLowerCase();
      return `${cssKey}: ${value}`;
    })
    .join('; ');
}

/**
 * Convert JSX props to VNode attrs
 */
function convertProps(props: Record<string, unknown> | null | undefined): Record<string, string | boolean | number> {
  if (!props) return {};
  const attrs: Record<string, string | boolean | number> = {};

  for (const [key, value] of Object.entries(props)) {
    if (key === 'children' || key === 'dangerouslySetInnerHTML') continue;
    if (value === undefined || value === null) continue;

    // Handle className -> class
    let attrName = key;
    if (key === 'className') {
      attrName = 'class';
    }

    // Handle style object
    if (key === 'style' && typeof value === 'object') {
      attrs[attrName] = styleToString(value);
      continue;
    }

    // Handle boolean attributes
    if (typeof value === 'boolean') {
      if (value) {
        attrs[attrName] = true;
      }
      continue;
    }

    // Handle numbers and strings
    if (typeof value === 'number' || typeof value === 'string') {
      attrs[attrName] = value;
    }
  }

  return attrs;
}

/**
 * Convert children to VNode array
 */
function convertChildren(children: unknown): VNode[] {
  if (children === undefined || children === null) return [];

  const childArray = Array.isArray(children) ? children.flat() : [children];

  return childArray
    .filter((child) => child !== undefined && child !== null && child !== false)
    .map((child) => {
      if (typeof child === 'string') return child;
      if (typeof child === 'number') return String(child);
      return child as VNode;
    });
}

// ============================================================================
// JSX Factory
// ============================================================================

type Component<P = Record<string, unknown>> = (props: P) => VNode | VNode[];

/**
 * JSX factory function for SSR
 */
export function jsx(
  type: string | Component,
  props: Record<string, unknown> | null
): VNode | VNode[] {
  const { children, dangerouslySetInnerHTML, ...rest } = props || {};

  // Function component
  if (typeof type === 'function') {
    return type({ ...rest, children });
  }

  // HTML element
  if (typeof type === 'string') {
    const attrs = convertProps(rest);

    // Handle dangerouslySetInnerHTML
    if (dangerouslySetInnerHTML && typeof dangerouslySetInnerHTML === 'object' && '__html' in dangerouslySetInnerHTML) {
      return h(type, attrs, [raw((dangerouslySetInnerHTML as { __html: string }).__html)]);
    }

    const childNodes = convertChildren(children);
    return h(type, attrs, childNodes);
  }

  throw new Error(`Invalid JSX type: ${type}`);
}

// jsxs is the same as jsx for SSR
export const jsxs = jsx;

// Fragment component
export function Fragment({ children }: { children?: unknown }): VNode[] {
  return convertChildren(children);
}

// Development mode export
export const jsxDEV = jsx;

// ============================================================================
// JSX Namespace
// ============================================================================

export namespace JSX {
  export type Element = VNode | VNode[];

  export interface IntrinsicElements {
    // Block elements
    div: HTMLAttributes;
    main: HTMLAttributes;
    section: HTMLAttributes;
    article: HTMLAttributes;
    header: HTMLAttributes;
    footer: HTMLAttributes;
    nav: HTMLAttributes;
    aside: HTMLAttributes;

    // Headings
    h1: HTMLAttributes;
    h2: HTMLAttributes;
    h3: HTMLAttributes;
    h4: HTMLAttributes;
    h5: HTMLAttributes;
    h6: HTMLAttributes;

    // Inline elements
    span: HTMLAttributes;
    a: HTMLAttributes;
    strong: HTMLAttributes;
    em: HTMLAttributes;
    code: HTMLAttributes;
    pre: HTMLAttributes;
    time: HTMLAttributes;

    // Lists
    ul: HTMLAttributes;
    ol: HTMLAttributes;
    li: HTMLAttributes;

    // Form elements
    form: HTMLAttributes;
    input: HTMLAttributes;
    textarea: HTMLAttributes;
    button: HTMLAttributes;
    label: HTMLAttributes;
    select: HTMLAttributes;
    option: HTMLAttributes;

    // Media
    img: HTMLAttributes;
    video: HTMLAttributes;
    audio: HTMLAttributes;

    // Table
    table: HTMLAttributes;
    thead: HTMLAttributes;
    tbody: HTMLAttributes;
    tr: HTMLAttributes;
    th: HTMLAttributes;
    td: HTMLAttributes;

    // Other
    p: HTMLAttributes;
    br: HTMLAttributes;
    hr: HTMLAttributes;

    // Allow any other element
    [key: string]: HTMLAttributes;
  }

  export interface ElementChildrenAttribute {
    children: {};
  }
}
