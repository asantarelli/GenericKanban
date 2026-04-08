// Ambient declarations for globals loaded outside the bundle.

interface SortableEvent {
  item: HTMLElement;
  from: HTMLElement & { dataset: DOMStringMap };
  to: HTMLElement & { dataset: DOMStringMap };
}

interface SortableOptions {
  group?: string;
  animation?: number;
  easing?: string;
  ghostClass?: string;
  chosenClass?: string;
  dragClass?: string;
  emptyInsertThreshold?: number;
  onEnd?(evt: SortableEvent): void;
}

declare class Sortable {
  constructor(el: HTMLElement, options: SortableOptions);
  option(name: string, value: unknown): void;
  destroy(): void;
}

interface Window {
  chrome: {
    webview: {
      postMessage(message: string): void;
    };
  };
  kanban: unknown; // debug console access
}
