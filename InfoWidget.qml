// InfoWidget.qml
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 160
    height: 120
    color: "#2d2d2d"

    // Włączenie obcinania zawartości do zaokrąglonych rogów (Standard Qt6)
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }

    // Właściwości udostępnione na zewnątrz
    property string stateType: "Not connected"
    property string titleText: "Title"
    property string contentText: "content..."
    property string bottomText: "Status"

    // Właściwości dla wykresu
    property var dataBuffer: []
    property color chartColor: "#00cc44"
    property real currentMaxY: 100 // Dynamicznie wyliczana skrajna wartość Y

    // Parametry czasu i nieliniowości
    property int timeWindowMs: 10000       // Zasięg czasowy (8 sekund)
    property real compressionFactor: 0.5   // < 1.0 rozciąga nowe dane (po prawej) i ściska stare (po lewej)
    property int gridIntervalMs: 1000       // Pionowe linie co 500 ms

    // Funkcja dodająca nową wartość do wykresu
    function addBitrateValue(value) {
        var now = Date.now()
        var newBuffer = dataBuffer.slice()
        newBuffer.push({ val: value, time: now })

        // Usuwamy stary bufor (starszy niż zdefiniowane okno czasowe)
        while (newBuffer.length > 0 && (now - newBuffer[0].time) > root.timeWindowMs) {
            newBuffer.shift()
        }

        // Automatyczne skalowanie – znajdowanie wartości maksymalnej
        var maxVal = 10 // Domyślna minimalna skala
        for (var i = 0; i < newBuffer.length; i++) {
            if (newBuffer[i].val > maxVal) maxVal = newBuffer[i].val
        }
        root.currentMaxY = maxVal * 1.15 // +15% zapasu na górze

        dataBuffer = newBuffer
    }

    function getBarColor(type) {
        switch (type) {
            case "Connected":     return "#00cc44" // Zielony
            case "Warning":       return "#ffcc00" // Żółty
            case "Error":         return "#ff1010" // Czerwony
            case "Not connected": return "#333333" // Szary
            default:              return "#ffcc00" // Domyślny
        }
    }

    // Pętla animacyjna wymuszająca płynne przerysowywanie (60 FPS)
    FrameAnimation {
        running: root.dataBuffer.length > 0
        onTriggered: chartCanvas.requestPaint()
    }

    // Górny pasek
    Rectangle {
        id: topBar
        width: parent.width
        height: 20
        anchors.top: parent.top

        color: root.getBarColor(root.stateType)

        border.color: "#cccccc"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MouseArea {
            id: barMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }

        Text {
            anchors.centerIn: parent
            text: root.titleText
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }
    }

    // ŚRODKOWA CZĘŚĆ - NIELINIOWY WYKRES Z GRADIENTEM I SIATKĄ 500MS
    Canvas {
        id: chartCanvas
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 2

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var now = Date.now()

            // Helper do przeliczania czasu na współrzędną X (Nieliniowo)
            function calculateX(itemTime) {
                var age = now - itemTime
                var normalizedAge = Math.min(Math.max(age / root.timeWindowMs, 0), 1)
                var nonLinearProgress = Math.pow(normalizedAge, root.compressionFactor)
                return width - (nonLinearProgress * width)
            }

            // 1. RYSOWANIE SIATKI (Pozioma + Pionowe co 500 ms)
            ctx.strokeStyle = "#5a5a5a"
            ctx.lineWidth = 1.0

            // Pozioma linia środkowa
            // ctx.beginPath()
            // ctx.moveTo(0, height / 2)
            // ctx.lineTo(width, height / 2)
            // ctx.stroke()

            // Pionowe linie czasu (wyrównane do siatki czasowej systemu)
            var lastTickTime = now - (now % root.gridIntervalMs)
            ctx.beginPath()
            for (var t = lastTickTime; t > now - root.timeWindowMs; t -= root.gridIntervalMs) {
                var gridX = calculateX(t)
                if (gridX >= 0 && gridX <= width) {
                    ctx.moveTo(gridX, 0)
                    ctx.lineTo(gridX, height)
                }
            }
            ctx.stroke()

            if (root.dataBuffer.length < 2) return

            // 2. PRZYGOTOWANIE GRADIENTU
            var gradient = ctx.createLinearGradient(0, 0, 0, height)
            var baseColor = Qt.color(root.chartColor)
            gradient.addColorStop(0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.9))
            gradient.addColorStop(1, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0))

            // 3. TWORZENIE ŚCIEŻKI DLA GRADIENTU
            var firstX = 0
            var lastX = 0

            ctx.beginPath()
            for (var i = 0; i < root.dataBuffer.length; i++) {
                var item = root.dataBuffer[i]
                var x = calculateX(item.time)
                var y = height - (item.val / root.currentMaxY) * height

                if (i === 0) {
                    ctx.moveTo(x, y)
                    firstX = x
                } else {
                    ctx.lineTo(x, y)
                }
                lastX = x
            }

            // 4. WYPEŁNIANIE GRADIENTEM
            ctx.save()
            ctx.lineTo(lastX, height)
            ctx.lineTo(firstX, height)
            ctx.closePath()
            ctx.fillStyle = gradient
            ctx.fill()
            ctx.restore()

            // 5. RYSOWANIE LINII NA WIERZCHU
            ctx.beginPath()
            ctx.lineWidth = 1.5
            ctx.strokeStyle = root.chartColor
            for (var j = 0; j < root.dataBuffer.length; j++) {
                var itemLine = root.dataBuffer[j]
                var xLine = calculateX(itemLine.time)
                var yLine = height - (itemLine.val / root.currentMaxY) * height

                if (j === 0) {
                    ctx.moveTo(xLine, yLine)
                } else {
                    ctx.lineTo(xLine, yLine)
                }
            }
            ctx.stroke()
        }
    }

    // Wskaźniki skali Y (Max i Min)
    Text {
        anchors.top: chartCanvas.top
        anchors.left: chartCanvas.left
        anchors.leftMargin: 2
        text: Math.round(root.currentMaxY)
        color: "white"
        font.pixelSize: 8
        visible: root.dataBuffer.length > 0
    }

    Text {
        anchors.bottom: chartCanvas.bottom
        anchors.left: chartCanvas.left
        anchors.leftMargin: 2
        text: "0"
        color: "white"
        font.pixelSize: 8
        visible: root.dataBuffer.length > 0
    }

    // Tekst wyświetlany, gdy brak danych do wykresu
    Text {
        anchors.centerIn: chartCanvas
        text: root.contentText
        color: "white"
        font.pixelSize: 11
        visible: root.dataBuffer.length === 0
    }

    // Dolny pasek
    Rectangle {
        id: bottomBar
        width: parent.width
        height: 20
        anchors.bottom: parent.bottom
        color: root.color

        border.color: "#cccccc"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Text {
            anchors.centerIn: parent
            text: root.bottomText
            color: "white"
            font.pixelSize: 11
        }
    }

    // Nakładka z ramką całego widgetu (z zaokrągleniem)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#cccccc"
        border.width: 1
        radius: root.radius
        z: 1
    }
}