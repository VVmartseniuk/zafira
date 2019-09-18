package com.qaprosoft.zafira.services.exceptions;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

public class ProcessingException extends ApplicationException {

    @Getter
    @RequiredArgsConstructor
    @AllArgsConstructor
    public enum ProcessingErrorDetail implements ErrorDetail {

        INVALID_FREEMARKER_TEMPLATE(2100),
        INVALID_WIDGET_TEMPLATE(2101),
        //belongs to the other type?
        FILE_UPLOAD_FAILED(2102),
        CONFIG_XML_MALFORMED(2103);

        private final Integer code;
        private String messageKey;

    }

    public ProcessingException(ProcessingErrorDetail errorDetail, String message) {
        super(errorDetail, message);
    }

    public ProcessingException(ProcessingErrorDetail errorDetail, String message, Throwable cause) {
        super(errorDetail, message, cause);
    }
}
