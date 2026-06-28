.pragma library

const REQUEST_BODY_LIMIT_BYTES = 128 * 1024;

function normalizeLanguage(language) {
    return (language || "").trim().toUpperCase();
}

function languageFamily(language) {
    const normalized = normalizeLanguage(language);
    const separator = normalized.indexOf("-");
    return separator >= 0 ? normalized.slice(0, separator) : normalized;
}

function buildRequestBody(text, sourceLanguage, targetLanguage) {
    const source = normalizeLanguage(sourceLanguage);
    const body = {
        "text": [text],
        "target_lang": normalizeLanguage(targetLanguage) || "EN-US",
        "show_billed_characters": true
    };

    if (source.length > 0)
        body.source_lang = source;

    return body;
}

function requestBodyBytes(body) {
    return utf8ByteLength(JSON.stringify(body));
}

function validateRequest(text, sourceLanguage, targetLanguage) {
    const source = normalizeLanguage(sourceLanguage);
    const target = normalizeLanguage(targetLanguage) || "EN-US";
    const body = buildRequestBody(text, source, target);
    const bytes = requestBodyBytes(body);

    if (source.length > 0 && languageFamily(source) === languageFamily(target)) {
        return {
            "ok": false,
            "message": "Choose different source and target languages.",
            "bytes": bytes,
            "limitBytes": REQUEST_BODY_LIMIT_BYTES
        };
    }

    if (bytes > REQUEST_BODY_LIMIT_BYTES) {
        return {
            "ok": false,
            "message": "Text is too large for a single DeepL request.",
            "bytes": bytes,
            "limitBytes": REQUEST_BODY_LIMIT_BYTES
        };
    }

    return {
        "ok": true,
        "message": "",
        "bytes": bytes,
        "limitBytes": REQUEST_BODY_LIMIT_BYTES
    };
}

function requestSizeText(text, sourceLanguage, targetLanguage) {
    const validation = validateRequest(text, sourceLanguage, targetLanguage);
    return formatBytes(validation.bytes) + " / " + formatBytes(validation.limitBytes);
}

function parseTranslateResponse(responseText) {
    const response = JSON.parse(responseText);
    const translations = response.translations || [];
    const translation = translations.length > 0 ? translations[0] : {};

    return {
        "text": translation.text || "",
        "detectedSourceLanguage": translation.detected_source_language || "",
        "billedCharacters": translation.billed_characters !== undefined ? translation.billed_characters : response.billed_characters || 0
    };
}

function formatSuccessStatus(result, sourceLanguage, targetLanguage) {
    const detectedSource = normalizeLanguage(result.detectedSourceLanguage);
    const selectedSource = normalizeLanguage(sourceLanguage);
    const source = detectedSource || selectedSource || "Auto";
    const target = normalizeLanguage(targetLanguage) || "EN-US";
    let status = "Done: " + source + " -> " + target;

    if (result.billedCharacters > 0)
        status += " · " + result.billedCharacters + " chars";

    return status;
}

function formatDeepLError(status, responseText) {
    const detail = responseMessage(responseText);
    let message = "";

    if (status === 0) {
        message = "Network error. Check your connection.";
    } else if (status === 400) {
        message = "DeepL rejected the request.";
    } else if (status === 401 || status === 403) {
        message = "DeepL authentication failed. Check your API key.";
    } else if (status === 429) {
        message = "Too many DeepL requests. Try again later.";
    } else if (status === 456) {
        message = "DeepL quota exceeded.";
    } else if (status >= 500) {
        message = "DeepL is temporarily unavailable.";
    } else {
        message = "DeepL error: " + status;
    }

    return detail.length > 0 ? message + " " + detail : message;
}

function utf8ByteLength(text) {
    let bytes = 0;

    for (let i = 0; i < text.length; i++) {
        const code = text.charCodeAt(i);

        if (code < 0x80) {
            bytes += 1;
        } else if (code < 0x800) {
            bytes += 2;
        } else if (code >= 0xd800 && code <= 0xdbff) {
            bytes += 4;
            i += 1;
        } else {
            bytes += 3;
        }
    }

    return bytes;
}

function responseMessage(responseText) {
    if (!responseText || responseText.length === 0)
        return "";

    try {
        const response = JSON.parse(responseText);
        return response.message || response.detail || "";
    } catch (error) {
        return "";
    }
}

function formatBytes(bytes) {
    const kibibytes = bytes / 1024;
    return kibibytes.toFixed(kibibytes < 10 ? 1 : 0) + " KiB";
}
