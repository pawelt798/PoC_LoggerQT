// Main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 1100
    height: 850
    visible: true
    title: "Wielokrotne użycie InfoWidget"
    color: "#1d1d1d"

    property bool isRecording: false

    // --- FUNKCJA DYNAMICZNEGO DODAWANIA MAKR ---
    function addMacroButton(label, callback) {
        var component = Qt.createComponent("CustomButton.qml")
        if (component.status === Component.Ready) {
            var btn = component.createObject(macroFlow, {
                "text": label,
                "iconText": "⚡"
            })
            if (btn && callback) {
                btn.clicked.connect(callback)
            }
        }
    }

    // --- MODELE DANYCH ---
    ListModel {
        id: rawLogModel
        ListElement { time: "2025-04-26 14:32:17.102"; tag: "UART"; tagColor: "#0088cc"; dir: "RX"; payload: "0x48 0x65 0x6C 0x6C 0x6F (\"Hello\")" }
        ListElement { time: "2025-04-26 14:32:17.215"; tag: "CAN";  tagColor: "#d35400"; dir: "RX"; payload: "ID: 0x123 DLC: 8 Data: 11 22 33 44 55 66 77 88" }
        ListElement { time: "2025-04-26 14:32:17.317"; tag: "RAW";  tagColor: "#27ae60"; dir: "RX"; payload: "192.168.1.10:54321 -> 192.168.1.20:5000 64 bytes" }
        ListElement { time: "2025-04-26 14:32:17.422"; tag: "CAN";  tagColor: "#d35400"; dir: "TX"; payload: "ID: 0x7F DLC: 2 Data: AA 55" }
        ListElement { time: "2025-04-26 14:32:17.528"; tag: "UART"; tagColor: "#0088cc"; dir: "TX"; payload: "0x01 0x03 0x00 0x0A 0xC5 0xCD" }
    }

    ListModel {
        id: filteredLogModel
        ListElement { time: "2025-04-26 14:32:17.215"; tag: "CAN";  tagColor: "#d35400"; dir: "RX"; payload: "ID: 0x123 DLC: 8 Data: 11 22 33 44 55 66 77 88" }
        ListElement { time: "2025-04-26 14:32:17.528"; tag: "UART"; tagColor: "#0088cc"; dir: "TX"; payload: "0x01 0x03 0x00 0x0A 0xC5 0xCD" }
    }

    ListModel {
        id: regexModel
        ListElement { active: true;  pattern: ".*(ERROR|FAIL|ERR).*"; tagColor: "#e74c3c" }
        ListElement { active: true;  pattern: "^.*(AT\\+|CMD:).*";    tagColor: "#00a8ff" }
        ListElement { active: true;  pattern: "^.*(OK|Ready).*";     tagColor: "#00a8ff" }
        ListElement { active: true;  pattern: "connection|connected";  tagColor: "#2ecc71" }
        ListElement { active: false; pattern: ".*(WARN|WARNING).*";   tagColor: "#9b59b6" }
    }

    // --- LEWA STRONA: Przyciski Akcji ---
    Row {
        id: leftButtons
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 5
        anchors.leftMargin: 5
        spacing: 5

        ActionDropdownButton {
            text: "Start Logging"
            onMainClicked: console.log("Główna akcja: Rozpoczęto logowanie")
            onDropdownClicked: console.log("Kliknięto strzałkę: Otwieram menu opcji")
        }

        CustomButton {
            text: isRecording ? "Nagrywanie..." : "Nagrywaj"
            iconText: "🔴"
            onClicked: {
                isRecording = !isRecording
                console.log("Stan nagrywania: " + isRecording)
            }
        }

        CustomButton {
            text: "Dodaj marker"
            iconText: "📍"
            onClicked: {
                var now = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss.zzz")
                rawLogModel.append({
                    time: now,
                    tag: "MARK",
                    tagColor: "#e67e22",
                    dir: "--",
                    payload: "=================== MARKER ==================="
                })
            }
        }

        CustomButton {
            text: "Wyczyść wszystko"
            iconText: "🗑"
            onClicked: {
                rawLogModel.clear()
                filteredLogModel.clear()
                regexModel.clear()
            }
        }

        CustomButton {
            text: "Ustawienia"
            iconText: "⚙"
            onClicked: console.log("Otwarto Ustawienia")
        }
    }

    // --- PRAWA STRONA: Widgety Informacyjne (z osobnego pliku ModernInfoWidget.qml) ---
    Row {
        id: rightWidgets
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 5
        anchors.rightMargin: 5
        spacing: 5

        ModernInfoWidget {
            id: dummyGenerator
            titleText: "Dummy Gen"
            contentText: "Generator: 100 Hz"
            bottomText: "Status: Aktywny"
            stateType: "Connected"
        }

        ModernInfoWidget {
            id: myWidget
            titleText: "Ethernet 1"
            contentText: "Aktualna temp: 21.5 °C"
            bottomText: "539 kB/s"
            stateType: "Connected"
        }

        ModernInfoWidget {
            id: myCOM
            titleText: "COM 1"
            contentText: "Połączono (100 Mbps)"
            bottomText: "5.12 MB/s"
            stateType: "Warning"
        }
    }

    // =========================================================
    // --- DOLNA SEKCJA: GŁÓWNY PIONOWY SPLITVIEW ---
    // =========================================================
    SplitView {
        anchors.top: rightWidgets.height > leftButtons.height ? rightWidgets.bottom : leftButtons.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 5
        anchors.topMargin: 10
        orientation: Qt.Vertical

        // Panel górny (GŁÓWNE LOGI)
        Rectangle {
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            SplitView.minimumHeight: 120
            color: "#2d2d2d"
            radius: 8
            border.color: "#3d3d3d"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Ξ Logi (wszystkie interfejsy)"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 65; height: 22; color: "transparent"; radius: 4; border.color: "#3d3d3d"
                        Row {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "🗑"; color: "#aaaaaa"; font.pixelSize: 10 }
                            Text { text: "Clear"; color: "#aaaaaa"; font.pixelSize: 11 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rawLogModel.clear()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: rawLogModel
                    delegate: RowLayout {
                        width: ListView.view.width
                        spacing: 8

                        Text { text: model.time; color: "#888888"; font.family: "Monospace"; font.pixelSize: 11 }
                        Rectangle {
                            width: 42; height: 16; radius: 3; color: model.tagColor
                            Text { anchors.centerIn: parent; text: model.tag; color: "white"; font.pixelSize: 9; font.bold: true }
                        }
                        Text { text: model.dir; color: model.dir === "RX" ? "#00c853" : "#0091ea"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true }
                        Text { text: model.payload; color: "#dddddd"; font.family: "Monospace"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }
            }
        }

        // =========================================================
        // --- SEKCJA WPROWADZANIA KOMEND I MAKR ---
        // =========================================================
        Rectangle {
            SplitView.fillWidth: true
            SplitView.preferredHeight: 130
            SplitView.minimumHeight: 90
            color: "#232323"
            radius: 8
            border.color: "#3d3d3d"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // 1. Pole Wprowadzania Komend
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Komenda:"
                        color: "#007acc"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextField {
                        id: commandInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        placeholderText: "Wpisz komendę (np. AT+RST lub SEND 0x01)..."
                        font.family: "Monospace"
                        font.pixelSize: 12
                        color: "white"
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle {
                            color: "#1a1a1a"
                            radius: 4
                            border.color: commandInput.activeFocus ? "#007acc" : "#444444"
                        }
                        onAccepted: sendBtn.clicked()
                    }

                    CustomButton {
                        id: sendBtn
                        text: "Wyślij"
                        iconText: "↵"
                        Layout.preferredHeight: 32
                        Layout.fillHeight: true
                        onClicked: {
                            if (commandInput.text.length > 0) {
                                console.log("Wysłano komendę: " + commandInput.text)
                                commandInput.clear()
                            }
                        }
                    }
                }

                // 2. Sekcja Makr
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    ScrollView {
                        id: macroScrollView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Flow {
                            id: macroFlow
                            width: macroScrollView.availableWidth
                            spacing: 6

                            // Domyślne przyciski
                            CustomButton {
                                text: "Ping CAN"
                                iconText: "▶"
                                onClicked: console.log("Wykonuję: Ping CAN")
                            }

                            CustomButton {
                                text: "Reset UART"
                                iconText: "🔄"
                                onClicked: console.log("Wykonuję: Reset UART")
                            }

                            CustomButton {
                                text: "Set Baudrate 115200"
                                iconText: "⚡"
                                onClicked: console.log("Wykonuję: Baudrate")
                            }
                        }
                    }

                    // Przycisk dodawania kolejnych makr
                    Rectangle {
                        width: 26
                        height: 26
                        color: "#333333"
                        radius: 4
                        border.color: "#555555"
                        Layout.alignment: Qt.AlignTop

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: "#aaaaaa"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: addMacroButton("Makro " + (macroFlow.children.length + 1), function() {
                                console.log("Wywołano dynamiczne makro")
                            })
                        }
                    }
                }
            }
        }

        // Panel dolny (SPLITVIEW POZIOMY): Dopasowane logi (Lewo) + Regexy (Prawo)
        SplitView {
            SplitView.fillWidth: true
            SplitView.preferredHeight: 220
            SplitView.minimumHeight: 120
            orientation: Qt.Horizontal

            // Lewe okno: Logi przefiltrowane
            Rectangle {
                SplitView.fillWidth: true
                SplitView.fillHeight: true
                SplitView.minimumWidth: 300
                color: "#2d2d2d"
                radius: 8
                border.color: "#3d3d3d"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Y Logi dopasowane do regexów"
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 65; height: 22; color: "transparent"; radius: 4; border.color: "#3d3d3d"
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Text { text: "🗑"; color: "#aaaaaa"; font.pixelSize: 10 }
                                Text { text: "Clear"; color: "#aaaaaa"; font.pixelSize: 11 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: filteredLogModel.clear()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: filteredLogModel
                        delegate: RowLayout {
                            width: ListView.view.width
                            spacing: 8

                            Text { text: model.time; color: "#888888"; font.family: "Monospace"; font.pixelSize: 11 }
                            Rectangle {
                                width: 42; height: 16; radius: 3; color: model.tagColor
                                Text { anchors.centerIn: parent; text: model.tag; color: "white"; font.pixelSize: 9; font.bold: true }
                            }
                            Text { text: model.dir; color: model.dir === "RX" ? "#00c853" : "#0091ea"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true }
                            Text { text: model.payload; color: "#dddddd"; font.family: "Monospace"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                }
            }

            // Prawe okno: Zarządzanie Regexami
            Rectangle {
                SplitView.preferredWidth: 340
                SplitView.minimumWidth: 260
                SplitView.maximumWidth: 480
                SplitView.fillHeight: true
                color: "#2d2d2d"
                radius: 8
                border.color: "#3d3d3d"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Y| Regexy"
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 65; height: 24; color: "#007acc"; radius: 4
                            Row {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: "+"; color: "white"; font.pixelSize: 12; font.bold: true }
                                Text { text: "Dodaj"; color: "white"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 10
                        model: regexModel
                        delegate: RowLayout {
                            width: ListView.view.width
                            spacing: 8

                            Rectangle {
                                width: 14; height: 14; radius: 3
                                color: model.active ? "#007acc" : "transparent"
                                border.color: model.active ? "#007acc" : "#555555"
                                Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 10; visible: model.active }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: regexModel.setProperty(index, "active", !model.active)
                                }
                            }

                            Text {
                                text: model.pattern
                                color: "#bbbbbb"
                                font.family: "Monospace"
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 12; height: 12; radius: 6; color: model.tagColor
                                Layout.preferredWidth: 12; Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                width: 18; height: 18; radius: 3
                                color: deleteMouseArea.containsMouse ? "#e74c3c" : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: deleteMouseArea.containsMouse ? "white" : "#888888"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: deleteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: regexModel.remove(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}