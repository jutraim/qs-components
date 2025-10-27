import QtQuick

Item {
    id: root

    required property var compiler

    // === STATE ===
    property string compileState: "idle" // idle | compiling | success | error
    property string message: "Idle"
    property double lastCompileTime: 0
    property double compileStartTime: 0
    property double duration: 0
    property bool liveReload: compiler.liveReload
    property int compileType: compiler.compileType
    property int fragErrorLine: -1
    property int vertexErrorLine: -1
    property string fragErrorString: ""
    property string vertexErrorString: ""

    property bool logVisible: false

    // === LOGGING DATA ===
    property int maxLogs: 50 // Keep log config here

    property alias logModel: logModel

    ListModel {
        id: logModel
    }

    // === ACTIONS / MUTATIONS ===
    function pushLog(type, msg) {
        var file = "", line = -1;
        var m = msg.match(/([^\s:]+):(\d+):\s*(?:error|warning)?:?\s*(.*)/) || msg.match(/ERROR:\s*(?:\d+:)?(\d+):\s*(.*)/);

        if (m) {
            file = m[1];
            line = parseInt(m[2] || m[1]);
        }

        logModel.append({
            time: new Date().toLocaleTimeString(),
            type: type,
            msg: msg,
            file: file,
            line: line
        });
        if (logModel.count > root.maxLogs)
            logModel.remove(0);
    }

    // === SIGNAL CONNECTIONS (Updates the internal state) ===
    Connections {
        target: root.compiler

        function onCompileStarted(msg, type) {
            root.compileStartTime = Date.now();
            root.compileState = "compiling";
            root.message = msg;
            root.pushLog("info", msg);
        }

        function onCompiledSuccessfully(msg) {
            root.duration = (Date.now() - root.compileStartTime) / 1000;
            root.lastCompileTime = Date.now();
            root.compileState = "success";
            root.message = msg;
            root.pushLog("success", msg);

            // Clear error line
            root.fragErrorLine = -1;
            root.vertexErrorLine = -1;
        }

        function onCompileFailed(msg) {
            root.duration = (Date.now() - root.compileStartTime) / 1000;
            root.compileState = "error";
            root.message = msg;
        }

        function onCompileError(line, msg) {
            root.compileState = "error";
            if (root.compileType === 0) {
                root.fragErrorLine = Number(line);
                root.fragErrorString = msg;
            } else if (root.compileType === 1) {
                root.vertexErrorLine = Number(line);
                root.vertexErrorString = msg;
            }
        }

        // Log messages
        function onErrLog(line) {
            root.pushLog("stderr", line);
        }
        function onOutLog(line) {
            root.pushLog("stdout", line);
        }
        function onReloading(type) {
            root.pushLog("reload", `Reloading ${type === root.compiler.FRAGMENT ? "fragment" : "vertex"} shader`);
        }
        function onLoaded(type) {
            root.pushLog("load", `Shader loaded (${type === root.compiler.FRAGMENT ? "fragment" : "vertex"})`);
        }
    }
}
