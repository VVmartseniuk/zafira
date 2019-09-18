/*******************************************************************************
 * Copyright 2013-2019 Qaprosoft (http://www.qaprosoft.com).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/
package com.qaprosoft.zafira.services.exceptions;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

public class ExternalSystemException extends ApplicationException {

    @Getter
    @RequiredArgsConstructor
    @AllArgsConstructor
    public enum ExternalSystemErrorDetail implements ErrorDetail {

        ENCRYPTION_KEY_GENERATION_FAILED(2040),
        GITHUB_ACCESS_TOKEN_REQUEST_FAILED(2041),
        ELASTICSEARCH_MALFORMED_SEARCH_REQUEST(2042),
        JENKINS_JOB_REQUEST_FAILED(2043),
        JIRA_ISSUE_REQUEST_FAILED(2044),
        AMAZON_MALFORMED_URL_TO_FILE(2045),
        AMAZON_INVALID_SECURITY_TOKEN_CREDENTIALS(2046);

        private final Integer code;
        private String messageKey;

    }

    public ExternalSystemException(ExternalSystemErrorDetail errorDetail, String message) {
        super(errorDetail, message);
    }

    public ExternalSystemException(ExternalSystemErrorDetail errorDetail, String message, Throwable cause) {
        super(errorDetail, message, cause);
    }

    public ExternalSystemException(String message, Throwable cause) {
        super(message, cause);
    }

}
