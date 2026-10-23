# fix.md — Controle de melhorias da edição LabsObjects

Documento de controle das correções e soluções criadas nesta versão
(Open Watcom V2 — LabsObjects Edition, `Version 2.0.1` em 09/10/2026).
Só contém melhorias **reais e verificadas** desta pipeline — nada aqui foi
inventado: cada item referencia a FASE de `marco.md` onde foi feito e
validado, mais os arquivos tocados.

**Regra permanente:** toda melhoria nova nesta edição deve ser registrada
neste arquivo (novo item na próxima seção livre + referência à FASE).
Modelo no final do documento.

Estado geral em 09/10/2026: `rel/binnt` 81 `.exe` 0 zerados,
`rel/lib386/nt/*.lib` 0 zerados, `build/test_examples.bat` `PASS=4 FAIL=0`,
suítes `ctest` 4/5 e `plustest` 23 PASS (deltas pré-existentes, FASE 29).

---

## 1. Sistema de build / bootstrap (GCC → auto-hospedagem)

| ID | Melhoria | Arquivos | Ref |
|----|----------|----------|-----|
| FIX-001 | `mingwmake`: build do `wmake.exe` com GCC/MinGW no Windows (`__NT__`, flags MinGW) | `bld/wmake/mingwmake` | FASE 1 |
| FIX-002 | `preboot`: 4º caminho GCC/MinGW no bloco `__NT__` (via `__GNUC__`) → `builder.exe` sem Visual C++ | `bld/builder/preboot` | FASE 2 |
| FIX-003 | `cpuoscfg.mif`: `bld_os_nt = 1` p/ `__GCC_TOOLS__` (sem isso todo target NT era pulado via `skip_build`) | `build/mif/cpuoscfg.mif` | FASE 3 |
| FIX-004 | `local.mif`: bloco GCC/Clang p/ NT (`-D__NT__`, `-m64`, ext `.dll`, extra ldflags, `bld_c_flags`) | `build/mif/local.mif` | FASE 4 |
| FIX-005 | `local.mif:509`: guarda `defined(__GCC_TOOLS__)` — elimina `E59 !IF Parse Error` no boot | `build/mif/local.mif` | FASE 8.1 |
| FIX-006 | `local.mif:451`: `-gz` só fora do NT via `host_os`/`bld_os` (não via `__NT__` indefinido no escopo) | `build/mif/local.mif` | FASE 8.2 |
| FIX-007 | Detecção do toolchain GCC em `cmnvars.bat` + `setvars_gcc.bat` (`OWTOOLS=GCC`) | `cmnvars.bat`, `setvars_gcc.bat` | FASE 0 |
| FIX-008 | Causa raiz `zq`: `BOOTSTRAP_CPU=386` + `BOOTSTRAP_OS=nt` nos 15 `.bat` de `build/` (host x64 não tem toolchain `bcl_x64`) + aliases `*_x64` → `386` em `cproj.mif`/`local.mif` | `build/*.bat`, `build/mif/cproj.mif`, `build/mif/local.mif` | FASE 18, 27.3 |
| FIX-009 | `wfile.hpp`: `#include <stdio.h>` (`SEEK_SET` quebrava o boot no GCC) | `bld/wclass/hpp/wfile.hpp` | FASE 18 |
| FIX-010 | `OWROOT` corrigido p/ o caminho real em `build_full`, `setvars_*`, `autohost*` | raiz + `build/` | FASE 18 |
| FIX-011 | `wlink.lnk` ausente → overlay `build/bwlink.lnk` → arquivo final curado em `rel/binnt/` (blocos 286/386 + `nt` com `%WATCOM%`) + remoção da linha-marcador que gerava `E3033` | `bld/wl/lnk/specs.sp`, `rel/binnt/wlink.lnk` | FASE 15.1b, 31.2 |
| FIX-012 | Infra `builder rel` documentada e funcional (makeinit via PATH, pmake embutido, `WLINK_LNK`) | `build/*.bat` (env) | FASE 15.1c |
| FIX-013 | `OWNEWWGML=1` nos 15 `.bat` (wgml nativo 64-bit; sem DOSBOX p/ `.gh` de help e docs) | `build/*.bat` | FASE 21.3, 24, 26.2 |
| FIX-014 | `.gitignore` += `*.tds` (ruído de build; `/build/*.bat` NÃO ignorado de propósito) | `.gitignore` | FASE 20.2, 26.2 |

