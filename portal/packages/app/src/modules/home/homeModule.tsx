import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { HomePageWidgetBlueprint } from '@backstage/plugin-home-react/alpha';
import { MarkdownContent } from '@backstage/core-components';

const content = `
## Portal de la plataforma

Punto de entrada único a los servicios de la organización: qué existe, quién es su
responsable, dónde está desplegado y cómo se documenta.

### Qué puedes hacer

- **Explorar el [catálogo](/catalog)**: servicios, sistemas, equipos y su propietario.
- **Leer la [documentación](/docs)** de cada servicio, generada desde su repositorio.
- **Consultar el despliegue**: cada servicio enlaza a su configuración GitOps y a sus
  entornos \`dev\` y \`staging\`.

### Cómo llega un cambio a los entornos

1. El código vive en el repositorio del servicio (\`svc-<nombre>\`); cada push a \`main\`
   publica una imagen etiquetada con el SHA del commit.
2. El despliegue se describe en \`idp-tfg/gitops/apps/<servicio>\`: promocionar es abrir un PR
   que cambia esa etiqueta en el overlay del entorno.
3. Argo CD aplica lo que está en Git; para volver atrás, \`git revert\`.
`;

const gettingStartedWidget = HomePageWidgetBlueprint.make({
  name: 'getting-started',
  params: {
    name: 'GettingStarted',
    title: 'Primeros pasos',
    description: 'Qué es el portal y cómo se despliega un servicio',
    components: async () => ({
      Content: () => <MarkdownContent content={content} />,
    }),
  },
});

export const homeModule = createFrontendModule({
  pluginId: 'home',
  extensions: [gettingStartedWidget],
});
