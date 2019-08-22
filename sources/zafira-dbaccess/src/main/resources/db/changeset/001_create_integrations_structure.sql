-- Groups of integrations like AUTOMATION_SERVER group includes jenkins, teamcity etc.
DROP TABLE IF EXISTS INTEGRATION_GROUPS;
CREATE TABLE IF NOT EXISTS INTEGRATION_GROUPS (
                                                  ID SERIAL,
                                                  NAME VARCHAR(50) NOT NULL,
                                                  ICON_URL VARCHAR(255) NOT NULL,
                                                  MULTIPLE_ALLOWED BOOLEAN NOT NULL DEFAULT FALSE,
                                                  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  PRIMARY KEY (ID));
CREATE UNIQUE INDEX INTEGRATION_GROUPS_NAME_UNIQUE ON INTEGRATION_GROUPS (NAME);
CREATE TRIGGER update_timestamp_integration_groups BEFORE INSERT OR UPDATE ON INTEGRATION_GROUPS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

-- Sub item of integration group
DROP TABLE IF EXISTS INTEGRATION_TYPES;
CREATE TABLE IF NOT EXISTS INTEGRATION_TYPES (
                                                 ID SERIAL,
                                                 NAME VARCHAR(50) NOT NULL,
                                                 DISPLAY_NAME VARCHAR(50) NOT NULL,
                                                 ICON_URL VARCHAR(255) NOT NULL,
                                                 INTEGRATION_GROUP_ID INT NOT NULL,
                                                 MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                 CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                 PRIMARY KEY (ID),
                                                 CONSTRAINT fk_INTEGRATION_INTEGRATION_GROUP_ID1
                                                     FOREIGN KEY (INTEGRATION_GROUP_ID)
                                                         REFERENCES INTEGRATION_GROUPS (ID)
                                                         ON DELETE NO ACTION
                                                         ON UPDATE NO ACTION);
CREATE UNIQUE INDEX INTEGRATION_TYPES_NAME_UNIQUE ON INTEGRATION_TYPES (NAME);
CREATE UNIQUE INDEX INTEGRATION_TYPES_DISPLAY_NAME_UNIQUE ON INTEGRATION_TYPES (DISPLAY_NAME);
CREATE TRIGGER update_timestamp_integration_types BEFORE INSERT OR UPDATE ON INTEGRATION_TYPES FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

DROP TABLE IF EXISTS INTEGRATIONS;
CREATE TABLE IF NOT EXISTS INTEGRATIONS (
                                            ID SERIAL,
                                            NAME VARCHAR(50) NOT NULL,
                                            BACK_REFERENCE_ID VARCHAR(50) NULL,
                                            "DEFAULT" BOOLEAN NOT NULL DEFAULT FALSE,
                                            ENABLED BOOLEAN NOT NULL DEFAULT FALSE,
                                            INTEGRATION_TYPE_ID INT NOT NULL,
                                            MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            PRIMARY KEY (ID),
                                            CONSTRAINT fk_INTEGRATION_INTEGRATION_TYPE_ID1
                                                FOREIGN KEY (INTEGRATION_TYPE_ID)
                                                    REFERENCES INTEGRATION_TYPES (ID)
                                                    ON DELETE NO ACTION
                                                    ON UPDATE NO ACTION);
CREATE UNIQUE INDEX INTEGRATIONS_BACK_REFERENCE_UNIQUE ON INTEGRATIONS (BACK_REFERENCE_ID);
CREATE UNIQUE INDEX INTEGRATIONS_INTEGRATION_TYPE_ID_DEFAULT_UNIQUE ON INTEGRATIONS (INTEGRATION_TYPE_ID, "DEFAULT") WHERE "DEFAULT" = TRUE;
CREATE TRIGGER update_timestamp_integrations BEFORE INSERT OR UPDATE ON INTEGRATIONS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

DROP TABLE IF EXISTS INTEGRATION_PARAMS;
CREATE TABLE IF NOT EXISTS INTEGRATION_PARAMS (
                                                  ID SERIAL,
                                                  NAME VARCHAR(50) NOT NULL,
                                                  METADATA TEXT NULL,
                                                  DEFAULT_VALUE TEXT NULL,
                                                  MANDATORY BOOLEAN NOT NULL DEFAULT FALSE,
                                                  NEED_ENCRYPTION BOOLEAN NOT NULL DEFAULT FALSE,
                                                  INTEGRATION_TYPE_ID INT NOT NULL,
                                                  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  PRIMARY KEY (ID),
                                                  CONSTRAINT fk_INTEGRATION_PARAM_INTEGRATION_TYPE_ID1
                                                      FOREIGN KEY (INTEGRATION_TYPE_ID)
                                                          REFERENCES INTEGRATION_TYPES (ID)
                                                          ON DELETE NO ACTION
                                                          ON UPDATE NO ACTION);
