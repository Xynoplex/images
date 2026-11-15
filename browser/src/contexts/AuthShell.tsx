/**
 * AuthShell — the part of the provider tree that requires authentication.
 *
 * Mounts the protected error boundary and the session modals (session
 * ended, permission denied, KB identity conflict).
 * The session state (KB list, active KB, per-KB XynologSession) is owned
 * by the module-scoped `XynologBrowser` singleton, made available via
 * `<XynologProvider>` at the app root; the modals read the active
 * `SessionSignals`.
 *
 * `ProtectedLayout` in App.tsx mounts this once above the authenticated
 * sections (know/, moderate/). Do NOT mount it at the locale layout
 * level — pre-app routes (landing, OAuth flow) have no session UI.
 */

import React from 'react';
import { useLocation } from 'react-router';
import {
  ProtectedErrorBoundary,
  SessionEndedModal,
  PermissionDeniedModal,
  KbIdentityConflictModal,
} from '@xynolog/react-ui';

export function AuthShell({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  return (
    <ProtectedErrorBoundary resetKeys={[location.pathname]}>
      <SessionEndedModal />
      <PermissionDeniedModal />
      <KbIdentityConflictModal />
      {children}
    </ProtectedErrorBoundary>
  );
}
