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
 *******************************************************************************/
package com.qaprosoft.zafira.web.documented;

import com.qaprosoft.zafira.models.dto.errors.ErrorResponse;
import com.qaprosoft.zafira.models.entity.integration.IntegrationInfo;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiImplicitParams;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;

import java.util.List;
import java.util.Map;

@Api("Integrations info API")
public interface IntegrationInfoDocumentedController {

    @ApiOperation(
            value = "Retrieves all integration connections info grouped by integration types",
            notes = "Returns all core integration attributes and groups them by integration type names",
            nickname = "getIntegrationsInfo",
            httpMethod = "GET",
            response = Map.class
    )
    @ApiImplicitParams({
            @ApiImplicitParam(name = "Authorization", paramType = "header", required = true, value = "The auth token (Bearer)")
    })
    @ApiResponses({
            @ApiResponse(code = 200, message = "Returns found integrations", response = Map.class)
    })
    Map<String, Map<String, List<IntegrationInfo>>> getIntegrationsInfo();

    @ApiOperation(
            value = "Retrieves integration connections info by id",
            notes = "Returns the core attributes of the integration by its id and the group it belongs to",
            nickname = "getIntegrationsInfoById",
            httpMethod = "GET",
            response = IntegrationInfo.class
    )
    @ApiImplicitParams({
            @ApiImplicitParam(name = "Authorization", paramType = "header", required = true, value = "The auth token (Bearer)"),
            @ApiImplicitParam(name = "id", paramType = "path", dataTypeClass = Long.class, required = true, value = "The integration id"),
            @ApiImplicitParam(name = "groupName", paramType = "query", dataType = "string", required = true, value = "The integration group name")
    })
    @ApiResponses({
            @ApiResponse(code = 200, message = "Returns the found integration", response = IntegrationInfo.class),
            @ApiResponse(code = 404, message = "Indicates that the integration cannot be found, and its information cannot be obtained", response = ErrorResponse.class)
    })
    IntegrationInfo getIntegrationsInfoById(Long id, String groupName);

}
