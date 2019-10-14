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
package com.qaprosoft.zafira.dbaccess.state;

import com.qaprosoft.zafira.dbaccess.dao.mysql.management.TenancyMapper;
import com.qaprosoft.zafira.dbaccess.utils.TenancyContext;
import com.qaprosoft.zafira.dbaccess.utils.TenancyDataSourceWrapper;
import com.qaprosoft.zafira.models.db.Tenancy;
import liquibase.integration.spring.MultiTenantSpringLiquibase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ResourceLoader;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.function.Supplier;
import java.util.stream.Collectors;

/**
 * Executes liquibase on all managed schemas. Runs on application startup if enabled. In case of failure throws
 * {@link DatabaseStateManagementException} and aborts startup.
 */
public class DatabaseStateManager {

    private static final Logger LOGGER = LoggerFactory.getLogger(DatabaseStateManager.class);

    private static final String ERR_MSG_MANAGED_SCHEMAS_EMPTY = "Database state management error: managed schemas set is empty, aborting";
    private static final String ERR_MSG_UNRECOGNIZED_MANAGED_SCHEMAS = "Database state management error: not all managed schemas were recognized, aborting";
    private static final String ERR_MSG_GENERIC_STATE_MANAGEMENT_ERROR = "Database state management error: patchset execution failed";

    private static final String CHANGE_LOG_PATH = "classpath:db/changelog.yml";

    private final TenancyDataSourceWrapper tenancyAppDSWrapper;
    private final TenancyMapper tenancyMapper;
    private final boolean manageSpecificTenantsOnly;
    private final List<String> managedTenants;
    private final boolean manageSpecificLabelsOnly;
    private final String managedLabelsExpression;
    private final ResourceLoader resourceLoader;

    public DatabaseStateManager(
            TenancyMapper tenancyMapper,
            TenancyDataSourceWrapper tenancyAppDSWrapper,
            boolean manageSpecificTenantsOnly,
            TenancyList<String> managedTenants,
            boolean manageSpecificLabelsOnly,
            String manageLabelsExpression,
            ResourceLoader resourceLoader
    ) {
        this.tenancyMapper = tenancyMapper;
        this.tenancyAppDSWrapper = tenancyAppDSWrapper;
        this.manageSpecificTenantsOnly = manageSpecificTenantsOnly;
        this.managedTenants = managedTenants;
        this.manageSpecificLabelsOnly = manageSpecificLabelsOnly;
        this.managedLabelsExpression = manageLabelsExpression;
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    private void updateDatabase() {
        List<String> schemas = obtainManagedSchemas();

        MultiTenantSpringLiquibase liquibase = new MultiTenantSpringLiquibase();
        liquibase.setDataSource(tenancyAppDSWrapper.getDataSource());
        liquibase.setChangeLog(CHANGE_LOG_PATH);
        liquibase.setResourceLoader(resourceLoader);
        liquibase.setSchemas(schemas);

        if (manageSpecificLabelsOnly && managedLabelsExpression != null) {
            liquibase.setLabels(managedLabelsExpression);
        }

        executeOnAllSchemas(liquibase);
    }

    private List<String> obtainManagedSchemas() {
        List<String> allTenants = getAllTenantNames();

        if (manageSpecificTenantsOnly) {
            if (managedTenants.isEmpty()) {
                throw new DatabaseStateManagementException(ERR_MSG_MANAGED_SCHEMAS_EMPTY);
            } else if (!allTenants.containsAll(managedTenants)) {
                throw new DatabaseStateManagementException(ERR_MSG_UNRECOGNIZED_MANAGED_SCHEMAS);
            } else {
                return managedTenants;
            }
        } else {
            return allTenants;
        }
    }

    private List<String> getAllTenantNames() {
        List<Tenancy> tenancies = tenancyMapper.getAllTenancies();
        return tenancies.stream()
                        .map(Tenancy::getName)
                        .collect(Collectors.toCollection((Supplier<TenancyList<String>>) TenancyList::new));
    }

    private void executeOnAllSchemas(MultiTenantSpringLiquibase liquibase) {
        try {
            liquibase.afterPropertiesSet();
        } catch (Exception e) {
            LOGGER.error(e.getMessage(), e);
            throw new DatabaseStateManagementException(ERR_MSG_GENERIC_STATE_MANAGEMENT_ERROR, e);
        }
    }

    /**
     * Required to override ArrayList iteration mechanism in order to properly populate TenancyContext content
     * @param <E>
     */
    static class TenancyList<E> extends ArrayList<E> {

        @Override
        public Iterator<E> iterator() {
            return new Iterator<>() {

                private final Iterator<E> iterator = TenancyList.super.iterator();

                @Override
                public boolean hasNext() {
                    return iterator.hasNext();
                }

                @Override
                public E next() {
                    E entity = iterator.next();
                    TenancyContext.setTenantName(entity.toString());
                    return entity;
                }
            };
        }
    }

}
