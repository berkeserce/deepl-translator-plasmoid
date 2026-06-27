import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_apiKey: apiKeyField.text
    property string cfg_apiHost: "https://api-free.deepl.com"
    property alias cfg_targetLang: targetLangBox.editText
    property alias cfg_sourceLang: sourceLangBox.editText

    QQC2.TextField {
        id: apiKeyField

        Kirigami.FormData.label: i18n("API key:")
        echoMode: TextInput.Password
        placeholderText: i18n("DeepL API key")
    }

    QQC2.ComboBox {
        id: apiHostBox

        Kirigami.FormData.label: i18n("Account:")
        textRole: "text"
        valueRole: "value"
        model: [{
            "text": i18n("Free"),
            "value": "https://api-free.deepl.com"
        }, {
            "text": i18n("Pro"),
            "value": "https://api.deepl.com"
        }]
        Component.onCompleted: {
            const index = indexOfValue(page.cfg_apiHost);
            currentIndex = index >= 0 ? index : 0;
        }
        onCurrentValueChanged: page.cfg_apiHost = currentValue
    }

    QQC2.ComboBox {
        id: targetLangBox

        Kirigami.FormData.label: i18n("Target language:")
        editable: true
        model: ["EN-US", "EN-GB", "TR", "DE", "FR", "ES", "IT", "NL", "PL", "PT-BR", "PT-PT", "RU", "JA", "ZH"]
    }

    QQC2.ComboBox {
        id: sourceLangBox

        Kirigami.FormData.label: i18n("Source language:")
        editable: true
        model: ["", "TR", "EN", "DE", "FR", "ES", "IT", "NL", "PL", "PT", "RU", "JA", "ZH"]
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Leave source language empty for automatic detection.")
    }

}
