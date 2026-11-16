// modernInfoWidget.qml
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 140
    height: 100
    color: "#2d2d2d" // Ciemne, granatowe tło
    radius: 5
    border.color: "#a3a3a3"
    border.width: 1

    // Włączenie obcinania zawartości do zaokrąglonych rogów
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
    property string stateType: "Connected"
    property string titleText: "UART"
    property string contentText: "115200 bps" // Szary tekst w środku
    property string bottomText: "115200 bps"  // Tekst wyświetlany na samym dole

    // Właściwości dla wykresu
    property var dataBuffer: []
    property color chartColor: getStatusColor(root.stateType)
    property real currentMaxY: 100

    // Parametry czasu i nieliniowości
    property int timeWindowMs: 10000
    property real compressionFactor: 0.5
    property int gridIntervalMs: 1000

    // Funkcja dodająca nową wartość do wykresu
    function addBitrateValue(value) {
        var now = Date.now()
        var newBuffer = dataBuffer.slice()
        newBuffer.push({ val: value, time: now })

        while (newBuffer.length > 0 && (now - newBuffer[0].time) > root.timeWindowMs) {
            newBuffer.shift()
        }

        var maxVal = 10
        for (var i = 0; i < newBuffer.length; i++) {
            if (newBuffer[i].val > maxVal) maxVal = newBuffer[i].val
        }
        root.currentMaxY = maxVal * 1.15

        dataBuffer = newBuffer
    }

    function getStatusColor(type) {
        switch (type) {
            case "Connected":     return "#00e676" // Neonowa zieleń
            case "Warning":       return "#ffcc00" // Żółty
            case "Error":         return "#ff3333" // Czerwony
            case "Not connected": return "#555555" // Szary
            default:              return "#00e676"
        }
    }

    // Pętla animacyjna (60 FPS)
    FrameAnimation {
        running: root.dataBuffer.length > 0
        onTriggered: chartCanvas.requestPaint()
    }

    // GŁÓWNY KONTENER NA SEKCJE GÓRNE (TYTUŁ + STATUS + CONTENT TEXT)
    Column {
        id: headerColumn
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 1

        // Nagłówek: Zielona kropka + Tytuł
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: root.getStatusColor(root.stateType)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.titleText
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
        }

        // Tekst statusu w kolorze zależnym od stanu (np. Connected)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.stateType
            color: root.getStatusColor(root.stateType)
            font.pixelSize: 12
           font.bold: true
        }

        // Szary tekst w środku (contentText)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.contentText
            color: "#a3a3a3"
            font.pixelSize: 11
        }
    }

    // WYKRES NA DOLE
    Canvas {
        id: chartCanvas
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomValText.top
        anchors.bottomMargin: 1
        height: 30

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var now = Date.now()

            function calculateX(itemTime) {
                var age = now - itemTime
                var normalizedAge = Math.min(Math.max(age / root.timeWindowMs, 0), 1)
                var nonLinearProgress = Math.pow(normalizedAge, root.compressionFactor)
                return width - (nonLinearProgress * width)
            }

            if (root.dataBuffer.length < 2) return

            // 1. GRADIENT
            var gradient = ctx.createLinearGradient(0, 0, 0, height)
            var baseColor = Qt.color(root.chartColor)
            gradient.addColorStop(0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.4))
            gradient.addColorStop(1, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0))

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

            ctx.save()
            ctx.lineTo(lastX, height)
            ctx.lineTo(firstX, height)
            ctx.closePath()
            ctx.fillStyle = gradient
            ctx.fill()
            ctx.restore()

            // 2. LINIA WYKRESU
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

    // Podpis na samym dole po prawej stronie (bottomText)
    Text {
        id: bottomValText
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        text: root.bottomText
        color: root.chartColor
        font.pixelSize: 10
    }
}