<p align="center">
  <img src="OpenWatcom.png" alt="Open Watcom V2 — LabsObjects Edition" width="240">
</p>

# Open Watcom V2 — LabsObjects Edition (Version 2.0.7)

> Sabor Windows x64 da Open Watcom V2, mantido pela **LabsObjects**:
> toolchain C/C++/FORTRAN 32-bit completa e auto-hospedada, construída
> com GCC/MinGW bootstrap + auto-hospedagem (`builder boot`/`rel`).
> Proposta: distribuição pronta para uso em Windows 10/11 x64, sem
> targets 16-bit/DOS/OS/2, com validação por suítes de regressão.
> Pipeline completa documentada em [`marco.md`](marco.md) (FASEs 0–46);
> regras de contribuição em [`skill.md`](skill.md).

## Estado desta edição

- `rel/binnt/`: **81 `.exe`, 0 zerados** — compiladores (`wcc386`,
  `wpp386`, `wfc386`), linker, assembler, debugger (`wd`/`wdw` + trap
  servers), IDE, `vi`, browser, ferramentas GUI/SDK e Fortran.
- Runtime completo: `clib3r/s`, `math3r/s`, `math387r/s`, `plib3r/s`,
  DLLs `clbr20`, `clbs20`, `mthr20`, `mths20`, `mt7r20`, `mt7s20`,
  `plbr20`, `plbs20` + import libs (incl. variantes MT).
- Layout upstream driver+DLL (`wccd386`, `wppd386`, `wlinkd`, `wrcd`,
  `weditcw/viw`) — banners `Version 2.0.<N>` (nesta build: `wcc`/`wpp`
  (32 e 16-bit), `wlink`, `wmake` e `wrc` em **2.0.7**; `wfc`/`wfl` em
  2.0.5 — unificam na próxima pipeline de Fortran;
  auto-incremento por build: `build/version.bin` + `build/bumpver.bat`).
- Validação: `build/test_examples.bat` (`PASS=4 FAIL=0`: C, C++,
  math `-fpc`, Fortran via `wfl386`), suítes `ctest` (4/5) e `plustest`
  (23 suítes PASS; deltas pré-existentes documentados em `marco.md`
  FASE 29). Detalhe dos fixes desta edição em [`fix.md`](fix.md).
- Instaladores: `distrib/ow/bin/open-watcom-2_0-c-win-x86.exe` (C/C++) e
  `open-watcom-2_0-f77-win-x86.exe` (Fortran).
- Notas: `OWNEWWGML=1` (wgml nativo 64-bit, sem DOSBOX); docs
  `.hlp/.chm` exigem HHC (fora de escopo local).
- Diário opcional: `ctx.exe` no PATH ativa proveniência local (`.ctx/`)
  via `build/ctx_log.bat`; sem ele tudo builda igual (ver `fix.md` FIX-060).
- Licença: [Sybase Open Watcom Public License + adendo LabsObjects](license.txt).

## Uso rápido (toolchain pronta em `rel/`)

```batch
REM Configurar ambiente (uma vez por sessão)
set WATCOM=C:\caminho\rel
set PATH=%WATCOM%\binnt;%PATH%
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
```

### Exemplo C (`examples/hello.c`)

```batch
wcc386 hello.c -fo=hello.obj -s
wlink form windows nt name hello.exe file hello.obj ^
  libpath %WATCOM%\lib386 libpath %WATCOM%\lib386\nt ^
  library clib3r.lib,kernel32.lib,user32.lib
hello.exe
```

Atalho em 1 passo: `wcl386 hello.c -fe=hello.exe`.

### Exemplo C++ (`examples/hello.cpp`)

```batch
wpp386 hello.cpp -fo=hello.obj -s
wlink form windows nt name hello.exe file hello.obj ^
  libpath %WATCOM%\lib386 libpath %WATCOM%\lib386\nt ^
  library plib3r.lib,clib3r.lib,kernel32.lib,user32.lib
hello.exe
```

### Exemplo Fortran (`examples/hello.for`)

```batch
wfc386 hello.for -fo=hello.obj
wlink form windows nt name hello.exe file hello.obj ^
  libpath %WATCOM%\lib386 libpath %WATCOM%\lib386\nt ^
  library flib.lib,math387r.lib,math3r.lib,clib3r.lib,^
    kernel32.lib,user32.lib
hello.exe
```

