import {
  createUnifiedTheme,
  palettes,
  PageTheme,
  UnifiedTheme,
} from '@backstage/theme';

// Identidad visual del portal de la IDP: verde azulado como color de marca sobre neutros pizarra.
// Sin las formas decorativas de las cabeceras por defecto: un panel interno debe leerse rápido.
const brand = {
  teal: '#0F766E',
  tealLight: '#2DD4BF',
  slate: '#0F172A',
  slateMid: '#1E293B',
  slateText: '#334155',
};

// Curva ease-out marcada para respuestas inmediatas a la interacción (≤ 200 ms).
const easeOut = 'cubic-bezier(0.23, 1, 0.32, 1)';

function pageTheme(from: string, to: string): PageTheme {
  return {
    colors: [from, to],
    shape: 'none',
    backgroundImage: `linear-gradient(90deg, ${from}, ${to})`,
    fontColor: '#FFFFFF',
  };
}

const pageThemes: Record<string, PageTheme> = {
  home: pageTheme(brand.slate, brand.teal),
  documentation: pageTheme(brand.slateMid, '#0E7490'),
  tool: pageTheme(brand.slateMid, '#4338CA'),
  service: pageTheme(brand.slate, brand.teal),
  website: pageTheme(brand.slate, '#0369A1'),
  library: pageTheme(brand.slate, '#6D28D9'),
  other: pageTheme(brand.slate, brand.slateText),
  app: pageTheme(brand.slate, brand.teal),
  apis: pageTheme(brand.slate, '#B45309'),
  card: pageTheme(brand.slate, brand.teal),
};

const fontFamily =
  'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';

// Retroalimentación de pulsación: escala sutil, solo transform y color, nunca `all`.
const components = {
  MuiButtonBase: {
    styleOverrides: {
      root: {
        transition: `transform 160ms ${easeOut}, background-color 150ms ease, color 150ms ease`,
        '&:active': { transform: 'scale(0.97)' },
        '@media (prefers-reduced-motion: reduce)': {
          transition: 'background-color 150ms ease, color 150ms ease',
          '&:active': { transform: 'none' },
        },
      },
    },
  },
  MuiCard: {
    styleOverrides: { root: { borderRadius: 8 } },
  },
  MuiPaper: {
    styleOverrides: { rounded: { borderRadius: 8 } },
  },
};

export const idpLightTheme: UnifiedTheme = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: brand.teal },
    secondary: { main: '#4338CA' },
    navigation: {
      ...palettes.light.navigation,
      background: brand.slate,
      indicator: brand.tealLight,
      selectedColor: '#FFFFFF',
      color: '#CBD5E1',
      navItem: { hoverBackground: brand.slateMid },
    },
  },
  fontFamily,
  defaultPageTheme: 'home',
  pageTheme: pageThemes,
  components,
});

export const idpDarkTheme: UnifiedTheme = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: { main: brand.tealLight },
    secondary: { main: '#A5B4FC' },
    navigation: {
      ...palettes.dark.navigation,
      background: '#020617',
      indicator: brand.tealLight,
      selectedColor: '#FFFFFF',
      color: '#94A3B8',
      navItem: { hoverBackground: brand.slateMid },
    },
  },
  fontFamily,
  defaultPageTheme: 'home',
  pageTheme: pageThemes,
  components,
});