CREATE UNIQUE INDEX INTEGRATION_PARAMS_NAME_INTEGRATION_TYPE_ID_UNIQUE ON INTEGRATION_PARAMS (NAME, INTEGRATION_TYPE_ID);
CREATE TRIGGER update_timestamp_integration_params BEFORE INSERT OR UPDATE ON INTEGRATION_PARAMS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

DROP TABLE IF EXISTS INTEGRATION_SETTINGS;
CREATE TABLE IF NOT EXISTS INTEGRATION_SETTINGS (
                                                    ID SERIAL,
                                                    VALUE TEXT NULL,
                                                    BINARY_DATA BYTEA NULL,
                                                    ENCRYPTED BOOLEAN NOT NULL DEFAULT FALSE,
                                                    INTEGRATION_ID INT NOT NULL,
                                                    INTEGRATION_PARAM_ID INT NOT NULL,
                                                    MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                    CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                    PRIMARY KEY (ID),
                                                    CONSTRAINT fk_INTEGRATION_SETTING_INTEGRATION_ID1
                                                        FOREIGN KEY (INTEGRATION_ID)
                                                            REFERENCES INTEGRATIONS (ID)
                                                            ON DELETE NO ACTION
                                                            ON UPDATE NO ACTION,
                                                    CONSTRAINT fk_INTEGRATION_SETTING_INTEGRATION_PARAM_ID1
                                                        FOREIGN KEY (INTEGRATION_PARAM_ID)
                                                            REFERENCES INTEGRATION_PARAMS (ID)
                                                            ON DELETE NO ACTION
                                                            ON UPDATE NO ACTION);
CREATE UNIQUE INDEX INTEGRATION_SETTINGS_INTEGRATION_PARAM_ID_INTEGRATION_ID_UNIQUE ON INTEGRATION_SETTINGS (INTEGRATION_PARAM_ID, INTEGRATION_ID);
CREATE TRIGGER update_timestamp_integration_settings BEFORE INSERT OR UPDATE ON INTEGRATION_SETTINGS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