## 2. Runtime libraries (CRT / math / C++ / Fortran)

| ID | Melhoria | Arquivos | Ref |
|----|----------|----------|-----|
| FIX-020 | `clib` perfilada `mf_rp`: 28 subprojetos + merged `clib3r.lib` + `export.gdf` via override `linkage=dynamic` + `clbrp.dll`; `builder.ctl` com deploy `clib3rp.lib` | `bld/clib/**`, `bld/clib/builder.ctl` | FASE 15 |
| FIX-021 | Math dentro da CRT DLL: `math_export.gdf` + `dll_libs`/`dll_def` em `objs.mif` → `sqrt/sin/cos/exp/log` exportados por `clbr20.dll` | `bld/clib/rtdll/winnt.386/objs.mif` | FASE 13 |
| FIX-022 | Diagnóstico FPU: inline FPU do compilador bootstrap dá NaN no WOW64; workaround `-fpc` documentado | docs (`marco.md`, `README.md`) | FASE 13.7 |
| FIX-023 | 6 variantes rtdll A–F (`clbs/mths/mt7r/mt7s/plbr/plbs20.dll` + import libs): `export.gdf` do `mf_s`, conversão register→stack do `math_export.gdf` (220 símbolos), rebuild limpo `math3s.lib`, `rel/` sincronizadas; prova funcional `-ms -br` e `-br` C++ | `bld/clib/`, `bld/mathlib/`, `bld/cpplib/` (rtdll) | FASE 27.1 |
| FIX-024 | `mathlib` estáticas `mf_s` + `winnt.387/mf_r/mf_s` (`math3s`, `math387r/s.lib`) | `bld/mathlib/library/*` | FASE 15.2, 15.3 |
| FIX-025 | Fortran `.rtd` destravado via `mt7rdll.lib` (faltava a import lib MT) → `wfc/386/nt386.rtd` linka (`WFC_RTD_RC=0`) | `rel/lib386/nt/` (artefato) | FASE 25.2, 27.2 |
| FIX-026 | `cpplib` NT (`plib3r/s`, `plbx3r/s.lib`) + validação `hello.cpp` | `bld/cpplib/`, `rel/lib386/nt/` | FASE 14 |

## 3. Ferramentas e drivers (linker, libs de build, Fortran)

| ID | Melhoria | Arquivos | Ref |
|----|----------|----------|-----|
| FIX-030 | `wlink`: `MakeToken` aceita `"` em paths com espaço + receita `libpath` p/ `emu387.lib` (`W1008`) | `bld/wl/c/cmdutils.c` (+ docs) | FASE 15.6 |
| FIX-031 | `wfl`: `ListAppend`/`ListAppendString` zeram `next` — elimina o crash pós-compilação (cauda da `File_List` com garbage) | `bld/f77/wfl/c/wfl.c` | FASE 31.3, 32.1 |
| FIX-032 | `wfl` `Parse`: `-`/`/` no meio do token fazem parte do nome (paths com `-`, valores `-fe=C:\a-b`); aspas de fechamento puladas (`"arq" -op`) | `bld/f77/wfl/c/wfl.c` | FASE 32.2 |
| FIX-033 | Receita `-ms` sem bug: `system nt` (sem `library` explícita) p/ C e C++ estático/`-br` — só documentação, sem tocar codegen | `README.md` | FASE 31.2 |
| FIX-034 | Reativação 16-bit/RISC nos `builder.ctl` (`i86` em cc/plusplus/cg, `axp/mps/ppc`) + tags `target_axp`/`target_i86` + ordem `dwarf` antes do `cgi86` | `bld/cc`, `bld/plusplus`, `bld/cg/*/builder.ctl` | FASE 19 |
| FIX-035 | `vi/viw`: dependência `rcsdll` construída (`rcsdll.dll/.lib`) | `bld/rcsdll`, `bld/vi` | FASE 21.1 |
| FIX-036 | `browser`: host-tool `dlgprs` construído manualmente (padrão `binmake`+`bld_os/cpu`) | `bld/browser/dlgprs`, `build/binbuild/` | FASE 21.2 |
| FIX-037 | Fortran: host-tool `errsrc` via `builder boot` (bloco `BINTOOL`) → `f77lib` (`flib/flibs/flib7/flib7s`) + `wfc/wfl` | `bld/f77/utils`, `bld/f77` | FASE 25 |
| FIX-038 | `aui.lib` construída (destravou `wv`/`wprof`) | `bld/aui` | FASE 22.1 |
| FIX-039 | SDK: `wr`, `fmedit`, `wresedit` (`wr/fmedit/wacc/wmenu/wstring`) → `wre/wde/imgedit/spy/zoom/ddespy` | `bld/sdk/*` | FASE 23.1 |
| FIX-040 | DLLs das ferramentas (`wccd386/wppd386/wlinkd/wrcd/weditcw/weditviw`) via tags `target_386`/`dll`/`guitool` (+ `.rtd` de quebra) | `bld/cc`, `bld/plusplus`, `bld/wl`, `bld/rc`, `bld/editdll` | FASE 28 |
| FIX-041 | `trap`: ordem `dip→mad→trap→aui→wv`; `tcp` via `wmake` direto; variante `ntx64` documentada fora do escopo `binnt` | `bld/dip`, `bld/mad`, `bld/trap`, `bld/wv` | FASE 22 |

