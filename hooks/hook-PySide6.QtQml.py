from PyInstaller.utils.hooks.qt import add_qt6_dependencies, pyside6_library_info


hiddenimports, binaries, datas = add_qt6_dependencies(__file__)

qml_binaries, qml_datas = pyside6_library_info.collect_qtqml_files()

_ALLOWED_QML_MODULES = {
    "QtQuick",
    "QtQuick.Controls",
    "QtQuick.Dialogs",
    "QtQuick.Effects",
    "QtQuick.Layouts",
}


def _is_allowed_qml_path(path: str) -> bool:
    normalized = path.replace("\\", "/")

    marker = "/qml/"
    if marker not in normalized:
        return False

    relative = normalized.split(marker, 1)[1]
    module = relative.split("/", 1)[0]

    return module in _ALLOWED_QML_MODULES


binaries += [
    item
    for item in qml_binaries
    if _is_allowed_qml_path(item[0])
]

datas += [
    item
    for item in qml_datas
    if _is_allowed_qml_path(item[0])
]
