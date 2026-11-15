import { useTranslation } from 'react-i18next';
import { LeftSidebar, useXynolog, useObservable } from '@xynolog/react-ui';
import { KnowledgeNavigation } from './KnowledgeNavigation';
import { Link, routes } from '@/lib/routing';

export function KnowledgeSidebarWrapper() {
  const { t } = useTranslation(undefined, { keyPrefix: 'Navigation' });
  const { t: tHome } = useTranslation(undefined, { keyPrefix: 'Home' });
  const session = useObservable(useXynolog().activeSession$);
  const user = useObservable(session?.user$);
  const isAuthenticated = !!user;

  return (
    <LeftSidebar
      Link={Link}
      routes={routes}
      t={t}
      tHome={tHome}
      brandingLink="/"
      collapsible={true}
      storageKey="knowledgeNavCollapsed"
      isAuthenticated={isAuthenticated}
    >
      {(isCollapsed, toggleCollapsed, navigationMenu) => (
        <KnowledgeNavigation
          isCollapsed={isCollapsed}
          toggleCollapsed={toggleCollapsed}
          navigationMenu={navigationMenu}
        />
      )}
    </LeftSidebar>
  );
}