## 4. Distribuição, versionamento e validação

| ID | Melhoria | Arquivos | Ref |
|----|----------|----------|-----|
| FIX-050 | Auto-versão `2.0.N`: `build/version.bin` + `build/bumpver.bat` + `_BLDVER_PATCH` em `banner.h`/`cproj.mif` (atual `2.0.1`) | `build/`, `bld/watcom/h/banner.h`, `build/mif/cproj.mif` | FASE 31.1 |
| FIX-051 | `build/test_examples.bat`: `[1-3]` C/C++/math + `[4/4]` Fortran via `wfl386` → `PASS=4 FAIL=0` | `build/test_examples.bat`, `examples/hello.for` | FASE 19.3, 30, 32.3 |
| FIX-052 | Infra `ctest`/`plustest`: `testutil` via boot, overrides `CTEST_WCC_386`/`PLUSTEST_WPP_386` + `linker` absoluto (quirk `E14` sem editar fontes); vereditos por suíte | `bld/testutil`, `bld/ctest`, `bld/plustest` | FASE 29 |
| FIX-053 | README LabsObjects (uso C/C++/Fortran, build por partes, layout) + `examples/hello.for` + adendo `license.txt` | `README.md`, `license.txt` | FASE 30, 32.3 |
| FIX-055 | Pêndulos `plustest` com veredito: `cool` (tests+examples, test0–3), `torture`/`perl`/`stl.95` (test0–1), `stl.94` demo+examples — todos PASS; overrides `wlib_any` absoluto (mesmo quirk E14 do `linker`), `CTEST_WCC_386` p/ o passo C do `perl`, subdirs p/ `cool`/`stl.94` (pai dá F05); RC=5 pós-PASS é quirk do `%append` final, não falha | `bld/plustest/*/*.log` (vereditos; sem editar fontes) | FASE 34 |
| FIX-054 | Instaladores `c` + `f77` rebuildados sem `.exe` zerados (`DISTRIB_RC=0`) | `distrib/ow/bin/` | FASE 26.3, 27.4, 28.3 |
| FIX-060 | `ctx.exe` (diário de código) integrado à pipeline como **opcional**: `ctx init` no repo + `build/ctx_log.bat` (no-op `RC=0` sem a ferramenta) + chamadas em `test_examples.bat` (4 exes) e `distrib_build.bat` (instaladores); snippet de ignore p/ `.ctx.yaml` | `.ctx.yaml`, `.ctx/`, `build/ctx_log.bat`, `build/test_examples.bat`, `build/distrib_build.bat`, `.gitignore` | FASE 33 |
| FIX-061 | `ctx` Fase A+B: `ctx_mem.bat` (veredito da suíte/distro), `ctx_checkpoint.bat` (`audit checkpoint` pós-distro), `ctx_smells.bat` (`smells --file` nos fontes fixados `wfl.c`/`cmdutils.c`, `total=0`); tudo no-op `RC=0` sem a ferramenta, validado `PASS=4 FAIL=0` com e sem ctx | `build/ctx_mem.bat`, `build/ctx_checkpoint.bat`, `build/ctx_smells.bat`, `build/test_examples.bat`, `build/distrib_build.bat` | FASE 35 |
| FIX-062 | `wfc386` aceita `-fo=` com `-` e aspas: removido o `break` por switch-char no meio do token em `MainCmdLine` (opção nova só após espaço, mesmo padrão do fix `wfl` FASE 32) + strip de aspas ao redor do valor em `FOOption`; rebuild `wfc/wfc386` (`RC=0`, incl. `.rtd`) + `cprel`; `smells total=0` nos 2 arquivos | `bld/f77/wfc/c/sdcline.c`, `bld/f77/wfc/c/option.c`, `rel/binnt/wfc.exe`, `rel/binnt/wfc386.exe` | FASE 36 |
| FIX-063 | `CP-09 dynamic memory not freed` eliminado (causa raiz, não supressão): `FiniPragmaAux` agora libera `objname/parms` dos 4 pragmas pré-definidos (`Syscall/Stdcall/Pascal/CdeclInfo`, fora do `AuxList`); prova TRMEM antes `8 chunks/43 bytes` → depois `0 unfreed` (`mem.trk` 0 bytes); saída do `wfc386`/`wfl386` limpa; `smells total=0` | `bld/f77/wfc/c/wf77aux.c`, `rel/binnt/wfc386.exe` | FASE 37 |
| FIX-064 | `ctx` Fase C: `ctx_audit_full.bat` on-demand (`verify` + `health` + `audit/build list` em `build/tmp_audit/`); `verify` tudo ok, `health 84/100 (B)`; `review` excluído (exige git, repo não tem — erro 129), `smells --security/--lint` e scan/full excluídos (timeout >120s); sempre `RC=0`, no-op sem ctx | `build/ctx_audit_full.bat` | FASE 39 |
| FIX-065 | Versão 2.0.5: `version.bin` 1→5 (4× `bumpver`, 1 por rebuild perdido: wfl F32, wfc F36/F37, wlink) + rebuild limpo `wl`/`wfc`/`wfl` com `OWBLDVER_PATCH=5` + `cprel`; banners `wlink/wfc/wfc386/wfl/wfl386` em 2.0.5 (`_WLINK_VERSION_=BAN_VER_STR` confirmado); `wcc/wpp` ficam 2.0.1 até pipeline cheia; `PASS=4 FAIL=0` | `build/version.bin`, `rel/binnt/wlink*.exe/*.dll`, `rel/binnt/wfc*.exe`, `rel/binnt/wfl*.exe` | FASE 40 |
| FIX-066 | Item 4 FPU fechado sem código novo (diagnóstico prova que toolchain está correta): `-fpi` (default) + default-libs do `.obj` (`math387r`) e `-fpc` + `math3r` são os combos consistentes (ambos provados corretos); forçar `math3r` em objeto `-fpi` mistura convenções (regs vs x87) e retorna o input — era essa a causa dos 2.0/NaN, não o codegen nem o WOW64; `math3r.lib` rebuildada self-host + `rel/` sincronizada; guarda `ifprag.h` experimental revertida (upstream-idêntica) | `rel/lib386*/math3r.lib`, docs | FASE 41 |
| FIX-067 | Instaladores rebuildados pós-FASE 36–41: `c` (18.713.909 bytes) + `f77` (14.534.857 bytes), `DISTRIB_RC=0`, com `wlink/wfc/wfl` 2.0.5 + `math3r` self-host + `wlink.lnk` curado; regressão `PASS=4 FAIL=0` pré+pós-distro; diary `BUILD-00044/45` (instaladores) + `00046–49` (regressão); `wcc` 2.0.1 e driver `wpp` 2.0 unificam na próxima pipeline cheia | `distrib/ow/bin/` | FASE 42 |
| FIX-068 | Item 6 fechado sem código novo (veredito, não fix): os 4 FAILs do `plustest positive` são pré-existentes — float03 exige `==`→0 p/ literais que são o mesmo double em IEEE-754 (prova gcc `0x1.c71c71c71c71cp-4`; invariante a `-ox/-fpc/-zfp/-ms`); i6403 de escada `__int64`/ULL-vs-UI64; opt03 de null-check dobrado pelo `-ox`; setjmp03 só no link `-br` da suite (`targ_br_wnt386`, estático passa); suite real re-rodada REL vs BW com `.outs` byte-idênticos (`fc` sem diferenças) | docs | FASE 43 |
| FIX-069 | Unificação `wcc`/`wpp` em 2.0.6: `version.bin` 5→6 (1× `bumpver`) + rebuild limpo `cc`/`plusplus` (`386/nt386.dll`, `386/nt386.rtd`, `i86/nt386.dll`; `target_386`+`target_i86`, todos `RC=0`) + `cprel`; drivers `wcc386/wpp386/wcc/wpp` em 2.0.6 com DLLs rebuildadas; `PASS=4 FAIL=0` com os compiladores novos + instaladores rebuildados (`DISTRIB_RC=0`) | `rel/binnt/wcc*.exe`, `rel/binnt/wpp*.exe`, `rel/binnt/wccd*.dll`, `rel/binnt/wppd*.dll`, `distrib/ow/bin/` | FASE 44 |

