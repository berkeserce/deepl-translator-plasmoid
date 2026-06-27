import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property bool busy: false
    property string statusText: ""
    property string translatedText: ""

    function translate(text, targetLanguage) {
        const apiKey = plasmoid.configuration.apiKey;
        const apiHost = plasmoid.configuration.apiHost || "https://api-free.deepl.com";
        const sourceLanguage = plasmoid.configuration.sourceLang;
        if (!apiKey || apiKey.trim().length === 0) {
            statusText = i18n("Set your DeepL API key in the widget settings.");
            return ;
        }
        busy = true;
        statusText = i18n("Translating...");
        translatedText = "";
        const body = {
            "text": [text],
            "target_lang": targetLanguage || "EN-US"
        };
        if (sourceLanguage && sourceLanguage.trim().length > 0)
            body.source_lang = sourceLanguage.trim();

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
                    const response = JSON.parse(request.responseText);
                    translatedText = response.translations && response.translations.length > 0 ? response.translations[0].text : "";
                    statusText = translatedText.length > 0 ? i18n("Done") : i18n("No translation returned.");
                } catch (error) {
                    statusText = i18n("Could not read DeepL response.");
                }
                return ;
            }
            statusText = i18n("DeepL error: %1", request.status);
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

            RowLayout {
                Layout.fillWidth: true

                QQC2.ComboBox {
                    id: targetLang

                    Layout.fillWidth: true
                    editable: true
                    model: ["EN-US", "EN-GB", "TR", "DE", "FR", "ES", "IT", "NL", "PL", "PT-BR", "PT-PT", "RU", "JA", "ZH"]
                    Component.onCompleted: editText = plasmoid.configuration.targetLang || "EN-US"
                }

                QQC2.Button {
                    text: root.busy ? i18n("Translating") : i18n("Translate")
                    enabled: !root.busy && inputText.text.trim().length > 0
                    icon.name: "run-build"
                    onClicked: root.translate(inputText.text, targetLang.editText)
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
                    onClicked: {
                        outputText.selectAll();
                        outputText.copy();
                    }
                }

            }

        }

    }

}
