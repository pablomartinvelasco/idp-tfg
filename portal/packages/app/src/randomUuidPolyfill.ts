// El laboratorio sirve el portal por HTTP en portal.localtest.me (ADR-0005), que el navegador no
// considera contexto seguro: allí crypto.randomUUID no existe y la comprobación de permisos del
// frontend (p. ej. la pestaña Kubernetes) falla antes de llegar al backend. crypto.getRandomValues
// sí está disponible, así que se define randomUUID (RFC 4122, versión 4) solo si falta.
if (typeof globalThis.crypto !== 'undefined' && !globalThis.crypto.randomUUID) {
  Object.defineProperty(globalThis.crypto, 'randomUUID', {
    configurable: true,
    value: (): `${string}-${string}-${string}-${string}-${string}` => {
      const b = globalThis.crypto.getRandomValues(new Uint8Array(16));
      b[6] = (b[6] & 0x0f) | 0x40;
      b[8] = (b[8] & 0x3f) | 0x80;
      const h = Array.from(b, x => x.toString(16).padStart(2, '0')).join('');
      return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}` as `${string}-${string}-${string}-${string}-${string}`;
    },
  });
}