## 5. Limites conhecidos (documentados, não são regressão)

- Docs `.hlp/.cnt/.chm`: exigem HHC/Help Workshop (fora de escopo local). (FASE 26.4)
- Suítes `cool/torture/stl/perl` e dirs auxiliares do `plustest`: harness próprio / `F05`. (FASE 29)
- `ctest diagnose`: 2 deltas provados upstream-idênticos (W115 desligado no fonte + E1046 off-by-one com input byte-idêntico) — veredito FASE 38: não tocar compilador nem expectativa (divergência unilateral seria anti-produção).
- `wfc386` com `-fo=` com `-`/aspas: **corrigido** (FIX-062, FASE 36) — sem
  contorno necessário.
- `wcc -ms` cru + `form windows nt` + `library` explícita (`main` vs `main_`): usar `system nt`. (FASE 27.1, 31.2)
- Conflito de entry points EXE vs DLL em rtdll perfilada (`E2030`, FASE 15.8/17.1): só afeta profiling com runtime DLL.
- `trap/*/ntx64.trp` e `binl/binp`: outras plataformas / `binnt64`, fora do escopo `binnt`. (FASE 22.2)
- `*ERR* CP-09 dynamic memory not freed` do `wfc386`/`wfl386`: **corrigido**
  (FIX-063, FASE 37) — era vazamento real dos pragmas pré-definidos.

