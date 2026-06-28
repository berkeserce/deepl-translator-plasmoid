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
        busy = true;
        statusText = i18n("Translating...");
        translatedText = "";
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
                    statusText = translatedText.length > 0 ? i18n("Done") : i18n("No translation returned.");
                } catch (error) {
                    statusText = i18n("Could not read DeepL response.");
                }
                return ;
            }
            statusText = TranslationEngine.formatDeepLError(request.status, request.responseText);
        };
        request.onerror = function() {
            busy = false;
            statusText = i18n("Network error.");
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
        implicitHeight: Kirigami.Units.gridUnit * 26

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
                columns: 2
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
