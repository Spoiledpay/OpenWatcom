
Primeiro entendas as regras de entregas de código.

**INSTRUÇÕES PARA ESTA SESSÃO DE PROGRAMAÇÃO**

Para garantir que nossa colaboração seja eficiente e precisa, siga estas regras estritamente:

1.  **Código Completo e Executável:**
    *   Sempre que eu solicitar uma função nova ou a modificação de um arquivo, forneça o **código completo e final do arquivo**, pronto para copiar e colar.
    *   **NUNCA** use placeholders como `//...`, `// seu código aqui`, `TODO` ou abreviações. O código deve ser 100% implementado.

2.  **Formato de Resposta para Correções:**
    *   Se for um erro de compilação simples (ex: typo, falta de `;`), aplique a correção diretamente e mostre **apenas o código corrigido**. Evite longas explicações sobre o erro.
    *   Para mudanças maiores, mostre o "ANTES" e "DEPOIS" de forma clara, em blocos separados, ou apenas o arquivo final completo.

3.  **Gestão de Versões de Código:**
    *   Quando eu anexar um arquivo a esta conversa, ele se torna a **verdade absoluta e a versão mais recente**. Ignore e substitua completamente qualquer versão anterior do mesmo arquivo que possa estar no histórico do chat.

4.  **Concisão e Clareza:**
    *   Se um arquivo ou função **não foi alterado**, **não o envie** na resposta. Presuma que eu tenho a versão anterior.
    *   Mantenha o código limpo. Não adicione comentários como `//-- aqui não alteramos //`.

5.  **Fluxo de Aprovação:**
    *   **Antes de implementar qualquer solicitação minha que altere o código,** **SEMPRE me pergunte** se pode prosseguir e confirme o escopo exato da mudança. Não assuma que tem permissão para alterar grandes seções sem minha confirmação explícita.

É proibido:
- gerar código resumido ou parcial
- deixar funções vazias
- omitir arquivos obrigatórios
- gerar pseudocódigo
- escrever “...” ou “implemente o resto depois”
- pular qualquer etapa do protocolo
- gerar tokens ou parser incompletos
- gerar encoder x64 incompleto
- gerar COFF inexato ou inválido

Por favor, confirme que entendeu todas estas instruções.
Depois vocÊ é um especialista em Desenvolvimento, programação, C E c++, COMPILADORES e vai ajudar a implementar e a melhorar esse compilador. 
# Open Watcom V2 - Port para Windows x64 com GCC/MinGW

## Objetivo

Compilar o Open Watcom V2 (compilador C/C++/FORTRAN auto-hospedado) no Windows 10 x64
usando GCC/MinGW-w64 como compilador de bootstrap, gerando **.exe nativos para Windows x64**.
Sem targets 16-bit, DOS, OS/2, Linux ou outras arquiteturas.

---

## Arquitetura do Build System OW

O Open Watcom usa um processo de **bootstrapping em 3 estágios**:

```
[Estágio 0] Host Compiler (GCC/MinGW)
    |
    v
[Estágio 1] wmake.exe + builder.exe  (ferramentas de build mínimas)
    |
    v
[Estágio 2] builder boot             (compila todas ferramentas OW com host compiler)
    |
    v
[Estágio 3] builder rel              (recompila tudo com as próprias ferramentas OW)
```

### Fluxo detalhado:

```
FASE 0 (Bootstrap Inicial):
  make -f mingwmake        -> wmake.exe    (usando gcc diretamente)
  wmake -f preboot         -> builder.exe  (usando wmake + gcc)

FASE 1 (Bootstrap Completo - builder boot):
  builder boot
    -> para cada projeto em bld/<projeto>/:
         wmake -f binmake bootstrap=1     (compila com host compiler)
    -> gera: wcc386.exe, wlink.exe, wasm.exe, wlib.exe, etc.

FASE 2 (Build Final - builder rel):
  builder rel
    -> para cada projeto em bld/<projeto>/:
         wmake -f makefile                (compila com OW tools)
    -> gera: todos os .exe finais em rel/
```

---

## FASE 0: Preparação do Ambiente

### 0.1 Verificar ferramentas disponíveis

- [x] `gcc` (MinGW-W64 x86_64-ucrt-posix-seh 13.2.0) -> OK
- [x] `make` (GNU Make 3.81 i386-pc-mingw32) -> OK
- [x] `ar` (GNU ar 2.42) -> OK
- [ ] Verificar `rm`, `cp`, `sed`, `awk` (necessários durante bootstrap)

### 0.2 Criar script de ambiente `setvars_gcc.bat`

Semelhante ao `setvars.bat` mas configurado para GCC:
- `OWROOT` = diretório do repositório
- `OWTOOLS=GCC`
- `OWOBJDIR=binbuild`
- `OWDOCBUILD=0` (sem docs inicialmente)
- `OWGUINOBUILD=1` (sem GUI inicialmente)

### 0.3 Adaptar `cmnvars.bat`

Adicionar detecção do toolchain GCC (atualmente só detecta WATCOM, VISUALC, INTEL):

```batch
:nowatcom
if not '%OWTOOLS%' == 'GCC' goto nogcc
echo set OWTOOLSVER=__GNUC__>getversi.gc
gcc -E -dM getversi.gc 2>&1 | find "__GNUC__" > getversi.bat
:nogcc
```

---

## FASE 1: Bootstrap wmake com GCC/MinGW

### 1.1 Criar `bld/wmake/mingwmake`

Baseado no `posmake` existente (que funciona em Linux com GCC), adaptado para Windows/MinGW.

**Diferenças do posmake:**
- `TARGETDEF` = `-D__NT__` (em vez de `-D__LINUX__`)
- `DEFS` adiciona `-D__FLAT__ -DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_WARNINGS`
- Target = `wmake.exe` (com extensão)
- Paths com `\` (backslash)

```makefile
# mingwmake - Build wmake with MinGW GCC on Windows
INCS = -I. -I../h -I../../watcom/h -I../../lib_misc/h $(DEFS)
DEFS = $(TARGETDEF) -DBOOTSTRAP -DPREBOOT -DINCL_MSGTEXT -D_XOPEN_SOURCE=600 -D_BLDVER=$(OWBLDVERTOOL) -D_CYEAR=xxxx $(EXTRADEF)
CFLAGS = -g -O2 $(INCS)

OBJS = macros.o main.o mautodep.o mautoomf.o mcache.o memory.o mexec.o \
       mglob.o mhash.o misc.o mlex.o mlexmac.o mlexprs.o mparse.o \
       mpreproc.o mrcmsg.o msg.o mstream.o msuffix.o msysdep.o \
       mtarget.o mupdate.o mvecstr.o depinfo.o clibext.o

all: ../../../build/$(OWOBJDIR)/wmake.exe

# Regras de compilação (mesmas do posmake)
# Link final com gcc
```

### 1.2 Ajustar headers para MinGW

Verificar/ajustar `bld/wmake/h/msysdep.h`:
- Para `__NT__` (definido pelo mingwmake): PATH_SPLIT=';', SHELL_ESC='^', etc.
- Verificar includes: `<direct.h>`, `<process.h>`, `<windows.h>` no MinGW

### 1.3 Compilar wmake.exe

```bash
cd bld\wmake
mkdir binbuild
cd binbuild
make -f ..\mingwmake OWOBJDIR=binbuild OWBLDVERTOOL=1300
```

**Verificações:**
- `build\binbuild\wmake.exe` existe
- `wmake -h` funciona
- `wmake -f ..\wmake clean` funciona

---

## FASE 2: Bootstrap builder com wmake

### 2.1 Adaptar `bld/builder/preboot` para GCC/MinGW

O `preboot` atual tem 3 caminhos:
1. `__WATCOM_TOOLS__` -> usa `wcl386`
2. `__NT__` -> usa `cl` (Visual C++)
3. Fallback -> usa `cc` (Unix)

Precisamos adicionar um 4º caminho para GCC/MinGW no NT:

```makefile
!ifdef __WATCOM_TOOLS__
  ...
!else ifdef __NT__
  !ifdef __GCC_TOOLS__
    CL = gcc -g -O2 -o$(name_exe)
    cpp_defines_common = -D__NT__ -D__FLAT__ -DWIN32_LEAN_AND_MEAN
  !else
    CL = cl /nologo /Fe:$(name_exe)
    cpp_defines_nt = -D__NT__
  !endif
!else
  CL = cc -g -O2 -o$(name_exe)
  cpp_defines_common = -D__UNIX__ -D_XOPEN_SOURCE=600
  ...
!endif
```

Mas o problema: o `preboot` detecta `__NT__` ou `__UNIX__` baseado em como o **wmake** foi compilado. Como vamos compilar wmake com `__NT__`, o `preboot` usará o caminho `__NT__` que atualmente chama `cl`.

**Solução:** Modificar `preboot` para detectar GCC vs CL dentro do bloco `__NT__`:

```makefile
!else ifdef __NT__
  !ifdef __GNUC__
    CL = gcc -g -O2 -o$(name_exe)
    cpp_defines_common = -D__NT__ -D__FLAT__ -DWIN32_LEAN_AND_MEAN
  !else
    CL = cl /nologo /Fe:$(name_exe)
    cpp_defines_nt = -D__NT__
  !endif
```

Onde `__GNUC__` é definido pelo GCC automaticamente.

### 2.2 Compilar builder.exe

```bash
mkdir bld\builder\binbuild
cd bld\builder\binbuild
..\..\..\build\binbuild\wmake -f ..\preboot
```

**Verificações:**
- `build\binbuild\builder.exe` existe
- `builder` funciona (pelo menos `builder -?`)

---

## FASE 3: cpuoscfg.mif - Adicionar suporte NT para GCC

### 3.1 Modificar `build/mif/cpuoscfg.mif`

Adicionar `bld_os_nt = 1` para `__GCC_TOOLS__`:

```makefile
!else ifdef __GCC_TOOLS__
  bld_cpu_386  = 1
  bld_cpu_x64  = 1
  bld_cpu_arm  = 1
  bld_cpu_a64  = 1
  bld_os_linux = 1
  bld_os_bsd   = 1
  bld_os_nt    = 1    # <-- ADICIONADO
```

Sem essa mudança, `skip_build = 1` será definido para qualquer target NT
com GCC, e o build será ignorado silenciosamente.

---

## FASE 4: local.mif - Adicionar configuração GCC/MinGW para NT

### 4.1 Adicionar NT-specific defines no bloco GCC/Clang

Em `build/mif/local.mif`, dentro da seção `__GCC_TOOLS__ || __CLANG_TOOLS__`
(linhas 316-696), adicionar:

```makefile
common_cppflags_nt    = -D__NT__ -DWIN32_LEAN_AND_MEAN
common_cppflags_ntx64 = -D__NT_X64__
```

Também ajustar `common_ppflags` para não definir `__UNIX__` quando no NT:

```makefile
!ifdef __NT__
  common_ppflags = -D__FLAT__ -D_CRT_SECURE_NO_WARNINGS
!else
  common_ppflags = -D__UNIX__ -D__FLAT__
!endif
```

### 4.2 Ajustar flags de compilação para NT

Adicionar flags específicas do Windows:

```makefile
# Target specific options for NT
target_cflags_x64_nt = -m64

# DLL extension for Windows
ext_lib_shared = .dll

# Extra libs for linking
bld_extra_ldflags_nt = -lshlwapi -luser32 -lgdi32 -lcomdlg32 -ladvapi32 -lshell32 -lole32
```

### 4.3 Ajustar linker flags

```makefile
# Para NT com GCC:
!ifdef __NT__
  bld_ldflags1 = $(common_ldflags) -Wl,-Map,$^&.map
  bld_ldflags  = $(bld_cl_extra_libs_gen) $(bld_extra_ldflags_nt) -static
!else
  bld_ldflags1 = $(common_ldflags) -Wl,-Map,$^&.map
  bld_ldflags  = $(bld_cl_extra_libs_gen) $(bld_extra_ldflags)
!endif
```

### 4.4 Ajustar `bld` e `cc` flags

```makefile
# Para NT:
!ifdef __NT__
  bld_c_flags   = -std=gnu99 -D__NT__
  bld_cxx_flags = -std=c++98
  cc            = $(noecho)gcc -pipe -c
  cl            = $(noecho)gcc -pipe
