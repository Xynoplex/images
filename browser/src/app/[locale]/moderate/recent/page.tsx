import { useTranslation } from 'react-i18next';
import { Toolbar } from '@xynoplex/react-ui';
import { ToolbarPanels } from '@/components/toolbar/ToolbarPanels';
import { useTheme, useShellStateUnit, useObservable } from '@xynoplex/react-ui';
import { RecentDocumentsPage } from '@xynoplex/react-ui';

export default function RecentDocumentsPageWrapper() {
  const { t } = useTranslation(undefined, { keyPrefix: 'ModerateRecent' });

  // Toolbar and settings state
  const browseStateUnit = useShellStateUnit();
  const activePanel = useObservable(browseStateUnit.activePanel$) ?? null;
  const { theme } = useTheme();



  return (
    <RecentDocumentsPage
      isLoading={false}
      theme={theme}
      activePanel={activePanel}
      translations={{
        pageTitle: t('pageTitle'),
        pageDescription: t('pageDescription'),
        sectionTitle: t('sectionTitle'),
        sectionDescription: t('sectionDescription'),
        noDocuments: t('noDocuments'),
        activityWillAppear: t('activityWillAppear'),
        loading: t('loading'),
      }}
      ToolbarPanels={ToolbarPanels}
      Toolbar={Toolbar}
    />
  );
}
