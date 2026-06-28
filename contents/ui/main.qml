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
    property string translatedText: ""
    property string lastDetectedSourceLanguage: ""
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
        statusText = swapStatus(sourceLang.currentValue, targetLang.currentValue);
    }

    function copyTranslation(textArea) {
        if (translatedText.length === 0)
            return ;

        textArea.forceActiveFocus();
        textArea.selectAll();
        textArea.copy();
        statusText = i18n("Copied");
    }

    function translate(text, sourceLanguage, targetLanguage) {
        const apiKey = plasmoid.configuration.apiKey;
        const apiHost = plasmoid.configuration.apiHost || "https://api-free.deepl.com";
        if (!apiKey || apiKey.trim().length === 0) {
            statusText = i18n("Set your DeepL API key in the widget settings.");
            return ;
        }
        const validation = TranslationEngine.validateRequest(text, sourceLanguage, targetLanguage);
        if (!validation.ok) {
            statusText = validation.message;
            return ;
        }
        busy = true;
        statusText = i18n("Translating...");
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
                    statusText = translatedText.length > 0 ? TranslationEngine.formatSuccessStatus(response, sourceLanguage, targetLanguage) : i18n("No translation returned.");
                } catch (error) {
                    statusText = i18n("Could not read DeepL response.");
                }
                return ;
            }
            statusText = TranslationEngine.formatDeepLError(request.status, request.responseText);
        };
        request.onerror = function() {
            busy = false;
            statusText = TranslationEngine.formatDeepLError(0, "");
        };
        request.send(JSON.stringify(body));
    }

    Plasmoid.icon: "accessories-dictionary"
    Plasmoid.title: i18n("DeepL Translator")
    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
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

        implicitWidth: Kirigami.Units.gridUnit * 24
        implicitHeight: Kirigami.Units.gridUnit * 27

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextArea {
                id: inputText

                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                wrapMode: TextEdit.Wrap
                placeholderText: i18n("Text to translate")
                selectByMouse: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        text: i18n("From")
                    }

                    QQC2.ComboBox {
                        id: sourceLang

                        Layout.fillWidth: true
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
                        textRole: "text"
                        valueRole: "value"
                        model: root.targetLanguages
                        Component.onCompleted: currentIndex = root.languageIndex(targetLang, plasmoid.configuration.targetLang, 0)
                    }

                }

            }

            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                text: root.busy ? i18n("Translating") : i18n("Translate")
                enabled: !root.busy && inputText.text.trim().length > 0
                icon.name: "run-build"
                onClicked: root.translate(inputText.text, sourceLang.currentValue, targetLang.currentValue)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                color: root.currentValidation().ok ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.negativeTextColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                text: root.currentValidation().ok ? TranslationEngine.requestSizeText(inputText.text, sourceLang.currentValue, targetLang.currentValue) : root.currentValidation().message
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

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.statusText
                }

                QQC2.Button {
                    icon.name: "edit-copy"
                    enabled: root.translatedText.length > 0
                    text: i18n("Copy")
                    onClicked: root.copyTranslation(outputText)
                }

            }

        }

    }

}