!endif
```

---

## FASE 5: Builder Boot - Compilar ferramentas bootstrap

### 5.1 Executar `builder boot`

```bash
cd bld
builder boot
```

Isso vai percorrer todos os projetos listados em `builder.ctl` (bloco `boot`),
executando `wmake -f ../binmake bootstrap=1` em cada um.

### 5.2 Projetos construídos no bootstrap (ordem em builder.ctl)

1. **watcom** - clibext library (funções extras para Watcom)
2. **git** - git version info
3. **posix** - POSIX tools (awk, sed, cp, rm, etc.)
4. **builder** - wsplice, genverrc, comstrip, diff, cdsay, wgrep
5. **yacc** - yet another compiler-compiler
6. **awk** - awk utility
7. **cpp** - C preprocessor
8. **fe_misc** - optencod, msgencod, findhash
9. **orl** - Object Reading Library
10. **nwlib** - Librarian (wlib)
11. **wres** - Windows resource library
12. **rc/rc** - Resource compiler
13. **wstrip** - Executable stripper
14. **dwarf/dw** - DWARF reading/writing
15. **wl** - Linker (wlink)
16. **owl** - Object Writing Library
17. **re2c** - Regex-to-C lexer generator
18. **as** - RISC assemblers
19. **wasm** - Watcom assembler
20. **wcl** - Compile & Link utility
21. **cfloat** - Floating-point support
22. **cg** - Code generator
23. **cc** - C compiler
24. **plusplus** - C++ compiler
25. **...** (demais utilitários)

### 5.3 Problemas potenciais no bootstrap

Para cada projeto, verificar:
- [ ] O `binmake` + `master.mif` + `cproj.mif` detectam corretamente GCC+NT
- [ ] `skip_build` não está sendo setado (cpuoscfg.mif)
- [ ] As flags de compilação estão corretas para MinGW
- [ ] Os headers do Windows estão disponíveis (via MinGW)
- [ ] As bibliotecas de sistema estão sendo linkadas corretamente

### 5.4 Correções necessárias em código fonte

Baseado na análise, os arquivos que precisam de atenção:

| Arquivo | Problema | Correção |
|---------|----------|----------|
| `bld/wmake/h/msysdep.h` | Usa `__WATCOMC__` para detectar NT | Adicionar `defined(__GNUC__)` como alternativa |
| `bld/wmake/c/mcache.c` | Inclui `<windows.h>` só com `__WATCOMC__` | Adicionar `|| defined(__GNUC__)` |
| `bld/builder/c/runit.c` | `typedef DWORD fattrs` precisa de `<windows.h>` | Garantir include |
| `bld/cc/**` | Pode ter código Watcom-specific | Verificar durante compilação |
| `bld/cg/**` | Code generator - pode ter assembly | Verificar |

---

## FASE 6: Build Final - `builder rel`

### 6.1 Executar `builder rel`

```bash
cd bld
builder rel
```

Usa as ferramentas OW recem-construídas (wcc386, wlink, wasm, etc.) para
recompilar **tudo** incluindo runtime libraries (clib, mathlib, cpplib).

### 6.2 Projetos construídos no `rel`

- **hdr** - Headers da linguagem/API
- **os2api, w16api, w32api** - Headers de API
- **clib** - C runtime library
- **mathlib** - Math library
- **cpplib** - C++ library
- **rtdll** - Runtime DLLs
- **f77lib** - FORTRAN library
- **fpuemu** - FPU emulator
- **graphlib** - Graphics library
- **wstuba** - DOS/4GW stub
- **causeway** - DOS extender
- **win386** - Windows 386 extender
- **wl** - Linker (reconstruído)
- **cc** - C compiler (reconstruído)
- **plusplus** - C++ compiler (reconstruído)
- **wcl** - Compile & Link (reconstruído)
- **ide, vi, debugger, profiler** - Ferramentas GUI
- (e muito mais)

### 6.3 Problemas potenciais no `rel`

- As ferramentas OW (wcc386, wlink) podem ter bugs quando compiladas com GCC no boot
- Runtime libraries precisam ser compiladas corretamente para Windows x64
- Alguns projetos têm dependências complexas

---

## FASE 7: Testes

### 7.1 Testes de bootstrap

```bash
cd bld\wasmtest && builder -i test
cd bld\ctest && builder -i test
cd bld\plustest && builder -i test
```

### 7.2 Testes de compilação

```bash
cd tests
# compilar programas de teste com wcc386/wlink
```

### 7.3 Testes de auto-hospedagem

```bash
# Recompilar o próprio OW com ele mesmo
set OWTOOLS=WATCOM
builder boot
builder rel
```

---

## Problemas Conhecidos e Riscos

1. **DOSBOX/WGML**: Documentação precisa de DOSBOX no Windows x64. Inicialmente desabilitar docs (`OWDOCBUILD=0`).

2. **clibext.lib**: Biblioteca de extensão do Watcom que adiciona funções faltantes. Precisa ser compilada primeiro no bootstrap.

3. **SysCall vs API**: MinGW usa `ucrtbase.dll` como CRT. O Watcom usa sua própria CRT (clib). A compatibilidade entre as duas precisa ser verificada.

4. **Recursos (.rc, .res)**: Compilação de recursos Windows depende do `wrc` (resource compiler OW). Precisa funcionar no bootstrap.

5. **DLLs**: O build de DLLs (rtdll) pode ter problemas com as convenções do MinGW vs Watcom.

6. **Código assembly**: O code generator (`cg`) e alguns outros componentes podem ter código assembly embutido que precisa ser revisado.

---

## Cronograma Estimado

| Fase | Descrição | Esforço |
|------|-----------|---------|
| 0 | Preparação do ambiente | 1 dia |
| 1 | Bootstrap wmake | 1-2 dias |
| 2 | Bootstrap builder | 1 dia |
| 3 | cpuoscfg.mif | 0.5 dia |
| 4 | local.mif GCC/NT | 2-3 dias |
| 5 | builder boot (correções) | 5-10 dias |
| 6 | builder rel (correções) | 5-10 dias |
| 7 | Testes | 3-5 dias |

**Total estimado: ~20-30 dias de trabalho**

---

---

## FASE 8: Correções Pós-Bootstrap — Build System (local.mif)

### 8.1 `local.mif` — Parse Error `!if $(__GCC_TOOLS__) >= 13` (boot)

**Problema:** Na linha 509, `!if $(__GCC_TOOLS__) >= 13` causa `Error(E59): !IF Parse Error` porque `__GCC_TOOLS__` não está definido durante o bootstrap com wmake.

**Solução:** Envolver a comparação com `defined()` e usar fallback numérico:

```makefile
!  if defined(__GCC_TOOLS__)
!   if $(__GCC_TOOLS__) >= 13
common_cflags_wng += -fstrict-flex-arrays=1
!   endif
!  endif
```

- [x] Aplicar correção em `build/mif/local.mif:509`
- [x] Re-testar `builder boot` — parse error não ocorre mais (boot progrediu além do watcom)

### 8.2 `local.mif` — Flag `-gz` sendo passada no NT com GCC

**Problema:** A flag `-gz` (compressão debug) está sendo passada para o GCC no NT porque `__NT__` não é definido no contexto onde `common_flags_compr` é avaliado.

**Solução:** Substituir `!ifdef __NT__` (que não está definido no escopo do make) por `!ifeq host_os nt` / `!ifeq bld_os nt` (variáveis disponíveis via `makeinit`):

```makefile
! else ifdef __GCC_TOOLS__
!  ifdef __OSX__
!  else ifeq host_os nt
!  else ifeq bld_os nt
!  else
common_flags_compr = -gz
!  endif
! endif
```

- [x] Aplicar correção em `build/mif/local.mif:451`
- [ ] Verificar se `-gz` não é mais passado durante `builder rel` ou `builder build`

---

## FASE 9: Correções Pós-Bootstrap — Runtime Libraries

### 9.1 `bld/watcom` — Clibext (clibext.lib)

- [x] `clibext.lib` compilou durante `builder boot` (erro de parse do local.mif corrigido na FASE 8)
- [x] `clibexts.lib` também compilado
- [ ] Garantir que `clibext.lib` e `clibexts.lib` sejam copiados para `rel/lib386/`

### 9.2 `bld/clib` — C Runtime Library (clib3r.lib, clib3s.lib)

- [x] `clib3r.lib` e `clib3s.lib` copiados para `rel/lib386/nt/` pelo `builder rel`
- [ ] Verificar se os símbolos de import (`__imp_*`) resolvem com as import libs do NT

### 9.3 `bld/clib/rtdll` — Runtime DLL (clbrdll.lib)

**Problema:** `clbrdll.lib` não existia porque o `export.gdf` (gerado apenas com `linkage=dynamic`) não era gerado para a biblioteca estática `mf_r`.

**Solução:** 
1. Compilar `bld/clib/library/winnt.386/mf_rd/` (linkage=dynamic) → gera `export.gdf`
2. Copiar `export.gdf` para `mf_r/`
3. Compilar `bld/clib/rtdll/winnt.386/mf_r/` → gera `clbrdll.lib` + `clbr20.dll`

- [x] Compilar `mf_rd` do clib para gerar `export.gdf`
- [x] Copiar `export.gdf` para `mf_r/`
- [x] Compilar `clbrdll.lib` e `clbr20.dll`
- [x] Copiar `clbrdll.lib` → `rel/lib386/nt/`
- [x] Copiar `clbr20.dll` → `rel/binnt/`
- [ ] Compilar variantes `mf_rp`, `mf_rd`, `mf_s` do rtdll

### 9.4 `bld/mathlib` — Math Library

- [x] Re-compilar `math3r.lib`, `math3s.lib`, `math387r.lib`, `math387s.lib`
- [x] Copiar para `rel/lib386/nt/`
- [x] `hello.exe` linkado com CRT: ✅ FUNCIONAL
- [ ] `math_test.exe` linkado mas resultados incorretos (provável problema com FPU emulator ou ordem de link)

### 9.5 `bld/cpplib` — C++ Library

- [ ] Compilar `plib3r.lib`, `plib3s.lib`, `plbx3r.lib`, `plbx3s.lib`
- [ ] Copiar para `rel/lib386/nt/`

---

## FASE 10: Correções Pós-Bootstrap — Import Libraries (w32api)

### 10.1 Verificar decoração `@N` nas import libraries

**Problema:** Símbolos na CRT usam `__imp__FunctionName@N` (stdcall com decoração Watcom). As import libraries precisam ter os mesmos símbolos.

- [ ] Inspecionar `kernel32.lib` para verificar decoração dos símbolos
- [ ] Se necessário, re-gerar import libraries com `def2lbc.awk`

### 10.2 Reconstruir import libraries corrompidas

- [ ] Se alguma import lib tiver decoração errada, recompilar via `bld/w32api`
  ```bash
  cd bld\w32api\nt386
  wmake -f ..\libs.mif
  ```

---

## FASE 11: Testes de Compilação com wcc386/wlink

### 11.1 Compilar exemplos C

- [ ] Compilar `examples/hello.c` com wcc386 + wlink
  ```bash
  wcc386 hello.c -fo=hello.obj -s -i=rel\h -i=rel\h\nt
  wlink form windows nt name hello.exe file hello.obj library rel\lib386\nt\clib3r.lib,rel\lib386\nt\kernel32.lib,rel\lib386\nt\user32.lib
  ```
- [ ] Executar `hello.exe` e validar saída

- [ ] Compilar e testar `examples/ExamplesC/ex1.c` até `ex5.c`
- [ ] Compilar e testar exemplos das subpastas (HelloWorld, Math, String, etc.)

### 11.2 Compilar exemplos C++

- [ ] Compilar `examples/hello.cpp` com wpp386 + wlink
  ```bash
  wpp386 hello.cpp -fo=hello.obj -s
  wlink ...
  ```
- [ ] Compilar e testar exemplos `examples/ExampleC++/` (HelloWorld, Classes, etc.)

### 11.3 Criar script de teste automatizado

- [ ] Criar `examples/test_all.bat` que compila e executa todos os exemplos
- [ ] Verificar saída esperada de cada exemplo

---

## FASE 12: Empacotamento e Distribuição

### 12.1 Verificar diretório `rel/` completo

- [ ] `rel/binnt/` — Todos os .exe das ferramentas OW
- [ ] `rel/h/` — Headers C/C++
- [ ] `rel/h/nt/` — Headers específicos NT
- [ ] `rel/lib386/nt/` — Todas as bibliotecas (CRT, math, C++, import libs)
- [ ] `rel/lib386/` — Bibliotecas de outros targets (se aplicável)

### 12.2 Script de ambiente `setvars_ow.bat`

- [ ] Criar script que configura `PATH`, `INCLUDE`, `WATCOM` para usar a toolchain OW
  ```batch
  set WATCOM=C:\caminho\rel
  set PATH=%WATCOM%\binnt;%PATH%
  set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
  ```

### 12.3 Verificar auto-hospedagem

- [ ] Compilar o próprio OW com ele mesmo:
  ```bash
  set OWTOOLS=WATCOM
  builder boot
  builder rel
  ```

---

## Cronograma Revisado

| Fase | Descrição | Esforço | Status |
|------|-----------|---------|--------|
| 0 | Preparação do ambiente | 1 dia | ✅ Concluído |
| 1 | Bootstrap wmake | 1-2 dias | ✅ Concluído |
| 2 | Bootstrap builder | 1 dia | ✅ Concluído |
| 3 | cpuoscfg.mif | 0.5 dia | ✅ Concluído |
| 4 | local.mif GCC/NT | 2-3 dias | Parcial (requer ajustes Fase 8) |
| 5 | builder boot (correções) | 5-10 dias | Parcial (boot executou mas com erros) |
| 6 | builder rel (correções) | 5-10 dias | Parcial (infra bloqueia) |
| 7 | Testes | 3-5 dias | ❌ Não iniciado |
| 8 | Correções build system (local.mif) | 1 dia | ✅ Concluído |
| 9 | Runtime libraries (clib, mathlib, cpplib) | 3-5 dias | Parcial (clib OK, mathlib compilado mas com NaN) |
| 10 | Import libraries (w32api) | 1 dia | ✅ Concluído |
| 11 | Testes de compilação | 2-3 dias | ⏳ Pendente |
| 12 | Empacotamento | 1 dia | ⏳ Pendente |
| 13 | Exportar math functions da CRT DLL | 3-5 dias | ✅ Concluído (mf_r) |
| 14 | C++ Runtime Library (cpplib) | 2-3 dias | ✅ Concluído |
| **15** | **Variante mf_rp (profile)** | **3 dias** | **✅ Completo** |
| 15a | clib mf_rp (28 subprojetos + merged) | 1 dia | ✅ |
| 15b | mathlib mf_rp criado e compilado | 0.5 dia | ✅ |
| 15c | rtdll mf_rp (clbrp.dll + import lib) | 0.5 dia | ✅ |
| 15d | wlink.lnk ausente (sys nt_dll) | 0.5 dia | ✅ |
| 15e | builder.ctl atualizado | 0.5 dia | ✅ |
| 16 | Testes finais | 2-3 dias | Parcial (C/C++/math OK via `build/test_examples.bat`, regressão `ctest/plustest` ⏳) |
| 17 | Infraestrutura builder rel | 2-3 dias | Parcial (ver 15.1c) |
| 18 | Causa raiz `zq` + `BOOTSTRAP_CPU=386` | 0.5 dia | ✅ Concluído (08/10/2026, FASE 18) |
| 19 | Parte 1 (16-bit/wdis) + Parte 2 (RISC) | 1 dia | ✅ Concluído (08/10/2026, FASE 19) |
| 20 | Partes 3-8 (vi, debugger, GUI, IDE, F77, docs) | ~5-10 dias | ⏳ Pendente (FASE 20, 28 `.exe` zerados) |

**Total revisado: ~35-50 dias de trabalho**

---

## FASE 13: Exportar Math Functions da CRT DLL (`clbr20.dll`)

### Contexto

O modelo `__SW_BR` (Big Runtime / DLL runtime) do OW para NT exige que **todas as funções CRT + matemáticas residam dentro da CRT DLL** (`clbr20.dll`). Atualmente:

- `clbr20.dll` contém apenas funções CRT (`printf`, `malloc`, etc.) — exportadas via `export.gdf`
- `math3r.lib` contém as implementações reais de `sqrt`, `sin`, `cos`, `exp`, `log`, etc.
- Programas compilados com `-br` (DLL runtime) geram `call __imp__sqrt` que espera encontrar o símbolo na DLL
- Como `sqrt_` não está na DLL, o linker resolve para a definição local em `math3r.lib`, criando inconsistência que produz NaN

**Solução:** Linkar `math3r.lib` dentro da DLL e exportar todas as funções matemáticas.

### Arquitetura da CRT DLL (`clbr20.dll`)

A DLL é construída via `bld/clib/rtdll/winnt.386/mf_r/makefile` que inclui:

```
makefile
  → ../../../rtdll.mif           (bld/clib/rtdll.mif)
    → $(rtdll_dir)/master.mif    (bld/rtdll/master.mif)
      → ../objs.mif              (bld/clib/rtdll/winnt.386/objs.mif)
```

O `objs.mif` define três variáveis principais usadas pelo linker:

| Variável | Função | Atual |
|----------|--------|-------|
| `dll_libs` | Bibliotecas estáticas linkadas na DLL | `clib3r.lib` |
| `dll_objs` | Objetos extras linkados na DLL | `clibdwnt.obj` |
| `dll_def` | Arquivos de definição de exports | `export.gdf` + `.def` files |

### 13.1 Gerar export list do `math3r.lib`

O mecanismo de exports existente usa:
1. `wlib -z=export.tmp lib` → gera lista de todos os símbolos públicos da biblioteca
2. `sed -f export.sed export.tmp > export.gdf` → coloca cada linha entre aspas simples

Precisamos gerar um `math_export.gdf` a partir do `math3r.lib`:

```bash
cd bld\mathlib\library\winnt.386\mf_r
wlib -z=export.tmp math3r.lib
sed -f ..\..\..\..\..\lib_misc\sed\export.sed export.tmp > math_export.gdf
```

**Verificações:**
- [ ] `math_export.gdf` gerado com símbolos como `'sqrt_'`, `'sin_'`, `'cos_'`, etc.
- [ ] Não há símbolos duplicados com `export.gdf` do clib (verificar overlaps)

### 13.2 Modificar `bld/clib/rtdll/winnt.386/objs.mif`

Adicionar `math3r.lib` e `math_export.gdf` às definições da DLL:

```makefile
dll_libs = $+ &
    $(clib_dir)/library/$(__cifx__)/clib3$(dllname_$(convention)).lib &
    $(mathlib_dir)/library/winnt.386/$(libsubdir)/math3$(dllname_$(convention)).lib &
    $-

dll_def = $+ &
    $(clib_dir)/library/$(__cifx__)/export.gdf &
    $(mathlib_dir)/library/winnt.386/$(libsubdir)/math_export.gdf &
    $(clib_dir)/intel/export.def &
    $(clib_dir)/startup/export.def &
    $(clib_dir)/startup/$(convention).def &
    $(clib_dir)/startup/library/$(system).$(processor)/$(convention).def &
    $-
```

Onde:
- `$(mathlib_dir)` → `bld/mathlib/`
- `$(libsubdir)` → `mf_r` (para model=flat, convention=register)
- `$(dllname_$(convention))` → sufixo do nome da lib (ex: `r` para register)

- [ ] Modificar `bld/clib/rtdll/winnt.386/objs.mif` com as novas entradas
- [ ] Garantir que `mathlib_dir` está disponível no escopo (definido em `cdirs.mif`)

### 13.3 Reconstruir `clbr20.dll` + `clbrdll.lib`

```bash
cd bld\clib\rtdll\winnt.386\mf_r
wmake -f makefile clean
wmake -f makefile
```

**Verificações:**
- [ ] `clbr20.dll` gerado sem erros de link (sem símbolos duplicados)
- [ ] `clbrdll.lib` gerado com os novos imports
- [ ] Verificar exports da DLL:
  ```bash
  objdump -p clbr20.dll | grep "sqrt_\|sin_\|cos_\|exp_\|log_"
  ```

### 13.4 Copiar artefatos para `rel/`

```bash
copy bld\clib\rtdll\winnt.386\mf_r\clbr20.dll   rel\binnt\
copy bld\clib\rtdll\winnt.386\mf_r\clbrdll.lib   rel\lib386\nt\
```

- [ ] `clbr20.dll` copiado para `rel/binnt/`
- [ ] `clbrdll.lib` copiado para `rel/lib386/nt/`

### 13.5 Recompilar `math3r.lib` com `linkage=static`

Após as funções math estarem na DLL, o `math3r.lib` deve ser recompilado com `linkage=static` para que programas que linkem com a DLL não tenham definições conflitantes:

**Problema:** Se `math3r.lib` mantiver `linkage=dynamic`, as funções `sqrt`, `sin`, etc. continuarão com `__declspec(dllimport)`, e o linker encontrará tanto a definição na DLL quanto no .lib, causando warnings/erros.

**Solução:** Modificar `bld/mathlib/library/winnt.386/mf_r/makefile`:
```makefile
# Antes:
linkage    = dynamic

# Depois:
linkage    = static
```

- [ ] Modificar makefile para `linkage=static`
- [ ] Recompilar `math3r.lib`:
  ```bash
  cd bld\mathlib\library\winnt.386\mf_r
  wmake -f makefile clean
  wmake -f makefile
  ```
- [ ] Copiar `math3r.lib` para `rel/lib386/nt/`

### 13.6 Validar `math_test.exe`

```bash
# Compilar
wcc386 math_test.c -fo=math_test.obj -s -i=rel\h -i=rel\h\nt

# Linkar com a DLL
wlink form windows nt name math_test.exe file math_test.obj library ^
    rel\lib386\nt\clib3r.lib,rel\lib386\nt\math3r.lib,^
    rel\lib386\nt\clbrdll.lib,rel\lib386\nt\kernel32.lib,rel\lib386\nt\user32.lib

# Executar (precisa do clbr20.dll no PATH)
math_test.exe
```

**Resultado esperado:**
```
sqrt( 2.0 ) = 1.414214
sin( 2.0 ) = 0.909297
cos( 2.0 ) = -0.416147
exp( 2.0 ) = 7.389056
log( 2.0 ) = 0.693147
```

- [ ] Compilar `math_test.c` com wcc386
- [ ] Linkar com `clbrdll.lib`
- [ ] Executar e verificar resultados corretos
- [ ] Testar com `-od` (sem otimizações) e sem `-od` (com otimizações)

### 13.7 Descoberta: NaN causado pelo compilador bootstrap (inline FPU)

**Problema:** Mesmo com as math functions corretamente exportadas na DLL, `math_test.exe` retornava `-nan` para todas as funções.

**Investigação:**
- `clbr20.dll` exportava `sqrt_`, `sin_`, `cos_`, etc. ✅
- `objdump -p clbr20.dll` confirmava os símbolos ✅
- Linkagem com `clbrdll.lib` resolvia `__imp__sqrt` etc. ✅
- Mas execução ainda produzia NaN ❌

**Causa raiz:** O compilador bootstrap (`bwcc386.exe`) gera instruções FPU inline (`fsqrt`, `fsin`, `fcos`, etc.) que produzem NaN no Windows x64/WOW64. As instruções FPU inline do compilador têm um bug quando executadas via WOW64.

**Solução:** Compilar com `-fpc` (calls to floating-point library):
```bash
wcc386 programa.c -fo=programa.obj -fpc
```
Isso força o compilador a gerar CALLs para as funções da math library (dentro do `clbr20.dll` ou `math3r.lib`), que funcionam corretamente.

**Resultado com `-fpc`:**
```
sqrt( 2.0 ) = 1.414214    ✓
sin( 2.0 )  = 0.909297    ✓
cos( 2.0 )  = -0.416147   ✓
exp( 2.0 )  = 7.389056    ✓
log( 2.0 )  = 0.693147    ✓
```

**Nota técnica:** O bug de inline FPU deve ser resolvido com a auto-hospedagem (recompilar o compilador com ele mesmo), pois o `wcc386.exe` final (compilado por ele mesmo) pode gerar código FPU inline correto.

### 13.8 Repetir para outras variantes (mf_s, math387, etc.)

Após validar `mf_r` (register convention), repetir para:
- `mf_s` (stack convention) — `math3s.lib` + `clbrdll.lib` (variante mf_s)
- `winnt.387/mf_r` — `math387r.lib`
- `winnt.387/mf_s` — `math387s.lib`

- [ ] Repetir 13.1-13.6 para `mf_s` (stack convention)
- [ ] Repetir 13.1-13.6 para `winnt.387` (387 FPU optimized)

---

## FASE 14: C++ Runtime Library (cpplib)

### 14.1 Compilar `plib3r.lib` e variantes

- [x] Compilar `bld/cpplib/library/winnt.386/mf_r/` → `plib3r.lib`, `plbx3r.lib`
- [x] Compilar `bld/cpplib/library/winnt.386/mf_s/` → `plib3s.lib`, `plbx3s.lib`
- [x] Copiar `plib3r.lib`, `plib3s.lib` para `rel/lib386/nt/`
- [x] Copiar `plbx3r.lib`, `plbx3s.lib` para `rel/lib386/nt/`

### 14.2 Compilar exemplos C++

- [x] Compilar `examples/hello.cpp` com wpp386 → ✅ `Hello world!`
- [ ] Compilar `examples/ExampleC++/HelloWorld/` com wpp386
- [ ] Compilar `examples/ExampleC++/Classes/` com wpp386

---

## FASE 15: GAPs e Pendências Conhecidas

### 15.1 Variante `mf_rp` (profile) — ✅ CONCLUÍDO

**O que foi feito:**
- Todos os **28 subprojetos clib** compilados em `mf_rp` (profile)
- **Merged library** `library/winnt.386/mf_rp/clib3r.lib` (1.4 MB) gerada com `linkage=dynamic` e `export.gdf`
- **mathlib** `mf_rp` static criado e compilado (246 KB)
- **rtdll** `mf_rp` — `clbrp.dll` (391 KB) + `clbrdll.lib` linkado com sucesso
- **builder.ctl** atualizado com deploy do `clib3rp.lib`
- Artefatos copiados para `rel/lib386/nt/` e `rel/binnt/`

**Como construir manualmente (comando base):**
```powershell
# clib subprojects
cd bld\clib\<sub>\library\winnt.386\mf_rp
wmake -h -f makefile clib_dir=<root>\bld\clib host_os=nt host_cpu=386

# merged clib
cd bld\clib\library\winnt.386\mf_rp
wmake -h -f makefile clib_dir=<root>\bld\clib host_os=nt host_cpu=386

# mathlib (precisa do diretório mf_rp criado)
cd bld\mathlib\library\winnt.386\mf_rp
wmake -h -f makefile clib_dir=<root>\bld\clib host_os=nt host_cpu=386

# rtdll (precisa de WLINK_LNK apontando para build\bwlink.lnk)
cd bld\clib\rtdll\winnt.386\mf_rp
set WLINK_LNK=<root>\build\bwlink.lnk
wmake -h -f makefile clib_dir=<root>\bld\clib host_os=nt host_cpu=386
```

**Pré-requisitos de ambiente:**
```
OWROOT=<root>
OWTOOLS=WATCOM
OWTOOLSVER=1300
OWBLDVERTOOL=1300
WATCOM=<root>\rel
PATH=<root>\rel\binnt;<root>\build\binbuild;%PATH%
INCLUDE=<root>\rel\h;<root>\rel\h\nt
```

---

### 15.1b Descoberta crítica: `wlink.lnk` ausente — ✅ CORRIGIDO

**Problema:** O wlink não reconhecia `sys nt_dll` porque o arquivo de inicialização `wlink.lnk` (com todas as definições de sistema) não estava presente ao lado do `wlink.exe`.

**Causa:** O `wlink.lnk` é gerado pelo `wsplice` a partir de `wlink.sp` + `specs.sp` (em `bld/wl/lnk/`), mas:
- O `bld/wl/lnk/specs.sp` tem apenas 21 linhas (não contém as definições de sistema)
- O verdadeiro init file completo é o `build/bwlink.lnk` (40.676 bytes, gerado durante o bootstrap)
- O `rel/binnt/wlink.exe` NÃO tinha `wlink.lnk` ao lado

**Solução:** Copiar `build/bwlink.lnk` para `rel/binnt/wlink.lnk` (ou definir `WLINK_LNK`).

**Arquivo de definições de sistema no bootstrap:**
```
build/bwlink.lnk  (40.676 bytes, 48 sistemas definidos incluindo nt_dll, nt, dos, etc.)
```

---

### 15.1c Problemas de infraestrutura do `builder rel` — Resolvido

**Problema:** O `builder` chama `pmake build os_nt cpu_386` que executa `wmake -f makefile` nos diretórios variantes. O wmake precisa encontrar `makeinit` (que configura o path de includes `.mif`), mas ele só procura no diretório corrente.

**Solução:** O `makeinit` é carregado com `envsearch=true`, o que significa que o `PATH` é pesquisado. Quando `%OWROOT%/build` está no PATH (configurado pelo `cmnvars.bat`), o `makeinit` é encontrado automaticamente. O `builder` já tem `pmake` embutido.

**Pré-requisitos de ambiente para `builder rel`:**
```powershell
PATH=%OWROOT%/build;%OWROOT%/build/binbuild;%OWROOT%/rel/binnt;%PATH%
OWROOT=<root>
OWTOOLS=WATCOM
OWBLDVERTOOL=1300
OWTOOLSVER=1300
WATCOM=<root>/rel
INCLUDE=<root>/rel/h;<root>/rel/h/nt
WLINK_LNK=<root>/build/bwlink.lnk   # necessário para nt_dll
```

---

### 15.2 Variante `mf_s` (stack convention) — ✅ CONCLUÍDO

**O que foi feito:**
- Criado makefile estático em `bld/mathlib/library/winnt.386/mf_s/makefile` (convention=stack, linkage=static)
- Compilado: `math3s.lib` (98.816 bytes)
- Copiado para `rel/lib386/nt/math3s.lib` e `rel/lib386/math3s.lib`

---

### 15.3 Variantes `winnt.387` (387 FPU) — ✅ CONCLUÍDO

**O que foi feito:**
- Criado `bld/mathlib/library/winnt.387/mf_r/` (register, static) → `math387r.lib` (82.432 bytes)
- Criado `bld/mathlib/library/winnt.387/mf_s/` (stack, static) → `math387s.lib` (83.968 bytes)
- Copiados para `rel/lib386/nt/` e `rel/lib386/`

---

### 15.8 Problema conhecido: rtdll mf_rp — múltiplos entry points

**Problema:** O `rtdll/winnt.386/mf_rp/` não consegue linkar `clbrp.dll` (CRT DLL com profile) porque a merged library `clib3r.lib` contém múltiplos módulos de startup conflitantes.

**Status da análise:**
- [x] Flag `-br` adicionada em `bld/clib/flags.mif` (correção no `sw_c_common`)
- [x] Subprojetos recompilados com `-br` (todos os 28 OK)
- [x] `clbrp.dll` gerado com 391 KB (exportações OK via `build/bwlink.lnk`)
- [ ] Link falha com `E2030: multiple starting addresses` — `cstrtwwt` (EXE) conflita com `dstrt386` (DLL)
- [ ] Símbolos `main_`, `_WinMain@16`, `wmain_`, `_wWinMain@16` indefinidos (esperado em DLL)

**Causa raiz:** A merged library inclui módulos de startup para TODOS os tipos de executável (EXE console, EXE windows, DLL). Para uma DLL, apenas `dstrt386` deve estar presente. Os módulos `cstrtwnt`, `cstrtwwt`, `cstrwwnt`, `cstrwwwt` definem entry points que conflitam.

**Soluções possíveis:**
1. Modificar o linker para ignorar entry points conflitantes (`disable 2030`)
2. Extrair módulos de startup EXE da merged library antes de linkar a DLL
3. Criar uma variante de merged library "DLL-only" sem os startups EXE

**Impacto:** Apenas afeta profiling com DLL runtime (`-br`). O uso normal do compilador C/C++ não é afetado.

---

### 15.4 Bug de inline FPU no compilador bootstrap

**Problema:** `wcc386.exe` (versão auto-hospedada) ainda produz `2.000000` para chamadas inline de `sqrt`, `sin`, `cos`, etc. — as funções retornam o input inalterado.

**Causa:** A auto-hospedagem via `builder build` com `OWTOOLS=WATCOM` reconstruiu as libraries (clib, mathlib, cpplib) mas NÃO reconstruiu o compilador (`wcc386.exe`). O `builder rel` falhou antes de chegar nos projetos `cc` e `cg` devido à variante `mf_rp`.

**Workaround:** Usar `-fpc` na compilação (força chamadas à math library em vez de inline FPU).

**Solução definitiva:** Completar a cadeia `mf_rp` ✅ (agora concluída) e executar `builder rel` para recompilar o compilador.

**Status:** ✅ `mf_rp` concluído, mas `builder rel` ainda encontra barreiras de infraestrutura (ver 15.1c)

---

### 15.5 Fortran (f77lib) não compila

**Problema:** `f77lib` precisa da ferramenta `errsrc` que não está disponível na build para NT.

**Solução:** `set OWNOBUILD=f77lib f77wfc f77wfl` para pular.

**Status:** ✅ Contornado (não relevante para C/C++)

---

### 15.6 wlink — paths com espaços

**Problema:** O tokenizer do wlink (`MakeToken` em `bld/wl/c/cmdutils.c`) não tratava aspas duplas (`"`) em paths.

**Solução:** Implementado suporte a `"` no `MakeToken()` — quando um token começa com `"`, espaços internos não quebram o token.

**Status:** ✅ Corrigido e testado

**Nota complementar — erro W1008 "cannot open emu387.lib":** Mesmo com o path do `library` entre aspas, o linker pode emitir `Warning! W1008: cannot open emu387.lib : No such file or directory`. Isso ocorre porque os objetos dentro de `clib3r.lib` têm diretivas de biblioteca padrão (*default library directives*) que referenciam `emu387.lib` e `math387r.lib`. O linker procura essas libs no diretório atual, não no path da lib especificada.

**Solução:** Usar `libpath` para registrar os diretórios de busca:
```bash
wlink form windows nt name prog.exe file prog.obj ^
    libpath "C:\caminho\rel\lib386" ^
    libpath "C:\caminho\rel\lib386\nt" ^
    library clib3r.lib,kernel32.lib,user32.lib
```
O `setvars_ow.bat` já define `%LIB386%` e `%LIBPATH%` para facilitar.

---

### 15.7 Exemplos com erros de código fonte

**Problemas encontrados em exemplos de terceiros:**
- `WriteConsole2.c`: Uso incorreto de `DWORD` como variável (em vez de `DWORD nWritten;`)
- `console-colors.c`: Uso incorreto de `CONSOLE_SCREEN_BUFFER_INFO` como variável
- `Multiplication1.c`: Strings não terminadas e uso incorreto de scanf
- `Dir2.c`: Inclui `dir.h` inexistente, strings não terminadas

**Status:** ❌ Erros nos fontes, não no compilador

---

## FASE 16: Testes de Compilação

### 16.1 Testes C

- [x] Compilar e executar `examples/hello.c` → ✅
- [x] Compilar e executar `examples/math_test.c` (com `-fpc`) → ✅
- [x] Compilar 32 exemplos em `examples/ExamplesC/` → ✅ (29 diretos, 3 com libpath)

### 16.2 Testes C++

- [x] Compilar `examples/hello.cpp` → ✅ `Hello world!`
- [ ] Compilar exemplos em `examples/ExampleC++/`

### 16.3 Testes de regressão

- [ ] Executar `builder -i test` em `bld/ctest`
- [ ] Executar `builder -i test` em `bld/plustest`

---

## FASE 17: Pendências Restantes

### 17.1 rtdll mf_rp — múltiplos entry points (⏳)

**Problema:** Link do `clbrp.dll` falha com `E2030: multiple starting addresses` porque a merged library contém startups EXE + DLL conflitantes.

**Solução proposta:** Extrair módulos de startup EXE (`cstrtwnt`, `cstrtwwt`, `cstrwwnt`, `cstrwwwt`) da merged library antes de linkar a DLL.

### 17.2 Testes C++ pendentes

- [x] Compilar `examples/hello.cpp` com wpp386 → ✅ (validado 08/10/2026 via `build/test_examples.bat`)
- [ ] Compilar exemplos em `examples/ExampleC++/` (HelloWorld, Classes, etc. — atenção: `HelloWorld/Hello.cpp` usa `cin.get()`, trava em teste auto)

### 17.3 Testes de regressão

- [ ] Executar `builder -i test` em `bld/ctest`
- [ ] Executar `builder -i test` em `bld/plustest`

### 17.4 Auto-hospedagem (`builder rel`)

**Pré-requisitos atendidos:**
- [x] `makeinit` encontrado via PATH
- [x] `builder` tem pmake embutido
- [x] `wlink.lnk` disponível (via `WLINK_LNK`)
- [x] Todas as variantes de biblioteca compiladas

**Passos restantes:**
- [ ] Executar `builder rel` de `bld/` com ambiente configurado
- [ ] Corrigir erros incrementalmente

## FASE 18: Causa raiz `zq` — `BOOTSTRAP_CPU=386` (sessão 08/10/2026)

### 18.1 Sintoma

Todo `builder build os_nt cpu_386` self-hosted (OWTOOLS=WATCOM) falhava em
projetos `wmake/nt386`, `ndisasm/nt386`, etc. com:

```
zq -D_BLDVER=1300 ... disbuild.c ... -fe=.\disbuild.exe
Error(E14): Cannot execute (zq): No such file or directory
```

O comando mostra só as flags (`-zq`), sem o compilador (`wcl386`/`wcc386`).

### 18.2 Diagnóstico (via `bld/ndisasm/nt386/dbg.mif` temporário, removido após)

Com o include chain real (`../master.mif`):

```
# sem BOOTSTRAP_CPU:
bld_os=[nt] bld_cpu=[x64] watbld_nt386=[1] skip=[]
bcl_386=[*wcl386] bcc_386=[*wcc386]      # existem, mas...
```

`bld_cpu=x64` (auto-detectado pelo `wmake.exe` 64-bit em `build/makeinit`),
então `$(bcl_$(bld_cpu))` = `$(bcl_x64)` = **vazio**
(`build/mif/local.mif:770` só define `bcl_386/axp/ppc/mps` — OW não gera
binário x64, wiki confirma). Com `BOOTSTRAP_CPU=386`:

```
bld_os=[nt] bld_cpu=[386] → bcl_386=[*wcl386] ✅
```

(`build/makeinit:70-72` — `BOOTSTRAP_CPU/OS` sobrescrevem o auto-detect.
No CI Windows isso nunca aparece porque usa VISUALC, que tem ramo x64
em `local.mif`. `setvars_gcc.bat` usa `BOOTSTRAP_CPU=x64`, correto p/ GCC.)

### 18.3 Correção aplicada

`set BOOTSTRAP_CPU=386` + `set BOOTSTRAP_OS=nt` em:
`build/win_complete.bat`, `win_tools2.bat`, `setupgui_build.bat`,
`setupgui_deps.bat`, `setupgui_deps2.bat`, `distrib_build.bat`,
`distrib_missing.bat`, `wmake_fix.bat`, `mkdisk_build.bat`,
`part1_16bit.bat`, `part1b_dwarf_cg.bat`, `part2_risc.bat`,
`part2b_axp.bat`, `build/autohost.bat`, `build/autohost2.bat`.

### 18.4 Outros fixes da sessão

- `bld/wclass/hpp/wfile.hpp:37` — `+ #include <stdio.h>` (`SEEK_SET`
  indefinido quebrava `builder boot` no GCC — era o motivo do boot parar
  e `mkdisk` nunca ser construído).
- `rel/binnt/wmake.exe` (234KB) — copiado de `build/binbuild/wmake.exe`
  (`bld/wmake/nt386` não linka no self-host: mesmo bug `zq` no `cretype`).
- `OWROOT` corrigido p/ `C:\Projetos\open-watcom-v2-master` em
  `build_full.bat:9`, `setvars_gcc.bat:8`, `setvars_ow.bat:21`,
  `build/autohost.bat:3`, `build/autohost2.bat:4`
  (apontavam p/ `...\Projetos Linguagem\forge-c\...`).

---

## FASE 19: Distro Windows por partes — Parte 1 (16-bit) e Parte 2 (RISC) ✅

### 19.1 Parte 1 — `wcc.exe`, `wpp.exe`, `wdis.exe`

`bld/cc|plusplus|cg/builder.ctl` tinham `i86` comentado ("not needed").
Reativado + build `dwarf` antes (`cgi86` precisa `dwarfw.lib`):

- `wcc.exe` (32KB, driver + `wccd.dll`) — `Open Watcom C x86 16-bit ... Usage: wcc` ✅
- `wpp.exe` (32KB) — `Open Watcom C++ x86 16-bit ... Usage: wpp` ✅
- `wdis.exe` (305KB) — `Open Watcom Multi-processor Disassembler ... Usage: wdis` ✅

### 19.2 Parte 2 — `wccaxp.exe`, `wasaxp.exe`, `wasppc.exe`

Reativado `axp/mps/ppc` nos 3 `builder.ctl`. Detalhe: `bld/cc/axp/nt386.dll/makefile`
tem tag `#pmake: build target_axp ...` — `builder build os_nt cpu_386` sozinho
**pula**; precisa `builder build os_nt cpu_386 target_axp` (`build/part2b_axp.bat`):

- `wccaxp.exe` (32KB), `wasaxp.exe` (135KB), `wasppc.exe` (143KB) ✅
- (`bld/as` nunca foi pulado — `bwasaxp/bwasmps/bwasppc` já existiam do boot.)

### 19.3 Validação exemplos (`build/test_examples.bat`, `PASS=3 FAIL=0`)

- `examples/hello.c` → `wcc386+wlink clib3r` → `Hello, Open Watcom World!` ✅
- `examples/hello.cpp` → `wpp386+wlink plib3r` → `Hello world!` ✅
- `examples/math_test.c -fpc` → `math3r+clbrdll` → `sqrt/sin/cos/exp/log` corretos ✅
- Evitar em teste auto: `Hello_c.c` (`getch`), `ExampleC++/HelloWorld/Hello.cpp`
  (`cin.get`), `ExamplesC/ex1.c` (usa `tcclib.h` do TCC, não OW).

---

## FASE 20: Estado atual e pendências (08/10/2026)

### 20.1 `rel/binnt`: 79 `.exe`, 28 zerados (placeholders do `mkinf -x`)

| Grupo (parte) | Zerados | Obs |
|---|---|---|
| Núcleo C/C++ 32-bit | **0** — `wcc386,wpp386,wlink,wlib,wasm,wrc,wmake,wtouch,wstrip,wcl386,owcc,wdump,dmpobj,wipfc,wcc,wpp,wdis,wccaxp,wasaxp,wasppc` reais | ✅ completo |
| Parte 3 — vi/browser | `vi.exe,viw.exe,wbrw.exe,wbrg.exe` (RC=5; `vi`/`browser` falham no link) | ⏳ |
| Parte 4 — debugger | `wd.exe,wdw.exe` + trap servers `novserv,parserv,serserv,tcpserv.exe` | ⏳ (stack mad/dip/trap não tentada) |
| Parte 5 — GUI tools | `wre,wde,wspy,wzoom,wimgedit,wddespy.exe,wbrg.exe,wprof.exe` + `bpatch,dbginst,mkcdpg,rfx.exe,_drwin95.exe` | ⏳ libs (`gui,ui,wpi,commonui,wres`) OK |
| Parte 6 — IDE | `ide.exe,ide2make.exe` (precisa `compile_gml_to_xxx` via DOSBOX; `browser` precisa `dlgprs` pulado p/ conflito `g++` vs operador `++` do wmake) | ⏳ |
| Parte 7 — Fortran | `wfc,wfc386,wfl,wfl386.exe` (precisa `errsrc`; `OWNOBUILD` pula) | ⏳ deliberado |
| Parte 8 — docs | `*.hlp/*.cnt/*.chm/*.pdf/*.inf/*.ihp` zerados (precisa DOSBOX+wgml+HHC) | ⏳ |
| Diversos | `drwatcom.exe` | ⏳ |

Instalador atual `distrib/ow/bin/open-watcom-2_0-c-win-x86.exe` (~20MB,
installed ~71MB, `DISTRIB_RC=0`) embarca esses zeros — **núcleo C/C++
100% funcional**, resto documentado acima.

### 20.2 `.gitignore` — o que cobre e o que falta

**Cobre bem os artefatos de build:**
- `*.exe *.obj *.lib *.dll *.sym *.res *.map *.lnk *.log *.err *.tmp` e
  gerados (`*.gh *.grh *.grc *.gdf *.gpp *.lnk *.lnd`) → `bld/*/binbuild/`,
  `bld/*/*/nt386/` e `rel/` ficam invisíveis p/ o git.
- `/*/` + exceções (`!/bld/ !/build/ !/ci/ !/contrib/ !/distrib/ !/docs/`) →
  **`rel/` e `distrib/ow/bin/` inteiros ignorados** (instaladores não poluem).
- `/build/*/` (só diretórios) → `build/binbuild/`, `build/tmp_test/` ignorados.

**NÃO cobre (vira ruído `untracked`):**
- `build/*.bat` novos da sessão (`win_complete, win_tools2, setupgui_*, mkdisk_build, distrib_*, part1*, part2*, wmake_fix, smoke_wcc, test_examples`) — `/build/*/` só pega diretórios, não arquivos. Sugestão: `!/build/*.bat` explícito ou mover p/ `build/scripts/`.
- `examples/*.exe *.obj *.tds *.err` (`hello.exe, hello.obj, *.tds` já existem no disco) — `*.exe/*.obj/*.err` cobertos, mas **`*.tds` não**.
- `marco.md`, `skill.md`, `Jimi.md`, `setvars_*.bat`, `build_full.bat` na raiz — trackeados/novos por desenho (documentação e conveniência local).
- `bld/*/binbuild/`, `bld/*/nt386/` com fontes gerados não-listados — maioria coberta por extensão; `*.dbg` do debugger? coberto (`*.dbg` não está na lista! `bld/wv/dbg/*/*.dbg` tem exceção própria p/ sources). Verificar se `*.dbg` binários vazam.

**Recomendação:** adicionar ao `.gitignore`:
```
*.tds
/build/*.bat
```

### 20.3 Próximos passos por parte

- [x] Parte 3: investigar `vi`/`browser` → ✅ CONCLUÍDO (08/10/2026, FASE 21)
- [ ] Parte 4: `dip/mad/rsilib/wattcp/trap/wv` p/ `wd/wdw` + servers
- [ ] Parte 5: `sdk/*` (wre/wde/spy/zoom/imgedit) + `wprof/wsample`
- [ ] Parte 6: `ide` (wgml via DOSBOX) ou documentar como fora de escopo local
- [ ] Parte 7: Fortran (`errsrc`) — decidir escopo (instalador `f77` separado já existe)
- [ ] Parte 8: docs NT (`builder docs docnt` com DOSBOX) + `builder install` final
- [ ] Re-rodar `build/test_examples.bat` após cada parte (zero regressão)

---

## FASE 21: Parte 3 — vi/browser ✅ (sessão 08/10/2026)

Regra da sessão: builds via `.bat` em `%TEMP%\opencode\`, nenhum fonte
editado via regex/PowerShell (só `Read`/`Edit` pontual + `builder`/`wmake`).
Regressão `build/test_examples.bat` (`PASS=3 FAIL=0`) re-validada após cada
`cprel`. Zerados em `rel/binnt`: 28 → 24.

### 21.1 `vi`/`viw` — dependência `rcsdll`

Sintoma: `bld/vi/nt386` compilava todos os `.obj` mas link falhava:
`Error(F38): (..\..\..\bld\rcsdll\nt386\rcsdll.lib) does not exist`.
Causa: `bld/rcsdll` nunca tinha sido construído no self-host
(`win_tools2.bat` não o inclui na lista). Solução: `builder build os_nt
cpu_386` em `bld/rcsdll` (com `cmnvars.bat` — sem ele, `local.mif(795)`
dá `E59 !IF Parse Error` porque `__BLD_WATCOM_TOOLS__` fica indefinido;
artefato de ambiente, não bug real) → `RC=0` (`rcsdll.dll` 42KB +
`rcsdll.lib`). Depois `builder build` em `bld/vi` → `VI_RC=0`
(`nt386/vi.exe` + `nt386.win/viw.exe`) e `cprel` dos dois projetos →
`rel/binnt/vi.exe` (353KB), `viw.exe` (518KB), `rcsdll.dll`.

### 21.2 `browser` — `dlgprs` + `OWNEWWGML=1`

Sintoma 1: `bld/browser/gen` falhava `Cannot execute (dlgprs)`.
Causa: `dlgprs` é host-tool ("Currently not built by default" no
`builder.ctl`, e `OWNOBUILD` o pula). Solução: build manual Εντός
`bld/browser/dlgprs/binbuild` com `wmake -f ..\binmake bootstrap=1
bld_os=nt bld_cpu=386` (padrão `mkdisk_build.bat`) → `DLGPRS_RC=0`,
sem o conflito `g++` vs operador `++` do wmake temido na FASE 20.
`dlgprs.exe` (95KB) copiado p/ `build/binbuild/` (entra no PATH dos builds).

Sintoma 2: `bld/browser/brg/nt386` OK (`wbrg.exe`), mas `nt386/wbrw.exe`
falhava em `wgml wbrw.gh` — `docs/gml/dos/wgml.exe` é 16-bit,
incompatível com Windows x64 (mesma classe do `ide`, ver Parte 6).
Causa/solução: `docs/mif/master.mif` tem `run_wgml_new` (usa `wgml` do
PATH — `build/binbuild/wgml.exe` nativo 64-bit) ativado por env
`OWNEWWGML=1` (`build/mif/wgmlcmd.mif` documenta o `run_wgml` antigo
via DOSBOX). Com `OWNEWWGML=1` → `BROWSER_RC=0` + `cprel` →
`rel/binnt/wbrw.exe` (941KB), `wbrg.exe` (174KB).

### 21.3 Ação recomendada (não aplicada — requer decisão)

Propagar `set OWNEWWGML=1` para os `.bat` de build (`win_complete.bat`,
`win_tools2.bat`, `distrib_build.bat`, etc.) — resolve a mesma classe de
falha em `ide` (Parte 6) e docs (Parte 8). `whpcvt.exe` nativo já existe
em `build/binbuild/`.

---

## FASE 22: Parte 4 — debugger + trap servers ✅ (sessão 08/10/2026)

Mesma regra da FASE 21 (builds via `.bat` em `%TEMP%\opencode\`, sem
editar fontes; regressão `PASS=3 FAIL=0` re-validada). Zerados em
`rel/binnt`: 24 → 16 (`wd, wdw, novserv, parserv, serserv, tcpserv,
rfx, dbginst` resolvidos).

### 22.1 Ordem de build (`dip → mad → rsilib/wattcp → trap → aui → wv`)

- `bld/dip` → `DIP_RC=0` (5 DLLs: `dwarf, codeview, watcom, export,
  mapsym`) + `cprel` → `rel/binnt/*.dll`.
- `bld/mad` → `MAD_RC=0` (4 DLLs: `madx86, madaxp, madppc, madmps`) +
  `cprel`.
- `bld/rsilib`, `bld/wattcp` → `RC=0` no-op (sem alvo `nt386`; só DOS).
- `bld/trap` via `builder build os_nt cpu_386` → constrói `lcl/nt/std386`
  (`std.dll`), `net` (`netserv.exe`), `nov/par/ser` (`novserv, parserv,
  serserv.exe` + `.dll`s) mas **trava em `ser/ntx64.trp`** com o clássico
  `Error(E14): Cannot execute (zq)` — variante host `x64` (`host_cpu=x64`
  no makefile, tag `#pmake: ... cpu_386 ... x64`) não tem toolchain
  (`bcl_x64` vazio em `local.mif`; mesma causa-raiz da FASE 18). Fora do
  escopo da distro 32-bit (`binnt`, não `binnt64`).
- `tcp/nt386.srv` + `tcp/nt386.trp` construídos com **`wmake -f makefile`
  direto** no subdir (o `builder` sempre volta à raiz do projeto e
  re-atinge o `ntx64.trp` quebrado) → `TCP_SRV_RC=0`, `TCP_TRP_RC=0`
  (`tcpserv.exe` 38KB + `tcp.dll`).
- `bld/wv` travava em `..\..\..\..\bld\aui\nt386\aui.lib` ausente
  (mesma falta que quebrava o `wprof` na Parte 5). `bld/aui` tem tag
  `#pmake: build os_nt cpu_386` mas nunca entrou nas listas
  (`builder.ctl` vazio — "not built by default"): `builder build` →
  `AUI_RC=0` (`aui.lib` em `nt386` + `nt386.gui`, 197KB).
- Retry `bld/wv` → `WV_RC=0` (`nt/nt386/wd.exe` 593KB,
  `nt/nt386.gui/wdw.exe` 910KB, `rfx/nt386/rfx.exe` 70KB).
- `cprel` de `dip/mad/trap/wv` → `CPREL_*=0`; bônus: `dbginst.exe`
  (de `trap/par/ntsupp`) também saiu dos zerados.

### 22.2 Pendência conhecida (fora do escopo `binnt`)

Variantes `*/ntx64.trp` do `trap` (ex.: `ser/ntx64.trp`) exigem toolchain
x64-host que o OW não define (`local.mif` só tem `bcl_386/axp/ppc/mps`).
Só afeta `binnt64`; documentado, não bloqueia.

---

## FASE 23: Parte 5 — GUI tools + wprof/wsample ✅ (sessão 08/10/2026)

Mesma regra (builds via `.bat` em `%TEMP%\opencode\`, sem editar fontes;
regressão `PASS=3 FAIL=0`). Zerados em `rel/binnt`: 16 → 9 (`wprof,
wre, wde, wspy, wzoom, wimgedit, wddespy` resolvidos).

### 23.1 Ordem de build (dependências `sdk` primeiro)

- `bld/wprof` → `WPROF_RC=0` direto (o `aui.lib` da FASE 22 destravou;
  `nt386/wprof.exe` console + `nt386.gui/wprof.exe` GUI) + `cprel` →
  `rel/binnt/wprof.exe` (261KB) + `wprofc.exe`.
- `bld/wsample` → `RC=0` (já existia em `rel/binnt`, 42KB; `cprel` refeito).
- `bld/sdk/spy|zoom|ddespy` → exes linkados (`wspy.exe` 185KB,
  `wzoom.exe` 51KB, `wddespy.exe` 137KB) mas `RC=5` (variante posterior
  irrelevante p/ `binnt`; artefatos `nt386` intactos).
- `bld/sdk/wre` travava em `wresedit/waccel/nt386/wacc.lib` ausente;
  `bld/sdk/wde` em `fmedit/nt386/fmedit.lib`; `imgedit` em
  `wr/nt386/wr.lib` — mesmo padrão `aui` (libs nunca entraram nas listas).
  `builder build` em `sdk/wr` (`wr.lib` 24KB + `wr.dll`), `sdk/fmedit`
  (`fmedit.lib` 13KB + `fmedit.dll`), `sdk/wresedit` (`WRESEDIT_RC=0`:
  `wacc/wmenu/wstring.dll`) → retry `wre` (`WRE_RC=0`, 220KB),
  `wde` (417KB), `imgedit` (282KB).
- `cprel` de `wprof/wsample/wr/fmedit/wresedit/wre/wde/spy/zoom/imgedit/
  ddespy` → todos `RC=0` (inclui DLLs de runtime `wr/fmedit/wacc/wmenu/
  wstring.dll` + `ntspyhk.dll` em `rel/binnt/`).

### 23.2 Restantes (9 zerados)

`ide.exe` (Parte 6), `wfc/wfc386/wfl/wfl386.exe` (Parte 7, Fortran),
`bpatch/mkcdpg/_drwin95/drwatcom.exe` (diversos — avaliar na Parte 8).

---

## FASE 24: Parte 6 — IDE ✅ (sessão 08/10/2026)

Mesma regra (builds via `.bat` em `%TEMP%\opencode\`, sem editar fontes;
regressão `PASS=3 FAIL=0`). Zerados em `rel/binnt`: 9 → 8.

`bld/ide` (lib + ide2make + ide + cfg) com `OWNEWWGML=1` → `IDE_RC=0`:
o `ide/ide/nt386` gerou `ide.gh` com o `wgml` nativo 64-bit
(`build/binbuild/wgml.exe`, o mesmo fix da FASE 21 que destravou o
`wbrw`), compilou e linkou `ide.exe`. `cprel` → `CPREL_IDE=0`:
`rel/binnt/ide.exe` (499KB) + `ide2make.exe` + `ide*.cfg` + `rel/ide.doc`.
Confirma a ação recomendada da FASE 21.3: `OWNEWWGML=1` elimina a
dependência de DOSBOX para os `.gh` de help no Windows x64.

---

## FASE 25: Parte 7 — Fortran ✅ (sessão 08/10/2026)

Escopo decidido: **tentar completo** (instalador `f77` separado existe,
mas o `errsrc` segue o mesmo padrão `dlgprs` que funcionou).
Mesma regra (builds via `.bat` em `%TEMP%\opencode\`, sem editar fontes;
regressão `PASS=3 FAIL=0`). Zerados em `rel/binnt`: 8 → 4.
Bônus: `rel/lib386/nt/flib.lib, flibs.lib, flib7.lib, flib7s.lib`
(4 zerados de lib) resolvidos.

### 25.1 `errsrc` (host-tool)

`builder build bintool` em `bld/f77/utils` é no-op (`RC=0` sem artefato:
o bloco `[BLOCK <BINTOOL> build]` só é ativado pela regra `boot`, ver
`build/defrule.ctl:20-25`). Caminho correto: `builder boot` no dir →
compila `errsrc.exe` via `binmake` e o bloco `BINTOOL` copia para
`build/binbuild/errsrc.exe` (38KB, entra no PATH).

### 25.2 `wfc/wfl/f77lib`

- `bld/f77` com `OWNOBUILD=` (vazio — antes pulava `f77lib f77wfc f77wfl`):
  `wfc/386/nt386/wfc386.exe` (814KB) OK, mas `wfc/386/nt386.rtd`
  (variante DLL-runtime, tag `rtdll`) falha: `W1008: cannot open
  mt7rdll.lib` (variante MT-DLL nunca construída — zerada em
  `rel/lib386/nt/`) + `E2028: __CHP`, `__imp___get_EFG_Format_` indefinidos
  (símbolos de code-page da CRT-DLL). Builder para no 1º erro (`F77_RC=1`).
- Contorno sem editar fontes: `wfl` e `f77lib` construídos em separado
  (`WFL_RC=0`: `wfl386.exe` 64KB + `wfl.exe` 63KB i86; `F77LIB_RC=0`:
  `flib/flibs/flib7/flib7s.lib` — `errsrc` funcionou, 207 phrases) e
  `wfc/i86/nt386` (tag `target_i86`, que o `build os_nt cpu_386` puro pula
  — mesmo padrão do `target_axp` da FASE 19) com `wmake -f makefile`
  direto (`WFC_I86_RC=0`, `wfc.exe` 814KB).
- `cprel` dos 3 → `RC=0`: `rel/binnt/wfc.exe, wfc386.exe, wfl.exe,
  wfl386.exe` + 4 libs. Smoke: `wfc386.exe` exibe banner
  `Open Watcom FORTRAN 77 x86 32-bit ... Oct 8 2026`.

### 25.3 Pendência conhecida

`wfc/386/nt386.rtd` (e `mt7rdll.lib`, `mthrdll` etc. em `rel/lib386/nt/`)
exigem variantes MT-DLL da CRT nunca construídas — mesmo tema do `rtdll
mf_rp` da FASE 15.8. Só afeta Fortran com `-br` (DLL runtime); uso com
runtime estático não é afetado.

---

## FASE 26: Parte 8 — diversos + install final ✅ (sessão 08/10/2026)

Mesma regra (builds via `.bat` em `%TEMP%\opencode\`, sem editar fontes
— exceto `build/*.bat` + `.gitignore`, com `Read`/`Edit` e aprovação;
regressão `PASS=3 FAIL=0`). **Zerados `.exe` em `rel/binnt`: 4 → 0.**

### 26.1 Últimos 4 exes

- `bld/bdiff` → `BDIFF_RC=0` (`bpatch.exe` 55KB + `bdiff/bdump/bpcmt/
  bplevel/wpatch/wcpatch.exe) + `cprel` → `rel/binnt/bpatch.exe`.
- `bld/rc/mkcdpg` → `MKCDPG_RC=0` (`mkcdpg.exe` 33KB) + `cprel`.
- `bld/sdk/drwat` → `DRWAT_RC=0` (`nt386/drwatcom.exe` 197KB +
  `win95/drwatcom.exe` 184KB) + `cprel` → `rel/binnt/drwatcom.exe` +
  `_drwin95.exe` (o `win95/` é a origem do `_drwin95`).

### 26.2 Ação 21.3 aplicada: `OWNEWWGML=1` nos 15 `.bat` de `build/`

`win_complete, win_tools2, part1_16bit, part1b_dwarf_cg, part2_risc,
part2b_axp, setupgui_build, setupgui_deps, setupgui_deps2, mkdisk_build,
distrib_build, distrib_missing, wmake_fix, autohost, autohost2`
(verificado: `cmnvars.bat` não limpa a var, inserção única basta).
`.gitignore` += `*.tds` (recomendação FASE 20.2; `/build/*.bat` NÃO
adicionado — ocultaria os `.bat` de build versionados).

### 26.3 Instalador final: `DISTRIB_RC=0`

`build/distrib_build.bat` → `distrib/ow/bin/open-watcom-2_0-c-win-x86.exe`
(~27MB, era ~20MB com zeros) + `open-watcom-2_0-f77-win-x86.exe` (~15MB).

### 26.4 Docs: fora de escopo local (ferramentas ausentes)

`rel/binnt` ainda tem 142 zeros não-`.exe`: 39 `.hlp` + 39 `.cnt` + 37
`.chm` (precisam HHC/HCW — `hhc.exe` não instalado, sem HTML Help
Workshop), 13 `.dll` (variantes MT-DLL: `clbs/mt7r/mt7s/mths/plbr/plbs20`
+ `vdm/wccd386/weditcw/weditviw/wlinkd/wppd386/wrcd` — mesmo tema
FASE 15.8/25.3), 6 `.sym`, codepages. Zeros em `binl/binp` etc. são de
outras plataformas (`mkinf -x`), irrelevantes p/ `instwin32`.

---

## FASE 27: Itens 2+3+4 — MT-DLL, Fortran .rtd, toolchain x64 ✅ (08/10/2026)

Regra da sessão (builds via `.bat` em `%TEMP%\opencode\`, `Read`/`Edit`
pontual com aprovação, sem regex/PowerShell em fontes). Regressão
`PASS=3 FAIL=0` após cada etapa. Zeros: `rel/lib386/nt/*.lib` 8 → 0,
`rel/binnt/*.dll` MT-DLL 7 → 0 (restam só 6 `*d*.dll` de ferramentas).

### 27.1 Item 2 — 6 variantes rtdll (A→F)

Pré-requisitos verificados antes: `math387r/s.lib`, `export.gdf` em
`mf_{r,s}.dll`/`mf_s.dll`(387), `exportx.gdf` + `plbxmt3r/s.lib` em
`mf_rmt[.dll]`/`mf_smt[.dll]` — tudo presente do bootstrap. Faltavam só:
- `clib mf_s/export.gdf` → gerado pelo mecanismo oficial
  (`wmake -f makefile linkage=dynamic` — override por linha de comando,
  sem editar o makefile; `wlib -z=export.tmp` + `sed`, ver
  `bld/clib/mrglib.mif:14-23`), depois rebuild `static` (byte-idêntico:
  648.704) + `.bak` removido.
- `math mf_s/math_export.gdf` → `mf_r` vs `mf_rp` são byte-idênticos
  (230 linhas, independe de convenção) → cópia + conversão register→stack
  (strip de `_` final via `dmpobj`-validação) + dedup (246) − 27 nomes
  ausentes no stack (Bessel `__P0P…`, `___d_infinity…`, `__get_EFG_*`,
  `finite/watof/gcvt…`, validados um a um contra o link) = 220 linhas.

Diagnóstico-chave (via `dmpobj` em objetos `-3r` vs `-3s`): a convenção
muda a decoração (`myfunc_`/`__P0P`/`___d_infinity` vs `myfunc`/`_P0P`/
`__d_infinity`) — comportamento correto do compilador, não bug. O
`E2028+E2044` em massa era `math3s.lib` de jul/GCC (obsoleta) + `.gdf`
com nomes register. Rebuild limpo de `math3s.lib` (self-host) +
rel/`clib3s.lib,math3s.lib` sincronizadas.
- A `clib/rtdll mf_s` → `clbs20.dll` (301KB) + `clbsdll.lib` (177KB)
- B/C/D `mathlib/rtdll` → `mths20/mt7r20/mt7s20.dll` + import libs
- E/F `cpplib/rtdll` → `plbr20.dll` (132KB) + `plbrdll[x].lib`,
  `plbs20.dll` + `plbsdll[x].lib` (E precisa de C, F de A+D — respeitado)
- Prova funcional: `wcl386 -ms -br hello.c` → PASS contra `clbs20.dll`;
  `wpp386 -br hello.cpp` + `plbrdll.lib` → PASS contra `plbr20.dll`.
  Nota: `wcc+wlink` crus com `-ms` falham em `main` vs `main_` (pré-existente,
  driver `wcl` trata; afeta estático e DLL igualmente, fora de escopo).

### 27.2 Item 3 — `wfc/386/nt386.rtd` ✅

Com `mt7rdll.lib` presente, o link que falhava (`W1008 mt7rdll.lib`,
`E2028 __CHP/__imp___get_EFG_*`) passou de primeira (`WFC_RTD_RC=0`,
770KB). Causa-raiz confirmada: só faltava a import lib MT.

### 27.3 Item 4 — `*_x64` em `cproj.mif` + `local.mif` ✅

Causa-raiz: `cc_$(host_cpu)`/`bcc_$(bld_cpu)` etc. só definidos p/
`386/axp/ppc/mps` (`cproj.mif:24-96`, `local.mif:752-778`); `host_cpu=x64`
(`target_cpu=x86` continua 32-bit!) dava ferramenta vazia → `zq`.
Fix (+17 linhas, com comentário): `cc/cl/cxx/linker/librarian/as_x64`
→ equivalentes `386` (`*wcc386…`/`*bwcc386…` nos dois ramos) e
`bcc/bcxx/bcl/bas/blibrarian_x64` em `local.mif` (32-bit via WOW64;
CI upstream já prevê `cpu_x64`). `builder build` do `trap` inteiro →
`TRAP_RC=0` (inclui `ser/ntx64.trp` → `rel/binnt64/ser.dll` e bônus
`vdm/nt386.trp` → `vdm.dll` em `binnt`). Sem regressão.

### 27.4 Restantes (fora do escopo 2+3+4)

- 6 `.dll` de ferramentas-debug: `wccd386/wppd386/wlinkd/wrcd/weditcw/
  weditviw.dll` (outra família — DLLs das próprias ferramentas).
- Docs `.hlp/.cnt/.chm` (sem HHC), `main` vs `main_` no `-ms` cru,
  `binl/binp` (outras plataformas).
- Instalador reconstruído: `c` ~27,5MB + `f77` ~15,9MB (`DISTRIB_RC=0`).

---

## FASE 28: DLLs das ferramentas (`*d*.dll`) ✅ (08/10/2026)

Regra da sessão (diagnóstico só-leitura, builds via `.bat` em
`%TEMP%\opencode\`, sem editar fontes; regressão `PASS=3 FAIL=0`).
Zeros `.dll` em `rel/binnt`: 6 → 0.

### 28.1 Origem (todas tinham `builder.ctl` com `cprel` p/ `binnt`)

- `wccd386.dll` ← `bld/cc/386/nt386.dll` (tag `target_386` — por isso o
  `build os_nt cpu_386` puro pulava; mesmo padrão do `target_axp`/FASE 19)
- `wppd386.dll` ← `bld/plusplus/386/nt386.dll` (idem `target_386`)
- `wlinkd.dll` ← `bld/wl/nt386.dll` (tag `dll`)
- `wrcd.dll` ← `bld/rc/rc/nt386.dll` (sem tag extra — nunca tinha entrado
  nas listas)
- `weditcw.dll` ← `bld/editdll/cw/nt386`, `weditviw.dll` ←
  `bld/editdll/viw/nt386` (tag `guitool`; DLLs de editor p/ IDE/`wdw`)

### 28.2 Builds (todos `RC=0`, bônus `.rtd` junto)

`builder build os_nt cpu_386 target_386` (cc/plusplus),
`build os_nt cpu_386 dll` (wl), `build os_nt cpu_386` (rc),
`build os_nt cpu_386 guitool` (editdll). De quebra vieram
`nt386.rtd` de cc/plusplus/wl/rc (variantes DLL-runtime das ferramentas,
  que falhavam no item 3 por falta do `mt7rdll.lib` — agora presente).
`cprel` dos 5 projetos → `rel/binnt/` recebe as 6 DLLs + `.sym`s.
Efeito colateral correto (layout upstream driver+DLL via `loaddll`):
`wcc386/wpp386/wlink/wrc.exe` de ~9-15MB monolíticos viram drivers ~32KB
+ DLLs; `wlink.lnk` + `.uni` agora copiados p/ `binnt/` (torna o
workaround `WLINK_LNK` da FASE 15.1b redundante, mantido por segurança).

### 28.3 Validação

Banners OK (`wcc386/wpp386/wlink/wrc` exibem versão Oct 8),
`test_examples.bat` `PASS=3 FAIL=0`, instalador reconstruído
(`DISTRIB_RC=0`, `c` ~27MB — menor porque driver+DLL ocupa menos que
monolíticos). Restam em `binnt`: só docs `.hlp/.cnt/.chm` (sem HHC).

---

## FASE 29: Suítes de regressão ctest/plustest ✅ (08/10/2026)

Primeira execução das suítes oficiais nesta pipeline. Infra prévia:
`bld/testutil` via `builder boot` (chk_exec/chktest/catfile → BINTOOL,
mesmo padrão do `errsrc`/FASE 25) e overlay `build/bwlink.lnk` →
`rel/binnt/wlink.lnk` (o `cprel` do `wl` restaura um fragmento corrupto
com `wlink.lnk#` na linha 22 → `E3033`; re-aplicar após cada `cprel` do wl).

### 29.1 Barreira E14 + solução (sem editar fontes)

`Cannot execute (wcc386/wlink): Exec format error` com nomes simples —
quirk de resolução do `wmake` com PATH interno gigante (provado por
bisseção: literal funciona, macro não). Solução: overrides absolutos
(`CTEST_WCC_386`/`PLUSTEST_WPP_386` por env — hooks já existentes em
`testenv1.mif:605/740` — + `linker=<abs>` por linha de comando,
precedente `linkage=dynamic`/FASE 27). Para `linker` não há hook env;
sugerido `%CTEST_LINKER%` futuro em `testenv1.mif:988` (não aplicado).

### 29.2 ctest: 4/5 PASS

positive, codegen, callconv, inline → PASS. diagnose → FAIL pré-existente:
W115 ausente (3 sítios em diag0012.c) + E1046 off-by-one (`inc3.h(60)`
vs `59`) — **byte-idênticos entre `bwcc386` (GCC) e `wcc386` (self-host)**,
logo comportamento do snapshot, zero regressão nossa.

### 29.3 plustest: 23 PASS, 4 FAIL (todos atribuídos, zero regressão)

- diagnose/except/positive/re2c05 FAIL; demais 23 PASS.
- except (EH dtors linha 65): `bwpp386` vs `wpp386` com flags idênticas
  (`-ox-d1-xst -mf`) → **saídas byte-idênticas** (inclusive sem os dtors).
- positive (`FAIL executing float03/i6403/opt03/setjmp03`, 675 PASS):
  A/B com flags exatas → saídas idênticas BW vs REL; `-fpc` não muda
  (não é o quirk FPU-inline/FASE 13.7) — igualdade exata de doubles sob
  `-ox`/`-ms`, pré-existente nos dois compiladores.
- re2c05: só carimbos (`Generated by re2c on <data>`, `$Log$`) — ambiental.
- Dirs sem veredito único (cool/torture/stl.94-95/perl/re2c/splash/test/
  wclass/yacl/mscompat/nih/dcmat/extref): `F05 No targets specified` ou
  harness próprio — variantes auxiliares, fora do núcleo de validação.

---

## FASE 30: README LabsObjects + exemplo Fortran ✅ (08/10/2026)
- `README.md` reescrito: logo `OpenWatcom.png`, proposta LabsObjects,
  estado da edição, uso rápido C/C++/Fortran, build do fonte, layout
  atualizado, licença. Upstream preservado em forma condensada.
- `license.txt`: adendo LabsObjects no topo, OWPL 1.0 intacta abaixo.
- `examples/hello.for` (novo): `wfc386 hello.for -fo=hello.obj` +
  `wlink … library flib.lib,math387r.lib,math3r.lib,clib3r.lib,…` →
  executa (`__iFDLD` exige `math387r.lib`). Achado: driver `wfl386`
  trava (null deref após compilar) — documentado two-step no README.

---

## Glossário

| Termo | Definição |
|-------|-----------|
| OW | Open Watcom |
| wmake | Watcom's make utility (compatível com sintaxe OW) |
| builder | Ferramenta de build OW (lê arquivos .ctl) |
| bootstrap | Processo de compilar OW com um compilador não-OW |
| rel | Release directory (`rel\`) - destino dos binários finais |
| wcc386 | Compilador C OW para 32-bit |
| wpp386 | Compilador C++ OW para 32-bit |
| wlink | Linker OW |
| wasm | Assembler OW |
| wlib | Librarian OW |
| ctl | Control file (scripts do builder) |
| mif | Make include file |
| binmake | Makefile usado para bootstrap de cada projeto |

---

## FASE 31: Auto-versionamento 2.0.N + melhorias A/B ✅ (08/10/2026)

### 31.1 Auto-incremento (pedido LabsObjects)

- `build/version.bin` (1 inteiro ASCII, começa em 0) +
  `build/bumpver.bat` (lê/incrementa/exporta `OWBLDVER_PATCH`;
  defensivo contra expansão vazia — `echo %V%>` com var vazia grava
  o texto de status no arquivo; usar forma `>"file" echo %V%` + guard).
  **Lição: arquivos lidos por `set /p` devem ser ASCII limpo**
  (Write tool pode gravar BOM — gerar via `Set-Content -NoNewline`).
- `bld/watcom/h/banner.h`: `#ifdef _BLDVER_PATCH` → `"2.0." N`
  (uniforme p/ todas as ferramentas via `BAN_VER_STR`).
- `build/mif/cproj.mif` (`ppflags_common`): `-D_BLDVER_PATCH=$(%OWBLDVER_PATCH)`
  quando env definida (compatível: sem env → `2.0` como antes).
- Chamada 1× no início de `win_complete`, `part1_16bit`, `part1b_*`,
  `part2_risc`, `part2b_axp` (só onde há rebuild de compilador).
- Validado: bump → 1, rebuild limpo `cc/386/nt386.dll` →
  `Version 2.0.1 beta` no banner + `test_examples PASS=3 FAIL=0`.
- Nuance honesta: o patch vale p/ objetos COMPILADOS no run (wmake não
  recompila por mudança de flag; `banner.h` mudou mas o autodepend dos
  `dllobjs` não disparou — foi preciso `clean`). `genverrc`/`$4`
  (FILEVERSION é time-based; nenhum skeleton usa `$4`) fora de escopo.

### 31.2 Melhoria B ✅ — `-ms` cru: sem bug, receita `system nt`

`wcc -ms` + `form windows nt` + `library clib3s.lib` falha (`main` vs
`main_`), mas `wcc -ms [-br]` + **`system nt`** (sem `library` explícita;
`wlink.lnk` + default-lib records selecionam startup/libs) → LINK 0 +
RUN 0 (estático e `-br`). Idem C++ (B2 FASE 27). Melhoria = documentação
(README) — sem tocar codegen. Pré-requisito consertado junto:
- `rel/binnt/wlink.lnk` estava duplamente quebrado: (1) linha `wlink.lnk#`
  do `specs.sp` → `E3033` (removida a linha 1 do `specs.sp`; `wsplice`
  não precisa dela com `$@` explícito — regeneração verificada limpa);
  (2) overlay `bwlink.lnk` (FASE 15.1b) quebrava usuário final
  (`%OWROOT%/bld`, `W1115`). Arquivo final curado: blocos únicos
  286/386 + bloco `nt` novo (cópia do 386, paths `%WATCOM%`) → links
  `system nt` com zero warnings. `WLINK_LNK=bwlink.lnk` mantido nos `.bat`
  (builds precisam dos libpaths de `bld/`).

### 31.3 Melhoria A ✅ — `wfl386` crash em `CompLink_` (resolvido 09/10/2026, FASE 32)

- Causa raiz (não era codegen): `ListAppendString` (`wfl.c:379`) nunca
  inicializava `p->next` e `ListAppend` (`wfl.c:344`) nunca zerava
  `new->next` — cauda da `File_List` com ponteiro garbage. `CompLink`
  processava o 1º arquivo OK (`wfc386` compilava) e andava para o
  garbage (`strcpy` em `wfl.c:1086`, ESI=0/`0xb3xx`). Por isso o guard
  NULL só deslocava o crash e o rebuild self-host não curava.
- Fix: `new->next = NULL` em `ListAppend` + `p->next = NULL` em
  `ListAppendString`; guard paliativo revertido. Rebuild
  (`builder build os_nt cpu_386` + `cprel` em `bld/f77/wfl`) → `wfl.exe` +
  `wfl386.exe` novos em `rel/binnt/`. Só `AddDirectivePath` zerava `next`
  antes — padrão correto agora uniforme.
- Validação: `wfl386 hello.for -fe=hello.exe` → `RC=0`, exe executa
  (`Hello, Open Watcom Fortran!`); `-c` OK nos dois drivers (386/i86);
  `test_examples.bat` estendido p/ `[4/4]` Fortran → `PASS=4 FAIL=0`.

---

## FASE 32: Melhoria A concluída + fix parser `wfl` ✅ (sessão 09/10/2026)

Regra da sessão (builds via `.bat` em `%TEMP%\opencode\`, `Read`/`Edit`
pontual com aprovação, sem regex/PowerShell em fontes).

### 32.1 Crash `wfl386` — causa raiz e fix (`bld/f77/wfl/c/wfl.c`)

Reproduzido: `wfl386 hello.for -fo=hello.obj` compilava OK e crashava em
seguida (`0x004024b8`, ESI=0). O `.map` de `bld/` era de build anterior
(`rel/binnt/wfl386.exe` 64KB vs `nt386` 72KB) — diagnóstico final por
leitura de código, não pelo EIP.

- `ListAppendString` não inicializava `p->next`; `ListAppend` não zerava
  `new->next` (só `AddDirectivePath` fazia). Cauda da `File_List` =
  garbage → `ListItemFree` retornava garbage → `strcpy` crashava.
- Fix (3 linhas): `new->next = NULL` + `p->next = NULL`, guard paliativo
  revertido. `builder build os_nt cpu_386` + `cprel` → `RC=0` (386 + i86).

### 32.2 Parser `Parse` — `-`/`/` no meio do token (mesmo arquivo)

Achado ao validar: paths com `-` (ex. `open-watcom-v2-master`) eram
fatiados em pseudo-opções (`-watcom`, `-v2` → `CO-05` + `SM-02`), porque
o scan quebrava o token em qualquer `CmdScanSwitchChar`.

- Fix: removido o `break` por switch-char no meio do token — nova opção
  só começa após espaço (classificação no início do loop, mantida).
  Contrapartida documentada: flags grudadas (`-c-y`) deixam de separar;
  uso normal é separado por espaço.
- Bônus (1 linha): pula aspas de fechamento (`"arq" -op` não grudava o
  próximo token).
- Limite pré-existente FORA deste fix (driver `wfc`, não `wfl`): o
  `wfc386` não aceita valor de `-fo=` com `-` nem com aspas (`CO-05` /
  `Usage`). Workaround: rodar `wfl386` no diretório do fonte com nomes
  relativos (é o que o `[4/4]` do `test_examples.bat` faz).

### 32.3 Fechamento

- `build/test_examples.bat`: `[4/4] hello.for` via `wfl386`
  (`-fe=`, nomes relativos, `cd` ida/volta) → **`PASS=4 FAIL=0`**, raiz limpa.
- README: nota do two-step removida (driver corrigido), contagens `PASS=4`,
  referência a `fix.md`; limite do `-fo=` do `wfc386` documentado.
- `fix.md` criado: controle de melhorias da edição LabsObjects (só itens
  reais desta pipeline; regra permanente: melhoria nova → documentar lá).

## ESTADO ATUAL (09/10/2026, pós-FASE 32 — ver CONTINUAR DEPOIS no fim do arquivo p/ o estado final do dia)

### Na fila (não iniciado)

1. Bump de versão: `bumpver.bat` já é chamado pelos 5 `.bat`; lembrar que
   o patch só aparece em objetos RECOMPILADOS (forçar `clean` se preciso).
2. Docs `.hlp/.chm` (sem HHC) e 6 `*d*.dll` restantes — fora de escopo local.
3. `wfc386`: aceitar `-fo=` com `-`/aspas (parser do driver Fortran);
   hoje contornado com nomes relativos.

## FASE 33: ctx.exe na pipeline (opcional, sem dependência) ✅ (09/10/2026)

Exigência: usar o diário `ctx.exe` (`C:\ctx\ctx\bin`, no PATH) na pipeline,
mas **nunca** quebrar quem builda sem a ferramenta (build, distro e
compilador 100% funcionais sem ela).

### 33.1 Funcionamento apurado (sandbox em `%TEMP%\opencode\ctxlab*`)

- `ctx init <dir>` cria só `.ctx.yaml` (+ `.gitignore` se inexistente —
  **preserva** o existente; verificado com conteúdo prévio). Store real =
  `.ctx/` (ex.: `build-provenance.json`, bytes, backend `file`), criado no
  1º `build record`; massa (67MB) do projeto do próprio ctx vem do uso.
- Comandos: `build record <artefato>` (hash+timestamp), `build list`,
  `memory add`, `decision add`, `bugs`; tudo com `--offline` (sem rede).
- Resolução do store é pelo **CWD** (não pelo path do artefato, que pode
  ser absoluto). `init` anterior + `where` indisponível = sem efeito.
- `.gitignore` do repo intacto (244 linhas); snippet ctx (`.ctx.yaml`,
  `.ctx.backup/`, `*.key`, `rbac.yaml`) anexado — `.ctx/` já coberto por
  `/*/`.

### 33.2 Integração

- `build/ctx_log.bat <artefato>`: `where ctx.exe` → ausente = no-op `RC=0`;
  presente = `pushd %OWROOT%` + `ctx --offline build record` + `popd`.
  `pushd` (não `cd`) porque o `cd` vazava p/ o loop chamador e quebrava
  `%%~fF` na 2ª iteração (paths `bin\<arq>` — pego e corrigido em teste).
- `build/test_examples.bat`: 4 chamadas (os 4 exes da suíte).
- `build/distrib_build.bat`: `for %%F in (bin\*.exe)` com `"%%~fF"` (CWD lá
  é `distrib\ow`; path absoluto evita o `bin\bin` — pego e corrigido).
- `ctx` grava `compiler: go` (auto-detecção irrelevante p/ artefatos
  Watcom; hash+data são o valor). Registros de simulação removidos do
  diary (só entra o que a pipeline real gravou).

### 33.3 Validação (ambos os modos)

- COM ctx: suíte `PASS=4 FAIL=0` + `BUILD-0000x` dos 4 exes no diary.
- SEM ctx (PATH sem `C:\ctx`, `CTX-AUSENTE-OK`): suíte `PASS=4 FAIL=0`,
  `ctx_log` direto `RC=0`. Garantia atendida.

---

## FASE 34: Instaladores + pêndulos plustest ✅ (sessão 09/10/2026)

Regra da sessão (sem editar fontes; só overrides por env/linha de comando
no padrão FASE 29 + `.bat` em `%TEMP%\opencode\`).

### 34.1 Opção 1 — instaladores rebuildados

`build/distrib_build.bat` → `DISTRIB_RC=0`: `open-watcom-2_0-c-win-x86.exe`
(17,8MB) + `open-watcom-2_0-f77-win-x86.exe` (13,9MB), agora com o `wfl`
fixado (FASE 32). Proveniência gravada no diary pelo loop `ctx_log`.

### 34.2 Opção 2 — cool/torture/stl/perl: todos PASS

- `torture` (test0+test1): `lib tort.lib` falhava mudo (E42) — mesmo quirk
  E14 do `linker` (FASE 29): nome simples `wlib` não resolve com PATH
  interno gigante. Fix: `wlib_any=<abs>\wlib.exe` na linha de comando
  (flags `-n -b` preservadas, sem editar `testenv1.mif`). → PASS ×2.
- `perl` (test0+test1): `cc regex.obj` dava E14 — faltava o hook env:
  `set CTEST_WCC_386=<abs>\wcc386.exe` (par do `PLUSTEST_WPP_386`).
  → PASS ×2.
- `cool`, `stl.94`: o dir pai não tem target `test` (F05 esperado) — rodar
  os subdirs (`cool/tests`, `cool/examples`, `stl.94/demo`,
  `stl.94/examples`); `cool.lib` vem do `!include ../lib.mif` + override
  `wlib_any`. → `cool` PASS test0–3 (4 variantes), `stl.94` PASS test0–1.
- `stl.95` (test0+test1): já passava; confirmado PASS ×2.
- Quirk cosmético: `cool`/`stl.95` saem `RC=5` após o PASS (o `%append`
  final com path sem drive — veredito gravado mesmo assim; mesma família
  do RC=5 da FASE 21). Vereditos oficiais em `bld/plustest/*.log`.
- Scripts: `%TEMP%\opencode\run_pendulum*.bat`, `run_cool*.bat`.

---

## FASE 35: ctx Fase A+B na pipeline ✅ (10/10/2026)

Aprovado: uso ativo quando presente, sem tornar obrigatório (FIX-060 mantido).

### 35.1 Wrappers (mesmo padrão `ctx_log.bat`: `where` + `pushd` + `--offline`, sempre `RC=0`)

- `build/ctx_mem.bat "<titulo>" "<descricao>" [tipo]` → `memory add`.
- `build/ctx_checkpoint.bat` → `audit checkpoint` (grava `Checkpoint written
  (0 events)` — sem eventos de histórico no store `file`; não é falha).
- `build/ctx_smells.bat <arquivo> [log]` → `smells --file` (escopado, rápido;
  o `status`/scan do repo inteiro estoura 120s e ficou fora).

### 35.2 Chamadas

- `build/test_examples.bat`: + `ctx_mem` com veredito `PASS/FAIL` + 2×
  `ctx_smells` (`bld/f77/wfl/c/wfl.c`, `bld/wl/c/cmdutils.c` → `%T%\smells_*.log`).
- `build/distrib_build.bat`: + `ctx_mem` + `ctx_checkpoint` após o loop dos instaladores.

### 35.3 Validação (ambos os modos)

- Wrappers COM ctx: `0/0/0/0`; SEM ctx (`PATH` sem `C:\ctx`): `0/0/0/0`.
- `test_examples.bat` COM ctx: `PASS=4 FAIL=0`; SEM ctx: `PASS=4 FAIL=0`.
- `smells --file wfl.c`: `total=0`; `cmdutils.c`: `total=0` (fontes fixados limpos).
- Fase C adiada: `verify --strict`, `review`, `health` (scan do repo inteiro).

---

## FASE 36: `wfc` aceita `-fo=` com `-` e aspas ✅ (10/10/2026)

Pendência nº 3 do fechamento 09/10 (limite FASE 32.2). Reproduzido antes do
fix: `-fo=wfc-out.obj` → `CO-05` em massa (`out.obj` caía no
`CompoundOptOption` por começar com `o`) e `ObjName` truncado em `wfc`;
`-fo="..."` falhava (`No such file`, aspas iam p/ `ObjName`). Causa raiz em
`bld/f77/wfc/c/sdcline.c` (`MainCmdLine:98-102` quebrava o token em qualquer
`-`/`/` — mesma família do fix `wfl` FIX-032) + `FOOption` sem strip de aspas
(só `PathOption` tinha).

### 36.1 Fix (2 arquivos, sem regex/PowerShell em fontes)

- `sdcline.c`: removido o `break` por switch-char no meio do token — opção
  nova só começa após espaço (classificação no loop externo, mantida).
  Contrapartida documentada (igual FASE 32.2): flags grudadas (`-c-y`)
  deixam de separar; uso normal é separado por espaço.
- `option.c` (`FOOption`): strip de aspas ao redor do valor (padrão
  `PathOption`; buffer da linha de comando é modificável).

### 36.2 Rebuild + validação

- `builder build os_nt cpu_386` em `bld/f77/wfc` → `WFC386_RC=0` (incl.
  `nt386.rtd` e `i86/nt386`); `CPREL_WFC=0` → `rel/binnt/wfc.exe`,
  `wfc386.exe` novos. Script: `%TEMP%\opencode\bld_wfc_fix.bat`.
- `-fo=wfc-out.obj` → `0 warnings, 0 errors`, `wfc-out.obj` gerado (antes:
  4 `CO-05`). `-fo="wfc quoted.obj"` → gera com espaço no nome.
  `-fo=` antes do fonte + `-od` OK; `wfc.exe` (i86) com dash OK.
- `smells --file sdcline.c/option.c`: `total=0` nos dois.
- Regressão `build/test_examples.bat`: `PASS=4 FAIL=0`.
- `fix.md`: FIX-062 + limite `-fo=` marcado corrigido.

---

## FASE 37: CP-09 eliminado (causa raiz) ✅ (10/10/2026)

Padrão produção (`skill.md` regra 5): causa raiz no ciclo completo, sem
supressão — antes documentado como "cosmético", agora resolvido de verdade.

### 37.1 Diagnóstico (build TRMEM oficial: `wmake trmem=1`)

- `CP_MEMORY_NOT_FREED` vem de `UnFreeMem > 0` em `FMemErrors`
  (`bld/f77/wfc/c/fmemmgr.c:98`); reproduz até no `hello.for` mínimo.
- TRMEM (`_trmem_prt_list_ex`) listou **8 chunks / 43 bytes**: 4 objnames
  (`"*"`, `"_*`", `"^"`, `"_*#"` — os pragmas pré-definidos `__syscall`,
  `__cdecl`, `__pascal`, `__stdcall`) + 4 regsets de 8 bytes (`parm []`).
- Causa: `DoPragma` do `InitPragmaAux` grava nesses 4 **statics**
  (`Syscall/Stdcall/Pascal/CdeclInfo`, fora do `AuxList`); `FiniPragmaAux`
  só liberava `AuxList` + `FortranInfo`. O CP-09 do `wfl386` vinha do
  `wfc386` filho (`CompLink`), mesma origem.

### 37.2 Fix (`bld/f77/wfc/c/wf77aux.c`, +4 linhas + comentário)

`FiniPragmaAux` agora chama `FreeAuxElements` nos 4 statics (a função já
reseta os campos p/ `DefaultInfo`; processo está saindo, sem uso posterior).

### 37.3 Validação (ciclo completo, árvore restaurada)

- `wfc386` normal: saída `0 warnings, 0 errors` **sem** `*ERR* CP-09`;
  `-fo=` com dash (FASE 36) intacto; `wfl386` filho também limpo.
- TRMEM pós-fix: sem tabela `***`, `mem.trk` 0 bytes (**0 unfreed**).
- `smells --file wf77aux.c`: `total=0`.
- Sequência de builds: normal+`cprel` → TRMEM prova → normal+`cprel`
  final (`BUILD_RC=0`, `CPREL_WFC=0`; `clean` entre trocas de flag p/ não
  misturar objetos). Scripts: `%TEMP%\opencode\bld_wfc_cp09.bat`,
  `bld_wfc_trmem_full.bat`.
- Regressão `build/test_examples.bat`: `PASS=4 FAIL=0`.
- `fix.md`: FIX-063 + limite CP-09 marcado corrigido.

---

## FASE 38: Veredito `ctest diagnose` (equivalência upstream, sem tocar nada) ✅ (10/10/2026)

Ordem de compiladores, item 3. Réplica manual completa do `diagnose`
(29 fontes, flags da suíte `-we -wx -e1000 -eq -dARCH=386` + `opt_diag*`,
`INCLUDE=rel\h;rel\h\nt`, normalização `fixpath.sed`): com env correto, o
diff contra `exec.chk` tem **só os 2 deltas da FASE 29** (sem-INCLUDE gera
lixo extra em `diag0008/diag0022` — artefato do meu harness, não do compilador).

- **W115 ausente (6 sítios, `diag0012.c`)**: emissão desligada no fonte
  (`CheckAddrOfArray` em `#if 0` + call comentado, `bld/cc/c/cexpr.c:707-717,
  789`) — **idêntico no upstream master** (conferido via raw.githubusercontent;
  `exec.chk` upstream idêntico ao nosso, ainda esperando W115). Reabilitar
  seria divergir do upstream com warning ruidoso em código válido; editar
  `exec.chk` seria mascarar. Decisão produção: não tocar nenhum dos dois.
- **E1046 `inc3.h(60)` vs `(59)`**: `diag0015.c` upstream **byte-idêntico**
  (4037 bytes, LF, sem newline final); `exec.chk` upstream idêntico (59);
  scanner determinístico → upstream produz 60 também. Mexer no contador de
  linha do EOF teria blast radius em todos os diagnósticos por 1 linha de
  expectativa stale. Decisão produção: não tocar.
- Prova de não-regressão nossa: BW (GCC) vs REL byte-idênticos (FASE 29) +
  réplica atual com `wcc386` 2.0.1 dá os mesmos 2 deltas. Árvore limpa
  (nenhum `.err` deixado). `smells` n/a (nenhum fonte alterado).

---

## FASE 39: ctx Fase C (auditoria on-demand) ✅ (10/10/2026)

Sondagem com timeout (repo gigante, sem git): `verify` rápido, tudo ok
(`working_tree unknown exit 128` — sem git, esperado); `health` rápido,
**84/100 (B)**; `review --unstaged` **inutilizável** (erro 129, exige git);
`smells --security --lint` e scan/full **estouram 120s** (cppcheck em fonte
Watcom é lento; `status` idem).

Decisão produção: Fase C = `build/ctx_audit_full.bat` **on-demand**
(pré-release/nightly, fora da suite quente p/ não lentar `test_examples`):
`verify` + `health` + `audit/build list` em `build/tmp_audit/audit_full.log`
(ignorado via `/build/*/`), sempre `RC=0`, no-op sem ctx. Validado COM ctx
(`FULL_RC=0`, log com verify ok + health B) e SEM ctx (`RC=0`).
Exclusões documentadas acima com motivo (não é simplificar — é não ligar
comando que sempre falha/estoura).

---

## FASE 40: Versão 2.0.5 (bumps em dia + restamp) ✅ (10/10/2026)

Reclamação: `wlink` com banner antigo (`Version 2.0 beta`, sem patch).
Causa: binário pré-FASE-31 (sem `-D_BLDVER_PATCH`); mecanismo OK
(`_WLINK_VERSION_ = BAN_VER_STR`, `bld/watcom/h/banner.h:142`). Rebuilds
ad-hoc da sessão (wfl F32, wfc F36/F37) não chamaram `bumpver` → `version.bin`
parado em 1, banners mistos (wcc 2.0.1, wfc/wfl/wlink 2.0).

### 40.1 Execução (`%TEMP%\opencode\bld_ver205.bat`, 1 sessão p/ herdar env)

- 4× `bumpver.bat` → `version.bin` 1→5 (`OWBLDVER_PATCH=5` no env).
- Rebuild **limpo** (patch só entra em objeto recompilado, FASE 31.1):
  `wl` (`nt386` + `nt386.dll` + `nt386.rtd`), `wfc` (`386/nt386` +
  `386/nt386.rtd` + `i86/nt386`), `wfl` (`386/nt386` + `i86/nt386`) →
  `WL_RC=0`, `WFC_RC=0`, `WFL_RC=0` + 3× `cprel RC=0`.
- Prova: `wlink`, `wfc/wfc386`, `wfl/wfl386` em **2.0.5**; `wcc/wpp`
  ficam 2.0.1 até a próxima pipeline cheia (documentado, não é regressão).
- Regressão `PASS=4 FAIL=0` (suite usa o `wlink` novo 4×).
- Processo: rebuild ad-hoc de compilador/ferramenta passa a chamar
  `bumpver` (lembrete em `skill.md` + regra: sem pular números).
- `fix.md`: FIX-065; `skill.md`: seção versão + disciplina ctx-sempre.

---

## FASE 41: Item 4 FPU — toolchain correta, causa era link errado ✅ (10/10/2026)

Desmontagem do `.obj` default (`-fpi`): `fld; call IF@Dxxx; fstp` (x87).
Desmontagem do `_IF_dsqrt` de `math3r.lib`: prólogo lê `EDX:EAX`, epílogo
retorna em regs — **convenção `-fpc`, incompatível com chamador `-fpi`**
(o `fstp` do chamador recolhe o próprio input intacto: os 2.0).
`_RWD_real87=3` correto; `__sqrt87`/`__sqrtd` corretos isolados (1.414214).

Prova decisiva: o `.obj` default registra default-libs `emu387/math387r/
clib3r` (`dmpobj` COMENT) — o compilador JÁ direciona `-fpi` p/ `math387r`
(x87, asm). Link sem forçar math (`libpath` + só `kernel32/user32`) →
**1.414214/0.909297/-0.416147/7.389056/0.693147, sem `-fpc`**.
Prova cruzada: mesmo `.obj` com `math387r` explícita = correto; com
`math3r` forçada = 2.0. Tentativa E1121 prova `sqrt.c` nem compila `-fpi`
(pragma `__value[regs]` inválido) — `flags.mif` idêntico ao upstream.

Veredito produção (matriz suportada, zero código novo):
`-fpi` (default) + default-libs **e** `-fpc` + `math3r` — ambos corretos;
**nunca force `math3r` em objeto `-fpi`**. Teoria antiga ("inline FPU dá
NaN no WOW64", FASE 13.7) substituída: era mismatch de convenção no link
(receita FASE 13.6 forçava a lib errada). `math3r.lib` rebuildada
self-host + `rel/` sincronizada (higiene, sem mudança funcional);
shims asm avaliados e **dispensados** (quebrariam chamadores `-fpc`, que
usam os mesmos símbolos com regs — provado no `at2`); guarda `ifprag.h`
revertida (upstream-idêntica). Suite segue `PASS=4` (`[3/4]` usa o combo
`-fpc`+`math3r`, consistente).

---

## FASE 42: Instaladores rebuildados pós-FASE 36–41 ✅ (10/10/2026)

Pendência nº 5 do fechamento 10/10 (item "CONTINUAR DEPOIS" abaixo).
Regra da sessão (sem editar fontes; só `build/*.bat` oficiais + docs).

### 42.1 Execução

- Baseline pré-distro: `build/test_examples.bat` `PASS=4 FAIL=0` +
  `build/ctx_audit_full.bat` `RC=0` (verify ok, health 84/B).
- `build/distrib_build.bat` → `DISTRIB_RC=0`:
  `open-watcom-2_0-c-win-x86.exe` (18.713.909 bytes) +
  `open-watcom-2_0-f77-win-x86.exe` (14.534.857 bytes).
  Proveniência `ctx` automática pelo loop do script (2 instaladores) +
  `ctx_mem` + `ctx_checkpoint`.
- Pós-distro: `test_examples.bat` `PASS=4 FAIL=0` (zero regressão;
  distro não toca `rel/`, confirmado) + `ctx_audit_full.bat` `RC=0`
  re-rodado (diary: `BUILD-00044/45` = instaladores novos,
  `BUILD-00046–49` = regressão pós-distro).

### 42.2 Conteúdo embarcado (o que muda vs instaladores de 09/10)

Instaladores anteriores (FASE 34) eram pré-FASE 36–41; os novos embarcam
o `rel/` atual: `wlink/wfc386/wfl386` **2.0.5** (FIX-062/063/065),
`math3r.lib` self-host (FIX-066), `wlink.lnk` curado (FIX-011/31.2).
`wcc386` segue 2.0.1 e o driver `wpp386` segue 2.0 (pré-`bumpver`, layout
driver+DLL da FASE 28 — a versão real está na `wppd386.dll`;
unificam na próxima pipeline cheia com `clean`, FASE 40).

### 42.3 Logo (decisão)

`OpenWatcom.png` (raiz, 1,1MB, com transparência) **não** entra no
instalador neste release (decisão do mantenedor). Motivo técnico: o
splash do setup é `bld/setupgui/res/wcc.bmp`/`f77.bmp` — BMP **515×214
8bpp paletado** (header `42 4D`, `0302`×`00D6`, `08bpp`) — e os ícones
são `setup.ico`/`disk.ico` de ~1KB; o PNG não entra direto, exigiria
conversão de identidade + rebuild do `setupgui` + nova redistrib.
Logo segue no README/GitHub (`OpenWatcom.png` referenciado no topo do
`README.md`).

---

## FASE 43: Item 6 — veredito float03/i6403/opt03/setjmp03 ✅ (10/10/2026)

Pendência nº 6 do fechamento 10/10 (`positive` FAILs da FASE 29).
Regra da sessão (sem editar fontes; builds via `.bat` em `%TEMP%\opencode\`;
scripts: `t_float03.bat`, `t_float03b.bat`, `t_float03c.bat`, `run_pos0.bat`).

### 43.1 float03 — expectativa insatisfatível em binary64 (não é codegen)

Referência independente (gcc, `ref.c` em `%TEMP%`): os dois literais de
31 dígitos convertem para o **mesmo** double
(`0x1.c71c71c71c71cp-4`; `eq=1 ne=0 lt=0 le=1 gt=0 ge=1`). O correto em
IEEE-754 é `==`→1 / `!=`→0 — exatamente o que o compilador produz
(`index:8 1.0`, `index:9 0.0`); o teste exige `==`→0 / `!=`→1, impossível
quando os operandos são o mesmo double. O gêmeo C (`ctest`, 16 dígitos,
doubles distintos) passa (`RC=0`). Invariante a `-ox`/`-fpc`/`-zfp`/`-ms`
(matriz [1]–[5] idêntica) — não é inline FPU nem convenção (FASE 41).

### 43.2 Irmaos (classificação, mesma matriz REL vs BW)

- **i6403** (linhas 81/84/119/122/125): escada de tipos de literal
  decimal (`__int64` na escada → `+5` vs `+4` esperado; `ULL` vs `UI64`) —
  diferença de conformidade/extensão (mesma família do MSVC), não codegen.
- **opt03**: idioma `&*p`/`this==0` com ponteiro nulo dobrado pelo `-ox`
  (família `-fdelete-null-pointer-checks` do GCC/Clang) → abort.
- **setjmp03** (linhas 38/51/59): contagem de dtors via `longjmp` difere
  só no link `-br` (DLL runtime) da suite; com link estático passa (`RC=0`
  nos dois compiladores). Detalhe apurado: suite test0 usa `-br` em NT386
  (`targ_env_386=wnt386` → `targ_br_wnt386=-br`, `testenv1.mif:1119/1130`).

### 43.3 Prova de não-regressão (harness real, 2 runs completos)

`run_pos0.bat` (receita FASE 29/34: `wmake test0=1 test`,
`PLUSTEST_WPP_386` + `linker=` absolutos): suite `positive/test0`
re-rodada com `wpp386` REL e `bwpp386` BW — veredito FAIL nos dois
(os 4 FAILs conhecidos entre ~675 PASS) e `fc /b` nos 4 `.outs`
**sem nenhuma diferença**. Nenhum fonte tocado (só docs desta FASE).

**Veredito produção** (precedente FASE 38): pré-existente, zero regressão
nossa — não tocar compilador nem expectativa.

---

## FASE 44: Unificação `wcc`/`wpp` em 2.0.6 ✅ (10/10/2026)

Escopo aprovado: alvo `cc`/`plusplus` + redistrib (sem pipeline cheia).
Regra da sessão (`bumpver` 1×, rebuild limpo, `Read`/`Edit` só em docs;
script: `%TEMP%\opencode\bld_ver206.bat`, padrão FASE 40).

### 44.1 Execução

- 1× `bumpver.bat` → `version.bin` 5→6 (`OWBLDVER_PATCH=6`).
- `wmake -f makefile clean` (6 dirs, todos `RC=0`): `cc` e `plusplus` ×
  `386/nt386.dll`, `386/nt386.rtd`, `i86/nt386.dll` (é de onde saem os
  drivers — não existe `nt386` puro nesses projetos).
- `builder build os_nt cpu_386 target_386` + `target_i86` nos 2 projetos
  (`CC386/CCI86/PP386/PPI86_RC=0`; `.rtd` veio de quebra, padrão FASE 28)
  + `cprel` (`CPREL_CC/CPREL_PP=0`).
- Banners: `wcc386/wpp386/wcc/wpp` em **2.0.6** (timestamps de hoje);
  DLLs `wccd386/wppd386/wccd/wppdi86` rebuildadas junto.
  `wlink/wfc/wfl` seguem 2.0.5 até a próxima pipeline cheia.
- `test_examples.bat` `PASS=4 FAIL=0` (**com os compiladores novos**),
  `ctx_audit_full.bat` `RC=0`, `distrib_build.bat` `DISTRIB_RC=0`
  (`c` 18.713.902 + `f77` 14.534.857 bytes) + regressão pós-distro `PASS=4`.

---

## FASE 45: CI CodeQL/Linux — guarda `__GNUC__` restrita a NT ✅ (26/10/2026)

### 45.1 Diagnóstico

Run #3 do workflow `CodeQL Advanced Static Analysis` (`Build DB`) falhou em
~5s no commit `7469e29`. O `ci/codeql.sh` chama `build.sh boot`; o `posmake`
compila `bld/watcom/c/clibext.c` com `-D__UNIX__` e GCC. A guarda local
`#if defined( _MSC_VER ) || defined( __GNUC__ )` incluía `<windows.h>` no
Linux → `fatal error: windows.h: No such file or directory`; `make` retornava
2 e o CodeQL reportava apenas `Process completed with exit code 2`.

O upstream usa somente `_MSC_VER`; a ampliação para `__GNUC__` foi feita para
MinGW/NT, mas também casava com GCC em POSIX. O mesmo padrão existia em
`clibext.c:736/775/1047` e `clibext.h:140/193/241`.

### 45.2 Correção

Guards restritos ao GCC em NT:

```c
#if defined( _MSC_VER ) || ( defined( __GNUC__ ) && defined( __NT__ ) )
```

`ci/codeql.sh` passou a imprimir `build/$OWOBJDIR/bootx.log` quando o build
falha, para o erro real aparecer no log do step.

### 45.3 Validação

- Ubuntu 24.04/GCC 13: antes falhava em `windows.h`; depois o `wmake` compila
  e o `builder boot` avança (chegou a compilar `wres`).
- MinGW/Strawberry GCC com `-D__NT__`: `clibext.c` compila `RC=0` (caminho
  Windows preservado).
- `clibext.h` mantém `#if !defined( __GNUC__ )` para `ssize_t`/`mode_t`
  (MinGW já fornece; MSVC precisa dos typedefs).

---

## CONTINUAR DEPOIS — estado e pendências (fechamento 10/10/2026)

### Estado final do dia (tudo verde)

- `rel/binnt`: 81 `.exe` 0 zerados · `rel/lib386/nt/*.lib` 0 zerados ·
  `.dll` só docs pendentes (sem HHC).
- `build/version.bin` = `6` → `wcc/wpp` (32+16-bit) em 2.0.6 (FASE 44);
  `wlink/wfc/wfl` em 2.0.5 até a próxima pipeline cheia (FASE 40).
- `build/test_examples.bat` = `PASS=4 FAIL=0` (C, C++, math `-fpc`,
  Fortran via `wfl386`); raiz limpa após os runs.
- FASE 42–44 (FIX-067/068/069): instaladores rebuildados
  pós-FASE 36–41 (FASE 42) + veredito item 6 sem código novo (FASE 43:
  float03/i6403/opt03/setjmp03 pré-existentes, REL vs BW byte-idênticos) +
  unificação `wcc`/`wpp` em 2.0.6 com redistrib (FASE 44).
- Sessão 10/10 (FASE 35–41): ctx A+B (`ctx_mem/checkpoint/smells`,
  FIX-061) + Fase C on-demand (`ctx_audit_full.bat`, verify ok, health
  84/B, FIX-064) + `wfc -fo=` com `-`/aspas (FIX-062) + CP-09 eliminado
  causa raiz via TRMEM (FIX-063) + veredito `ctest diagnose` upstream-
  idêntico sem tocar nada (FASE 38) + item 4 FPU fechado sem código novo
  (matriz `-fpi`+default-libs e `-fpc`+`math3r`, FIX-066).
- `skill.md` atualizado: robustez produção/nunca simplificar,
  controle de versão na pipeline, disciplina ctx-sempre (opcional por
  desenho). `README.md`: matriz math + `-fo=` corrigidos.
- Regressão oficial: `ctest` 4/5, `plustest` 23 PASS + pêndulos FASE 34
  (deltas pré-existentes FASE 29/38, zero regressão nossa).
- Diary `.ctx/` com proveniência + memórias + `audit_full.log` em
  `build/tmp_audit/`; `ctx` opcional (`FIX-060/061/064`) — sem ele tudo
  builda igual (`PASS=4 FAIL=0` validado nos dois modos).
- Instaladores `distrib/ow/bin/`: rebuildados na FASE 44 (c 18.713.902 +
  f77 14.534.857 bytes, `DISTRIB_RC=0`) — embarcam `wcc`/`wpp` 2.0.6 +
  `wfc`/`wfl`/`wlink` 2.0.5 + `math3r` self-host. Pendência 5 ✅ concluída
  (primeiro build FASE 42, atualizado FASE 44).

### Pendências (por prioridade)

1. Bump de versão: `bumpver.bat` chamado pelos 5 `.bat` **+ em todo
   rebuild ad-hoc** (regra nova, `skill.md`); patch só aparece em objetos
   RECOMPILADOS (forçar `clean` se preciso); sem pular números.
2. Docs `.hlp/.chm` (exigem HHC) — fora de escopo local.
3. ~~`wfc386 -fo=` com `-`/aspas~~ ✅ corrigido (FIX-062, FASE 36).
4. ~~CP-09~~ ✅ corrigido (FIX-063, FASE 37).
5. ~~Rebuildar instaladores (`distrib_build.bat` + `ctx` proveniência) p/
   embarcar `wfc/wfl/wlink` 2.0.5 + `math3r` self-host~~ ✅ concluído
   (FASE 42: `DISTRIB_RC=0`, regressão `PASS=4` pré+pós, diary
   `BUILD-00044/45` + `00046–49`).
6. ~~Próxima investigação (ordem): `ctest float03`/precision (`-ox`, FASE 29,
   pré-existente) — só após o item 5.~~ ✅ concluído (FASE 43: os 4 FAILs
   do `positive` são pré-existentes — float03 com expectativa insatisfatível
   em binary64, i6403 de escada `__int64`, opt03 de null-check dobrado,
   setjmp03 só no link `-br`; REL vs BW byte-idênticos, não tocar).
7. Logo no instalador: fora deste release (decisão, FASE 42.3) — splash
   exige conversão p/ BMP 515×214 8bpp + rebuild do `setupgui`.
8. Unificar `wlink`/`wfc`/`wfl` (2.0.5) com `wcc`/`wpp` (2.0.6): próxima
   pipeline cheia (`clean` + `bumpver` 1× → 2.0.7) + redistrib (FASE 44).

### Como retomar

- Env padrão dos `.bat`: `OWROOT=<repo>`, `OWTOOLS=WATCOM`,
  `BOOTSTRAP_CPU=386`, `BOOTSTRAP_OS=nt`, `OWNEWWGML=1`,
  `PATH=%OWROOT%/build;%OWROOT%/build/binbuild;%OWROOT%/rel/binnt`,
  `WLINK_LNK=%OWROOT%/build/bwlink.lnk`.
- Validar: `build\test_examples.bat` (esperado `PASS=4 FAIL=0`).
- Auditoria: `build\ctx_audit_full.bat` (esperado `RC=0`,
  `build/tmp_audit/audit_full.log` com verify ok + health B).
- Pêndulos: `%TEMP%\opencode\run_pendulum*.bat` + `run_cool*.bat`
  (overrides `linker=` + `wlib_any=` absolutos, `CTEST_WCC_386` p/ C,
   subdirs p/ `cool`/`stl.94`) — recriar se limpar o Temp (scripts que
   ficam: `bld_ver205.bat`, `bld_ver206.bat`, `bld_wfc_*`, `bld_math3r.bat`,
   `t_fpu_*.bat`, `t_float03*.bat`, `run_pos0.bat`, `run_diag.ps1` — todos
   em `%TEMP%\opencode\`).
- Regras permanentes: melhoria nova → registrar em `fix.md`; `ctx`
  opcional por desenho, sempre usado por disciplina; `bumpver` 1× por
  rebuild de compilador/ferramenta; nada de teste/exemplo na raiz;
  robustez produção, nunca simplificar (`skill.md`).
