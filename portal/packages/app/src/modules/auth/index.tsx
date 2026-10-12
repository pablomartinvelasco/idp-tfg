import { SignInPage } from '@backstage/core-components';
import {
  createFrontendModule,
  githubAuthApiRef,
} from '@backstage/frontend-plugin-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';

// Inicio de sesión con GitHub (ADR-0007). El backend solo emite identidad para cuentas que
// existen como User en el catálogo; el resto de cuentas de GitHub no puede entrar.
const githubSignInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props =>
      (
        <SignInPage
          {...props}
          title="Portal de la plataforma"
          align="center"
          auto
          provider={{
            id: 'github-auth-provider',
            title: 'GitHub',
            message: 'Inicia sesión con tu cuenta de GitHub',
            apiRef: githubAuthApiRef,
          }}
        />
      ),
  },
});

export const authModule = createFrontendModule({
  pluginId: 'app',
  extensions: [githubSignInPage],
});
