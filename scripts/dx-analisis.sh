#!/usr/bin/env bash
# Resume docs/dx/registro.csv: mediana por escenario y modalidad (tiempo, acciones, cambios de
# herramienta, errores) y diferencia porcentual de la mediana IDP frente a la manual.
# Solo usa repeticiones con estado final verificado = si. Uso: scripts/dx-analisis.sh [fichero.csv]

source "$(dirname "$0")/lib.sh"
csv="${1:-${REPO_ROOT}/docs/dx/registro.csv}"
[[ -f "${csv}" ]] || die "no existe ${csv}"

awk -F, '
function median(arr, n,   i, j, t, s) {
  for (i = 1; i <= n; i++) s[i] = arr[i]
  for (i = 2; i <= n; i++) { t = s[i]; for (j = i - 1; j >= 1 && s[j] > t; j--) s[j+1] = s[j]; s[j+1] = t }
  return (n % 2) ? s[(n+1)/2] : (s[n/2] + s[n/2+1]) / 2
}
NR > 1 && $10 == "si" {
  k = $1 SUBSEP $2; n[k]++
  t[k, n[k]] = $6; a[k, n[k]] = $7; c[k, n[k]] = $8; e[k, n[k]] = $9
  esc[$1] = 1
}
END {
  printf "%-9s %-7s %3s %10s %9s %9s %9s\n", "escenario", "modo", "n", "t_med(s)", "acc_med", "cambios", "errores"
  for (s in esc) for (m = 1; m <= 2; m++) {
    mode = (m == 1) ? "manual" : "idp"; k = s SUBSEP mode
    if (!n[k]) continue
    for (i = 1; i <= n[k]; i++) { T[i] = t[k,i]; A[i] = a[k,i]; C[i] = c[k,i]; E[i] = e[k,i] }
    mt[k] = median(T, n[k])
    printf "%-9s %-7s %3d %10.1f %9.1f %9.1f %9.1f\n", s, mode, n[k], mt[k], median(A, n[k]), median(C, n[k]), median(E, n[k])
  }
  print ""
  for (s in esc) {
    km = s SUBSEP "manual"; ki = s SUBSEP "idp"
    if (n[km] && n[ki]) printf "%s: mediana IDP vs manual = %+.1f %% (negativo = IDP más rápido; n=%d/%d)\n", s, (mt[ki] - mt[km]) / mt[km] * 100, n[ki], n[km]
    else printf "%s: faltan repeticiones verificadas en alguna modalidad\n", s
  }
}' "${csv}"
