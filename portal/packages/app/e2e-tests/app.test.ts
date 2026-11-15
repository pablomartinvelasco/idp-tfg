import { test, expect } from '@playwright/test';

// El portal exige identidad de GitHub (ADR-0007). Sin sesión debe mostrar el inicio de sesión
// de GitHub y NO ofrecer el acceso de invitado. El flujo completo con OAuth no se automatiza:
// requiere una cuenta real y se registra manualmente en docs/pruebas.md (PA-06, PA-07).
test('Sin sesión, el portal ofrece solo el inicio de sesión con GitHub', async ({
  page,
}) => {
  await page.goto('/');

  await expect(page.getByRole('heading', { name: 'Portal IDP' })).toBeVisible();
  await expect(page.getByText('Inicia sesión con tu cuenta de GitHub')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
  // Ninguna vía de acceso sin identidad (ADR-0007).
  await expect(page.getByRole('button', { name: 'Enter' })).toHaveCount(0);
  await expect(page.getByText('Guest')).toHaveCount(0);
});
