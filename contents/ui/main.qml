import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import "TranslationEngine.js" as TranslationEngine
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property bool busy: false
    property string statusText: ""
    property string statusTone: "neutral"
    property string translatedText: ""
    property string lastDetectedSourceLanguage: ""
    readonly property url appIconSource: Qt.resolvedUrl("../images/deepl-translator.svg")
    property var sourceLanguages: [{
        "text": i18n("Auto detect"),
        "value": ""
    }, {
        "text": "TR",
        "value": "TR"
    }, {
        "text": "EN",
        "value": "EN"
    }, {
        "text": "DE",
        "value": "DE"
    }, {
        "text": "FR",
        "value": "FR"
    }, {
        "text": "ES",
        "value": "ES"
    }, {
        "text": "IT",
        "value": "IT"
    }, {
        "text": "NL",
        "value": "NL"
    }, {
        "text": "PL",
        "value": "PL"
    }, {
        "text": "PT",
        "value": "PT"
    }, {
        "text": "RU",
        "value": "RU"
    }, {
        "text": "JA",
        "value": "JA"
    }, {
        "text": "ZH",
        "value": "ZH"
    }]
    property var targetLanguages: [{
        "text": "EN-US",
        "value": "EN-US"
    }, {
        "text": "EN-GB",
        "value": "EN-GB"
    }, {
        "text": "TR",
        "value": "TR"
    }, {
        "text": "DE",
        "value": "DE"
    }, {
        "text": "FR",
        "value": "FR"
    }, {
        "text": "ES",
        "value": "ES"
    }, {
        "text": "IT",
        "value": "IT"
    }, {
        "text": "NL",
        "value": "NL"
    }, {
        "text": "PL",
        "value": "PL"
    }, {
        "text": "PT-BR",
        "value": "PT-BR"
    }, {
        "text": "PT-PT",
        "value": "PT-PT"
    }, {
        "text": "RU",
        "value": "RU"
    }, {
        "text": "JA",
        "value": "JA"
    }, {
        "text": "ZH",
        "value": "ZH"
    }]

    function languageIndex(comboBox, value, fallbackIndex) {
        const index = comboBox.indexOfValue(value || "");
        return index >= 0 ? index : fallbackIndex;
    }

    function currentValidation() {
        return TranslationEngine.validateRequest(inputText.text, sourceLang.currentValue, targetLang.currentValue);
    }

    function requestSizeRatio() {
        const validation = currentValidation();
        return validation.limitBytes > 0 ? Math.min(validation.bytes / validation.limitBytes, 1) : 0;
    }

    function requestSizeColor() {
        const validation = currentValidation();
        if (!validation.ok)
            return Kirigami.Theme.negativeTextColor;

        return requestSizeRatio() >= 0.85 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.disabledTextColor;
    }

    function setStatus(message, tone) {
        statusText = message;
        statusTone = tone || "neutral";
    }

    function statusColor() {
        if (statusText.length === 0)
            return Kirigami.Theme.disabledTextColor;

        if (statusTone === "error")
            return Kirigami.Theme.negativeTextColor;

        if (statusTone === "success")
            return Kirigami.Theme.positiveTextColor;

        if (statusTone === "warning")
            return Kirigami.Theme.neutralTextColor;

        return Kirigami.Theme.textColor;
    }

    function setComboValue(comboBox, value, fallbackIndex) {
        const index = comboBox.indexOfValue(value || "");
        comboBox.currentIndex = index >= 0 ? index : fallbackIndex;
    }

    function sourceValueForTarget(targetLanguage) {
        const target = TranslationEngine.normalizeLanguage(targetLanguage);
        if (sourceLang.indexOfValue(target) >= 0)
            return target;

        const family = TranslationEngine.languageFamily(target);
        return sourceLang.indexOfValue(family) >= 0 ? family : "";
    }

    function targetValueForSource(sourceLanguage) {
        const source = TranslationEngine.normalizeLanguage(sourceLanguage);
        if (targetLang.indexOfValue(source) >= 0)
            return source;

        const family = TranslationEngine.languageFamily(source);
        if (family === "EN")
            return "EN-US";

        return targetLang.indexOfValue(family) >= 0 ? family : "";
    }

    function fallbackTargetForAutoDetect(previousTarget) {
        const previousTargetFamily = TranslationEngine.languageFamily(previousTarget);
        return previousTargetFamily === "EN" ? "TR" : "EN-US";
    }

    function targetValueForAutoDetect(previousTarget, detectedSourceLanguage) {
        const detected = targetValueForSource(detectedSourceLanguage);
        if (detected.length > 0)
            return detected;

        return fallbackTargetForAutoDetect(previousTarget);
    }

    function swapStatus(sourceLanguage, targetLanguage) {
        return i18n("Swapped: %1 -> %2", sourceLanguage.length > 0 ? sourceLanguage : i18n("Auto"), targetLanguage);
    }

    function swapLanguagesAndText(inputTextArea) {
        const previousSource = sourceLang.currentValue;
        const previousTarget = targetLang.currentValue;
        const previousInput = inputTextArea.text;
        const previousOutput = translatedText;
        const sourceForTarget = sourceValueForTarget(previousTarget);
        const targetForSource = previousSource && previousSource.length > 0 ? targetValueForSource(previousSource) : targetValueForAutoDetect(previousTarget, lastDetectedSourceLanguage);
        setComboValue(sourceLang, sourceForTarget, 0);
        setComboValue(targetLang, targetForSource, 0);
        if (previousOutput.length > 0) {
            inputTextArea.text = previousOutput;
            translatedText = previousInput;
        }
        setStatus(swapStatus(sourceLang.currentValue, targetLang.currentValue), "neutral");
    }

    function clearInput(inputTextArea) {
        if (busy)
            return ;

        inputTextArea.text = "";
        translatedText = "";
        lastDetectedSourceLanguage = "";
        setStatus("", "neutral");
    }

    function copyTranslation(textArea) {
        if (translatedText.length === 0)
            return ;

        textArea.forceActiveFocus();
        textArea.selectAll();
        textArea.copy();
        setStatus(i18n("Copied"), "success");
    }

    function translate(text, sourceLanguage, targetLanguage) {
        const apiKey = plasmoid.configuration.apiKey;
        const apiHost = plasmoid.configuration.apiHost || "https://api-free.deepl.com";
        if (!apiKey || apiKey.trim().length === 0) {
            setStatus(i18n("Set your DeepL API key in the widget settings."), "warning");
            return ;
        }
        const validation = TranslationEngine.validateRequest(text, sourceLanguage, targetLanguage);
        if (!validation.ok) {
            setStatus(validation.message, "error");
            return ;
        }
        busy = true;
        setStatus(i18n("Translating..."), "neutral");
        translatedText = "";
        lastDetectedSourceLanguage = "";
        const body = TranslationEngine.buildRequestBody(text, sourceLanguage, targetLanguage);
        const request = new XMLHttpRequest();
        request.open("POST", apiHost + "/v2/translate");
        request.setRequestHeader("Authorization", "DeepL-Auth-Key " + apiKey.trim());
        request.setRequestHeader("Content-Type", "application/json");
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            busy = false;
            if (request.status >= 200 && request.status < 300) {
                try {
                    const response = TranslationEngine.parseTranslateResponse(request.responseText);
                    translatedText = response.text;
                    lastDetectedSourceLanguage = response.detectedSourceLanguage;
                    setStatus(translatedText.length > 0 ? TranslationEngine.formatSuccessStatus(response, sourceLanguage, targetLanguage) : i18n("No translation returned."), translatedText.length > 0 ? "success" : "warning");
                } catch (error) {
                    setStatus(i18n("Could not read DeepL response."), "error");
                }
                return ;
            }
            setStatus(TranslationEngine.formatDeepLError(request.status, request.responseText), "error");
        };
        request.onerror = function() {
            busy = false;
            setStatus(TranslationEngine.formatDeepLError(0, ""), "error");
        };
        request.send(JSON.stringify(body));
    }

    Plasmoid.icon: "accessories-dictionary"
    Plasmoid.title: i18n("DeepL Translator")
    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
            source: root.appIconSource
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }

    }

    fullRepresentation: Item {
        id: popup

        implicitWidth: Kirigami.Units.gridUnit * 25
        implicitHeight: Kirigami.Units.gridUnit * 29

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 1.2

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Image {
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    smooth: true
                    source: root.appIconSource
                }

                PlasmaComponents.Label {
                    font.weight: Font.DemiBold
                    text: i18n("DeepL Translator")
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    color: root.statusColor()
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    text: root.statusText.length > 0 ? root.statusText : i18n("Ready")
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        text: i18n("From")
                    }

                    QQC2.ComboBox {
                        id: sourceLang

                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                        textRole: "text"
                        valueRole: "value"
                        model: root.sourceLanguages
                        Component.onCompleted: currentIndex = root.languageIndex(sourceLang, plasmoid.configuration.sourceLang, 0)
                    }

                }

                QQC2.Button {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    enabled: !root.busy
                    icon.name: "exchange-positions"
                    onClicked: root.swapLanguagesAndText(inputText)
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Swap languages and text")
                    QQC2.ToolTip.visible: hovered
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        text: i18n("To")
                    }

                    QQC2.ComboBox {
                        id: targetLang

                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                        textRole: "text"
                        valueRole: "value"
                        model: root.targetLanguages
                        Component.onCompleted: currentIndex = root.languageIndex(targetLang, plasmoid.configuration.targetLang, 0)
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    font.weight: Font.DemiBold
                    text: i18n("Source")
                }

                QQC2.ToolButton {
                    enabled: !root.busy && inputText.text.length > 0
                    icon.name: "edit-clear"
                    onClicked: root.clearInput(inputText)
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Clear source text")
                    QQC2.ToolTip.visible: hovered
                }

            }

            QQC2.TextArea {
                id: inputText

                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                wrapMode: TextEdit.Wrap
                placeholderText: i18n("Text to translate")
                selectByMouse: true
                Keys.onPressed: function(event) {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = true;
                        if (!root.busy && inputText.text.trim().length > 0)
                            root.translate(inputText.text, sourceLang.currentValue, targetLang.currentValue);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        color: root.requestSizeColor()
                        elide: Text.ElideRight
                        text: root.currentValidation().ok ? TranslationEngine.requestSizeText(inputText.text, sourceLang.currentValue, targetLang.currentValue) : root.currentValidation().message
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: root.currentValidation().limitBytes
                        value: Math.min(root.currentValidation().bytes, root.currentValidation().limitBytes)
                    }

                }

                QQC2.Button {
                    highlighted: true
                    text: root.busy ? i18n("Translating") : i18n("Translate")
                    enabled: !root.busy && inputText.text.trim().length > 0
                    icon.name: "run-build"
                    onClicked: root.translate(inputText.text, sourceLang.currentValue, targetLang.currentValue)
                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    font.weight: Font.DemiBold
                    text: i18n("Translation")
                }

                QQC2.ToolButton {
                    enabled: root.translatedText.length > 0
                    icon.name: "edit-copy"
                    onClicked: root.copyTranslation(outputText)
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Copy translation")
                    QQC2.ToolTip.visible: hovered
                }

            }

            QQC2.TextArea {
                id: outputText

                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                wrapMode: TextEdit.Wrap
                text: root.translatedText
                placeholderText: i18n("Translation")
                selectByMouse: true
            }

        }

    }

}
