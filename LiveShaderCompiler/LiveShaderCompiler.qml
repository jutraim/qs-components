import Quickshell.Io
import QtQuick

Item {
    id: root
    required property var targetShaderEffect

    // === OPTIONS ===
    property bool verbose: true
    property bool liveReload: true
    property int compileType: LiveShaderCompiler.BOTH

    enum CompileType {
        FRAGMENT,
        VERTEX,
        BOTH
    }

    // === CONFIG ===
    property string shaderName: "_live_shader"
    readonly property url shaderDir: Qt.resolvedUrl("shader")
    readonly property url fragPath: Qt.resolvedUrl(shaderDir + "/" + shaderName + ".frag")
    readonly property url vertPath: Qt.resolvedUrl(shaderDir + "/" + shaderName + ".vert")
    property string qsbArgs: "--qt6"
    readonly property string qsbArgSeparated: qsbArgs.split(" ").join(" ")
    property string qsbDir: "/usr/lib/qt6/bin/qsb"

    // === SHADER EFFECT SIGNALS ===
    signal shaderLoading(string type)
    signal shaderReloading(string type)
    signal shaderLoaded(string type)

    function cacheBusterPath(fileView) {
        const cacheBuster = `?v=${Date.now()}`;
        return fileView.path + cacheBuster;
    }

    // === RELOAD FUNCTION ===
    function reloadShader(type) {
        if (liveReload === false) {
            return;
        }
        if (type === LiveShaderCompiler.FRAGMENT && !targetShaderEffect.fragmentShader) {
            shaderLoading(type);
        } else if (type === LiveShaderCompiler.VERTEX && !targetShaderEffect.vertexShader) {
            shaderLoading(type);
        } else {
            shaderReloading(type);
        }

        switch (type) {
        case LiveShaderCompiler.FRAGMENT:
            targetShaderEffect.fragmentShader = cacheBusterPath(fragQsbFile);
            break;
        case LiveShaderCompiler.VERTEX:
            targetShaderEffect.vertexShader = cacheBusterPath(vertQsbFile);
            break;
        case LiveShaderCompiler.BOTH:
            targetShaderEffect.fragmentShader = cacheBusterPath(fragQsbFile);
            targetShaderEffect.vertexShader = cacheBusterPath(vertQsbFile);
            break;
        }
        shaderLoaded(type);
    }

    // === FILE VIEWS ===
    property alias fragFile: liveShaderWatcher.fragFile
    property alias vertFile: liveShaderWatcher.vertFile
    property alias fragQsbFile: liveShaderWatcher.fragQsbFile
    property alias vertQsbFile: liveShaderWatcher.vertQsbFile

    LiveShaderWatcher {
        id: liveShaderWatcher
        liveShaderCompiler: root
    }

    // === PROCESS SIGNALS ===
    signal compileFailed(string message)
    signal compiledSuccessfully(string message)
    signal compileStarted(string message, string type)
    signal compileFinished(string message)
    signal compileError(string line, string message)
    signal errLog(string line)
    signal outLog(string line)

    // === COMPILE FUNCTION ===

    // debounce / queue support for compilations
    property int pendingCompileType: -1
    property int compileQueued: -1
    Timer {
        id: compileDebounceTimer
        interval: 250 // ms
        repeat: false
        onTriggered: {
            if (root.pendingCompileType !== -1) {
                root._compileShader(root.pendingCompileType);
                root.pendingCompileType = -1;
            }
        }
    }

    function compileShader(type) {
        if (liveReload === false) {
            if (verbose)
                root.outLog("Live reload is disabled; compile request ignored.");
            return;
        }
        pendingCompileType = type;
        compileQueued = -1; // clear any queued type
        compileDebounceTimer.restart();
    }

    function _compileShader(type) {
        compileType = type;
        if (!targetShaderEffect) {
            root.compileFailed("Cannot compile, targetShaderEffect is not set.");
            return;
        }

        // If a compile is already running, queue this one and return
        if (compileProcess.running) {
            root.compileQueued = type;
            if (verbose)
                root.outLog("Compile requested while busy — queued.");
            return;
        }

        compileProcess.running = true;
    }

    // === COMPILE PROCESS ===
    Process {
        id: compileProcess
        running: false

        command: {
            const fragCommand = [root.qsbDir, root.shaderName + ".frag", "-o", root.shaderName + ".frag.qsb", root.qsbArgSeparated];
            const vertCommand = [root.qsbDir, root.shaderName + ".vert", "-o", root.shaderName + ".vert.qsb", root.qsbArgSeparated];
            switch (root.compileType) {
            case LiveShaderCompiler.FRAGMENT:
                return fragCommand;
            case LiveShaderCompiler.VERTEX:
                return vertCommand;
            default:
                return fragCommand;
            }
        }

        workingDirectory: root.shaderDir.toString().replace("file://", "")

        onRunningChanged: {
            if (running) {
                root.compileStarted(`Compiling ${root.compileType === 0 ? "Fragment" : "Vertex"} shader...`, root.compileType);
            } else {
                root.compileFinished("Shader compilation process finished.");
            }
        }

        onExited: (exitCode, exitStatus) => { // The lint warning is bullshit
            if (exitCode === 0) {
                root.compiledSuccessfully("Shader compiled successfully");
            } else {
                root.compileFailed("Shader compilation failed");
            }

            // If a compile was queued while we were running, schedule it via debounce timer
            if (root.compileQueued !== -1) {
                root.pendingCompileType = root.compileQueued;
                root.compileQueued = -1;
                compileDebounceTimer.restart();
                if (root.verbose)
                    root.outLog("Queued compile scheduled after exit.");
            }
        }

        stdout: StdioCollector {
            onStreamFinished: if (text)
                root.outLog(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.errLog(text);
                    const match = text.match(/(?:ERROR|WARNING):\s*[^:]*:?(\d+):\s*(.*)/);
                    if (match) {
                        const isError = text.includes("ERROR:");

                        if (isError) {
                            root.compileError(match[1], match[2]);
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: reloadShader(LiveShaderCompiler.BOTH)
}
