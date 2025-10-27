
Collection of reusable QML components for QuickShell. This repository currently contains a live GLSL shader compiler / watcher that can be embedded into QuickShell UIs to edit and reload shaders at runtime.

## Contents

- `LiveShaderCompiler/`
	- `LiveShaderCompiler.qml` — Main component that compiles and exposes shader programs.
	- `LiveShaderWatcher.qml` — Watches shader files on disk and triggers reloads.
	- `LiveShaderSignaler.qml` — Simple signal bridge used to notify the host application.
	- `shader/` — Example shader sources and compiled qsb bundles:
		- `_live_shader.vert`, `_live_shader.frag` — GLSL sources used by the example.
		- `*.qsb` — Precompiled shader bundle artifacts (used by the component when available).

## Overview

The LiveShaderCompiler component makes it easy to work with vertex/fragment GLSL shaders inside a Quickshell-based shell. It provides:

- Live reloading of shader sources when files change on disk.
- A minimal signaler, for error reporting back into QML so you can display compile errors.
- File watcher separation so you can customize how files are discovered.

This is intended for development and live-edit workflows (hot-reloading shaders while iterating on visuals). It is not hardened for production distribution without additional sandboxing and validation.

## Quick start

Minimal example: place the `LiveShaderCompiler` folder on your QML import path and then
use the component from QML.

Example usage (in your QML file):

```qml
import QtQuick
import "./LiveShaderCompiler" // relative path to the component folder

// Example item here, use whatever
Item {
    visible: true
    width: 800
    height: 600

    ShaderEffect {
        id: liveShader
        anchors.fill: parent

        LiveShaderCompiler {
            id: liveShaderCompiler
            targetShaderEffect: liveShader
            // OPTIONALS
            shaderName: "_live_shader"
            qsbArgs: "--qt6" // doesn't support multiple args yet
            qsbDir: "/usr/lib/qt6/bin/qsb" // default, if you don't have qsb installed manually
        }
    }
    // OPTIONAL!
    // This can be wherever you want,
    // It connects to shader compiler signals and creates compilation related logs for you.
    // It can also be used to track compiler states.
    // Useful if you want to create your own shadertoy.
    LiveShaderConnector {
        id: liveShaderConnector
        compiler: liveShaderCompiler
    }
}
```

Notes:
- The component exposes signals `compiled` and `compileError` (or similarly named in
	the QML source) — check the component file for the exact property/signal names. Use
	them to surface errors to the UI or console.
- When `LiveShaderWatcher` detects a change in a shader source it will ask the
	`LiveShaderCompiler` to recompile and emit events you can react to.

## Usage
1. Edit GLSL files under `LiveShaderCompiler/shader/` and save — the watcher should pick up changes and trigger recompilation. Obviously, the shader compiler component **MUST** be loaded in your shell while you are editing the shaders.

## Files and responsibilities

- `LiveShaderCompiler.qml`: Compile vertex/fragment sources into a usable shader program
	for the QML scene. Handles compile requests and exposes the compiled program or
	error messages.
- `LiveShaderWatcher.qml`: Monitors a configured list of files and emits change events.
- `LiveShaderSignaler.qml`: Tiny utility to forward signals between objects.
- `shader/`: Example shaders and compiled bundles used by the demo. This is the default path.

## Troubleshooting

- If shaders fail to compile, check the application output — the component forwards
	compiler log messages. Ensure your GLSL version and uniforms match the renderer.
- File watching may behave differently across platforms. If you don't see reloads,
	verify the watcher path and permissions.
- Feel free to open an issue if you have any questions or problems.

## Contributing

Contributions are welcome. If you add features, try to include small focused commits,
tests (or a manual reproduction procedure) and update this README with any new public
API surface.

## License

This repository follows the project-wide license, **MIT**.