set schema 'zafira';
DO $$

    DECLARE SETTING_ROW SETTINGS%ROWTYPE;
        DECLARE INTEGRATION_GROUP_ID INTEGRATION_GROUPS.ID%TYPE;
        DECLARE SETTING_TOOL SETTINGS.TOOL%TYPE;
        DECLARE DISPLAY_NAME_VAR SETTINGS.TOOL%TYPE;
        DECLARE INTEGRATION_TYPE_ID INTEGRATION_TYPES.ID%TYPE;
        DECLARE INTEGRATION_ID INTEGRATIONS.ID%TYPE;
        DECLARE INTEGRATION_PARAM_MANDATORY INTEGRATION_PARAMS.MANDATORY%TYPE DEFAULT FALSE;
        DECLARE INTEGRATION_SETTING_INTEGRATION_PARAM_ID INTEGRATION_PARAMS.ID%TYPE;
        DECLARE INTEGRATION_GROUP_NAME INTEGRATION_GROUPS.NAME%TYPE;
        DECLARE INTEGRATION_GROUP_MULTIPLE_ALLOWED INTEGRATION_GROUPS.MULTIPLE_ALLOWED%TYPE DEFAULT FALSE;
        DECLARE INTEGRATION_PARAM_NEED_ENCRYPTION INTEGRATION_PARAMS.NEED_ENCRYPTION%TYPE DEFAULT FALSE;

    BEGIN

        UPDATE SETTINGS SET TOOL = NULL WHERE TOOL = 'CRYPTO';

        FOR SETTING_TOOL IN SELECT DISTINCT TOOL FROM SETTINGS WHERE TOOL IS NOT NULL
            LOOP
                DISPLAY_NAME_VAR = INITCAP(SETTING_TOOL); -- Capitalize tool name to use as display name
                CASE
                    WHEN SETTING_TOOL = 'RABBITMQ' THEN
                        INTEGRATION_GROUP_NAME = 'MESSAGE_BROKER';
                    WHEN SETTING_TOOL = 'GOOGLE' OR SETTING_TOOL = 'EMAIL' OR SETTING_TOOL = 'SLACK' THEN
                        INTEGRATION_GROUP_NAME = 'MESSENGERS_REPORTING';
                    WHEN SETTING_TOOL = 'AMAZON' THEN
                        INTEGRATION_GROUP_NAME = 'STORAGE_PROVIDER';
                    WHEN SETTING_TOOL = 'LDAP' THEN
                        INTEGRATION_GROUP_NAME = 'ACCESS_MANAGEMENT';
                    WHEN SETTING_TOOL = 'SELENIUM' THEN
                        INTEGRATION_GROUP_NAME = 'TEST_AUTOMATION_TOOL';
                    WHEN SETTING_TOOL = 'JENKINS' THEN
                        INTEGRATION_GROUP_NAME = 'AUTOMATION_SERVER';
                        INTEGRATION_GROUP_MULTIPLE_ALLOWED = TRUE;
                    WHEN SETTING_TOOL = 'JIRA' OR SETTING_TOOL = 'TESTRAIL' OR SETTING_TOOL = 'QTEST' THEN
                        INTEGRATION_GROUP_NAME = 'TEST_CASE_MANAGEMENT';
                    ELSE
                        RAISE EXCEPTION 'Cannot support tool with name %', SETTING_TOOL;
                    END CASE;
                IF NOT EXISTS(SELECT ID FROM INTEGRATION_GROUPS WHERE NAME = INTEGRATION_GROUP_NAME) THEN
                    INSERT INTO INTEGRATION_GROUPS(NAME, ICON_URL, MULTIPLE_ALLOWED) VALUES (INTEGRATION_GROUP_NAME, '', INTEGRATION_GROUP_MULTIPLE_ALLOWED) RETURNING ID INTO INTEGRATION_GROUP_ID;
                END IF;
                INTEGRATION_GROUP_MULTIPLE_ALLOWED = FALSE;
                INSERT INTO INTEGRATION_TYPES(NAME, DISPLAY_NAME, ICON_URL, INTEGRATION_GROUP_ID) VALUES (SETTING_TOOL, DISPLAY_NAME_VAR, '', INTEGRATION_GROUP_ID) RETURNING ID INTO INTEGRATION_TYPE_ID;
                FOR SETTING_ROW IN SELECT * FROM SETTINGS WHERE TOOL = SETTING_TOOL ORDER BY CASE WHEN NAME = CONCAT(SETTING_TOOL, '_ENABLED') THEN 0 ELSE 1 END
                    LOOP
                        IF SETTING_ROW.NAME = 'JIRA_PASSWORD' OR SETTING_ROW.NAME = 'JENKINS_API_TOKEN_OR_PASSWORD' OR SETTING_ROW.NAME = 'EMAIL_PASSWORD' OR SETTING_ROW.NAME = 'AMAZON_SECRET_KEY' OR SETTING_ROW.NAME = 'LDAP_MANAGER_PASSWORD' OR SETTING_ROW.NAME = 'RABBITMQ_PASSWORD' OR SETTING_ROW.NAME = 'SELENIUM_PASSWORD' THEN
                            INTEGRATION_PARAM_NEED_ENCRYPTION = TRUE;
                        END IF;
                        IF SETTING_ROW.NAME = CONCAT(SETTING_TOOL, '_ENABLED') THEN
                            INSERT INTO INTEGRATIONS(NAME, INTEGRATION_TYPE_ID, "DEFAULT", ENABLED) VALUES (SETTING_TOOL, INTEGRATION_TYPE_ID, TRUE, SETTING_ROW.VALUE::boolean) RETURNING ID INTO INTEGRATION_ID;
                        ELSE
                            INTEGRATION_PARAM_MANDATORY = SETTING_ROW.NAME != 'JENKINS_FOLDER' AND SETTING_ROW.NAME != 'EMAIL_FROM_ADDRESS' AND SETTING_ROW.NAME != 'SELENIUM_USER' AND SETTING_ROW.NAME != 'SELENIUM_PASSWORD';
                            INSERT INTO INTEGRATION_PARAMS(NAME, MANDATORY, INTEGRATION_TYPE_ID, NEED_ENCRYPTION) VALUES (SETTING_ROW.NAME, INTEGRATION_PARAM_MANDATORY, INTEGRATION_TYPE_ID, INTEGRATION_PARAM_NEED_ENCRYPTION) RETURNING ID INTO INTEGRATION_SETTING_INTEGRATION_PARAM_ID;
                            INSERT INTO INTEGRATION_SETTINGS(INTEGRATION_ID, INTEGRATION_PARAM_ID, VALUE, BINARY_DATA, ENCRYPTED) VALUES(INTEGRATION_ID, INTEGRATION_SETTING_INTEGRATION_PARAM_ID, SETTING_ROW.VALUE, SETTING_ROW.FILE, SETTING_ROW.IS_ENCRYPTED);
                        END IF;
                        INTEGRATION_PARAM_NEED_ENCRYPTION = FALSE;
                    END LOOP;
                DELETE FROM SETTINGS WHERE TOOL = SETTING_TOOL;
            END LOOP;
        RETURN;

    END$$;

ALTER TABLE JOBS ADD COLUMN AUTOMATION_SERVER_ID INT NULL;
ALTER TABLE JOBS ADD CONSTRAINT fk_JOB_AUTOMATION_SERVER_ID1
    FOREIGN KEY (AUTOMATION_SERVER_ID)
        REFERENCES INTEGRATIONS (ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION;

ALTER TABLE SETTINGS DROP COLUMN TOOL;
ALTER TABLE SETTINGS DROP COLUMN IS_ENCRYPTED;
ALTER TABLE SETTINGS DROP COLUMN FILE;
