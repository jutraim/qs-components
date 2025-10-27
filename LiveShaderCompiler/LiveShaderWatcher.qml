import Quickshell.Io
import QtQuick

Item {
    id: root
    required property var liveShaderCompiler

    property alias fragFile: fragFile
    property alias vertFile: vertFile
    property alias fragQsbFile: fragQsbFile
    property alias vertQsbFile: vertQsbFile

    // === FILEVIEW SIGNALS ===
    signal fileSaveFailed(string path, string error)
    signal fileLoadFailed(string path, string error)
    signal fileChanged(string path)
    signal fileSaved(string path)

    FileView {
        id: fragFile
        path: root.liveShaderCompiler.fragPath
        watchChanges: true
        printErrors: true

        onFileChanged: root.liveShaderCompiler.compileShader(LiveShaderCompiler.FRAGMENT)
        onSaveFailed: error => root.liveShaderCompiler.fileSaveFailed(".frag save failed:" + error)
        onLoadFailed: error => root.liveShaderCompiler.fileLoadFailed(".frag load failed:" + error)
    }

    FileView {
        id: vertFile
        path: root.liveShaderCompiler.vertPath
        watchChanges: true
        printErrors: true

        onFileChanged: root.liveShaderCompiler.compileShader(LiveShaderCompiler.VERTEX)
        onSaveFailed: error => root.liveShaderCompiler.fileSaveFailed(".vert save failed:" + error)
        onLoadFailed: error => root.liveShaderCompiler.fileLoadFailed(".vert load failed:" + error)
    }

    // === QSB FILE VIEWS ===
    FileView {
        id: fragQsbFile
        path: root.liveShaderCompiler.fragPath + ".qsb"
        watchChanges: true
        printErrors: true

        onLoaded: root.liveShaderCompiler.reloadShader(LiveShaderCompiler.FRAGMENT)
        onFileChanged: root.liveShaderCompiler.reloadShader(LiveShaderCompiler.FRAGMENT)
        onLoadFailed: error => root.liveShaderCompiler.fileLoadFailed(".vert.qsb load failed:" + error)
    }

    FileView {
        id: vertQsbFile
        path: root.liveShaderCompiler.vertPath + ".qsb"
        watchChanges: true
        printErrors: true

        onLoaded: root.liveShaderCompiler.reloadShader(LiveShaderCompiler.VERTEX)
        onFileChanged: root.liveShaderCompiler.reloadShader(LiveShaderCompiler.VERTEX)
        onLoadFailed: error => root.liveShaderCompiler.fileLoadFailed(".vert.qsb load failed:" + error)
    }
}
