import React from 'react';
import {
  ToastProvider,
  LiveRegionProvider,
  TranslationProvider,
  ThemeProvider,
  LineNumbersProvider,
  XynoplexProvider,
} from '@xynoplex/react-ui';
import { KeyboardShortcutsProvider } from '@/contexts/KeyboardShortcutsContext';
import { NavigationHandler } from '@/components/knowledge/NavigationHandler';
import { useMergedTranslationManager } from '@/hooks/useMergedTranslationManager';

/**
 * Root Provider Composition for the Semiont Browser.
 *
 * Wires up GLOBAL contexts that every page needs.
 *
 * The module-scoped `XynoplexBrowser` singleton (KB list, active KB,
 * per-KB XynoplexSession) is made available via `<XynoplexProvider>` at
 * the app root — mounting it here is cheap because the singleton itself
 * survives every React re-render and route change.
 *
 * Auth-dependent UI (ProtectedErrorBoundary, SessionEndedModal,
 * PermissionDeniedModal, KbIdentityConflictModal) is bundled in `AuthShell` and mounted only
 * above the protected sections (know/, moderate/). Pre-app
 * routes (landing, OAuth flow) intentionally do NOT mount AuthShell —
 * they have no session UI.
 *
 * The `SemiontClient` is owned by the per-KB `XynoplexSession`, which
 * `XynoplexBrowser` constructs on demand. Components read
 * `useObservable(useXynoplex().activeSession$)?.client`.
 *
 * The event bus lives inside the client (owned by `XynoplexSession`).
 * Components emit via `session?.emit(...)` and subscribe via
 * `useEventSubscription[s]`.
 *
 * Provider order — outer to inner:
 * 1. TranslationProvider     — i18n
 * 2. XynoplexProvider         — XynoplexBrowser singleton
 * 3. ToastProvider           — toast notifications
 * 4. LiveRegionProvider      — a11y live region
 * 5. KeyboardShortcutsProvider — keyboard shortcuts
 * 6. ThemeProvider           — theme
 * 7. LineNumbersProvider     — line-numbers display (shared, like theme)
 *    + NavigationHandler
 */
export function Providers({ children }: { children: React.ReactNode }) {
  const translationManager = useMergedTranslationManager();

  return (
    <TranslationProvider translationManager={translationManager}>
      <XynoplexProvider>
        <ToastProvider>
          <LiveRegionProvider>
            <KeyboardShortcutsProvider>
              <ThemeProvider>
                <LineNumbersProvider>
                  <NavigationHandler />
                  {children}
                </LineNumbersProvider>
              </ThemeProvider>
            </KeyboardShortcutsProvider>
          </LiveRegionProvider>
        </ToastProvider>
      </XynoplexProvider>
    </TranslationProvider>
  );
}