---

## 6. Uso do ctx.exe (diário de código, opcional)

- Requer `ctx.exe` no `PATH` (ex.: `C:\ctx\ctx\bin`). **Sem ele, tudo
  builda igual**: `build/ctx_log.bat` detecta via `where` e sai `RC=0`
  silencioso — validado `PASS=4 FAIL=0` com e sem a ferramenta.
- Com ele: cada run da suíte grava 4 proveniências (`hello`, `hello_cpp`,
  `math`, `wfl_hello`) + 1 memória de veredito (`PASS/FAIL`) + 2 `smells`
  (`wfl.c`, `cmdutils.c`, ambos `total=0`) e cada `distrib_build` grava os
  instaladores + 1 memória + 1 `audit checkpoint`, tudo
  em `.ctx/` (local, `--offline`, sem rede).
- Consultar: `ctx --offline build list` (com CWD no repo).
- Registro manual: `ctx --offline memory add ...`, `ctx --offline decision
  add --title ... --decision ... --rationale ...`, `ctx --offline bugs ...`.
- Detalhes de funcionamento e armadilhas (store por diretório, `pushd` no
  wrapper, `%%~fF` no loop): `marco.md` FASE 33.
- Fase C (`marco.md` FASE 39): `build/ctx_audit_full.bat` on-demand com
  `verify` + `health` (rápidos, `RC=0` sempre); `review` e scan/full fora
  (sem git / timeout).

## Modelo para registrar nova melhoria

```md
| FIX-0xx | Título curto: o que mudou e o efeito | arquivos | FASE nn |
```

Detalhar em `marco.md` (FASE nova) e referenciar aqui. Nunca registrar
melhoria não executada/validada — este arquivo é documento de controle.