Atalho em 1 passo (driver corrigido nesta edição, ver `fix.md`):
`wfl386 hello.for -fe=hello.exe`. O `wfc386` também aceita `-fo=` com
`-`/aspas desde FIX-062. Para math, use um dos combos consistentes (ver `marco.md`
FASE 41): default (`-fpi`) + default-libs do `.obj` (`math387r`), ou
C com `-fpc` + `math3r.lib` — nunca force `math3r` em objeto `-fpi`.

### Validar a instalação

```batch
build\test_examples.bat
rem esperado: PASS=4 FAIL=0
```

## Build a partir do fonte

Pré-requisitos: Windows 10/11 x64 + GCC/MinGW-w64 + GNU Make.
Ordem dos scripts (todos em `build/`, com `BOOTSTRAP_CPU=386` e
`OWNEWWGML=1` já configurados):

1. `win_complete.bat` — núcleo C/C++ (tools + libs + `cprel`)
2. `part1_16bit.bat`, `part1b_dwarf_cg.bat` — `wcc/wpp` 16-bit, `wdis`
3. `part2_risc.bat`, `part2b_axp.bat` — cross Alpha/PPC
4. `win_tools2.bat`, `setupgui_deps.bat`, `setupgui_build.bat` — resto
5. `build/test_examples.bat` — regressão após cada parte
6. `distrib_build.bat` — instaladores finais

Detalhes, dependências e diagnósticos: [`marco.md`](marco.md).

## Source Tree Layout

Pode-se colocar a árvore quase em qualquer lugar (evite caminhos com
espaços). A raiz é `OWROOT`. Separador `\` (Windows). Layout:

    bld
      - Raiz dos projetos. Exemplos:
          bld\cg       -> code generator
          bld\cc       -> C compiler
          bld\plusplus -> C++ compiler
          bld\wl       -> linker (wlink)
          bld\wasm     -> assembler
          bld\wv       -> debugger (wd/wdw)
          bld\f77      -> Fortran (wfc/wfl)
          bld\vi       -> editor vi
          (see projects.txt for details)

    build
      - Sistema de build: *.ctl (builder), makeinit, mif/.
      - build\*.bat — pipeline LabsObjects (win_complete, part1_*,
        part2_*, setupgui_*, mkdisk_build, distrib_build, test_examples,
        smoke_wcc, wmake_fix, autohost*). Todos com BOOTSTRAP_CPU=386
        e OWNEWWGML=1.
      - build\binbuild — host tools: wmake, builder, bwcc386/bwpp386,
        bwlink, byacc, re2c, wgml/whpcvt nativos, dlgprs, errsrc,
        chk_exec/chktest/catfile (testes), wsplice, wlink.lnk.

    docs
      - Documentação e GML (docs .hlp/.chm exigem HHC; fora de escopo).

    distrib
      - Manifestos e instaladores (distrib/ow/bin/).

    contrib
      - Código de terceiros (DOS extenders).

    examples
      - Exemplos C/C++ (hello.c, hello.cpp, math_test.c, ExamplesC/,
        ExampleC++/) + build\test_examples.bat.

    rel
      - Destino dos binários (estrutura criada via cprel; OWRELROOT
        pode mudar o local). rel\binnt = toolchain Windows 32-bit
        completa; rel\lib386\nt = runtimes; rel\h = headers.

    Raiz
      - OpenWatcom.png — logo desta edição (582×675, 353 KB, otimizado).
      - marco.md — pipeline FASEs 0–46 (o que funciona + pendências).
      - skill.md — regras de engenharia/entrega.
      - license.txt — OWPL 1.0 + adendo LabsObjects.
      - setvars_ow.bat / setvars_gcc.bat / build_full.bat — ambientes.

## Comunidade (upstream)

Discussão: [`Open Watcom on GitHub`](https://github.com/open-watcom/open-watcom-v2/discussions),
[`Reddit`](https://www.reddit.com/r/OpenWatcom/),
[Discord 2.0](https://discord.gg/39w5wZM89p).
[`openwatcom.org`](http://openwatcom.org) (só WEB no ar).
Releases e CI do upstream: [GitHub Releases](https://github.com/open-watcom/open-watcom-v2/releases).

## Licença

[Sybase Open Watcom Public License v1.0 + adendo LabsObjects](license.txt).
Sem restrições adicionais: modificações contribuídas sob a mesma licença.
