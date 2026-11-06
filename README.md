# Qumir service

The web service behind the [qumir.dev](https://qumir.dev) playground: the HTTP
server, the browser UI (editor, debugger, robot, turtle, painter and drawer
executors), the user documentation in Russian and the example programs.

The compiler lives in [QumirLabs/qumir](https://github.com/QumirLabs/qumir).
The service does not link it. It runs `qumirc` as a subprocess from
`--binary-dir` and serves the JavaScript runtime that the qumir package
installs into `share/qumir/js` under `/runtime/`.

History before qumir commit
[ff0f797c](https://github.com/QumirLabs/qumir/commit/ff0f797c2363c07ba53d710006ee3cdc862aa211)
lives in [QumirLabs/qumir](https://github.com/QumirLabs/qumir): this
repository started from a copy of its service at that commit.

## Layout

- `service/server.cpp`: the HTTP server (coroio and LLVMSupport for `llvm::json`).
- `service/plugin.h`: the plugin API; plugins resolve coroio and `llvm::json`
  symbols from the server executable.
- `service/static/`: the playground UI; `service/static/docs` links to `docs/ru`.
- `service/build-docs.js`: renders `docs/ru` to static HTML.
- `docs/ru/`: user documentation; the screenshots are stored in Git LFS.
- `examples/`: example programs listed by `/api/examples`.
- `test/test_browser_debugger.mjs`: browser test of the playground and the debugger.
- `externals/coroio`: the coroio submodule.

## Build

Requirements: CMake 3.30 or newer, a C++23 compiler (g++-14 or clang), LLVM 20
or newer, Ninja, Git LFS for the documentation screenshots.

```bash
git lfs install
git clone --recursive https://github.com/QumirLabs/qumir-service.git
cd qumir-service
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DLLVM_DIR="$(llvm-config-20 --cmakedir)"
cmake --build build
```

The server is `build/service/server`. On macOS with Homebrew use
`-DLLVM_DIR=/opt/homebrew/opt/llvm@20/lib/cmake/llvm`.

## Run for development

Build qumir next to this repository (see its README), then point the server at
its `qumirc` and its JavaScript runtime. The playground compiles to
WebAssembly, so `qumirc` needs `wasm-ld` (lld) in `PATH`.

```bash
QUMIR=../qumir
build/service/server --port 8080 --static-dir service/static \
    --binary-dir $QUMIR/build/bin \
    --qumir-runtime $QUMIR/qumir/runtime/js \
    --qumir-docs $QUMIR/docs/arch \
    --examples-dir examples --shared-links-dir /tmp/qumir-shared
```

- `--binary-dir`: the directory with `qumirc`; `/usr/bin` with the qumir package.
- `--qumir-runtime`: the JavaScript runtime served under `/runtime/`; it must
  contain `loader.js`. The default is `<prefix>/share/qumir/js`.
- `--qumir-docs`: development only, serves the architecture notes (markdown) of
  qumir under `/docs/arch/`. In production the static pages are built by
  qumir_private from the qumir package.

Browser test (puppeteer):

```bash
npm install
QUMIR_BIN_DIR=$QUMIR/build/bin QUMIR_RUNTIME_DIR=$QUMIR/qumir/runtime/js \
    node test/test_browser_debugger.mjs
```

Without the variables the test uses the qumir package: `/usr/bin` and
`/usr/share/qumir/js`. `node docs/capture-screenshots.mjs` retakes the
documentation screenshots against a running server.

## Package

On Linux `cpack -G DEB` in the build directory makes
`qumir-service_1.1.0-<N>_<arch>.deb`. Configure with
`-DCMAKE_INSTALL_PREFIX=/usr -DQUMIR_SERVICE_BUILD_NUMBER=<N>`; the build
number becomes the Debian revision and goes into `/api/version` with the
commit. The package depends on `qumir (>= 1.1.0)` and installs:

- `/usr/bin/qumir-service`;
- `/usr/share/qumir-service/static` (the UI and `docs/ru`) and
  `/usr/share/qumir-service/examples`;
- the systemd unit `qumir-service.service`, which runs as the `qumir` user
  (created by `postinst`) and keeps shared links in
  `QUMIR_DATA_DIR/shared` (default `/var/lib/qumir-data`, created by `postinst`
  and owned by `qumir`).

## Checks

```bash
python3 tools/check_text.py
python3 tools/check_commits.py origin/main..HEAD
```

`check_text.py` allows only ASCII, Russian letters and № in C/C++ and `.kum`
comments and forbids invisible characters everywhere; `check_commits.py`
applies the same rule to commit messages and rejects bot authors and
co-authors.
