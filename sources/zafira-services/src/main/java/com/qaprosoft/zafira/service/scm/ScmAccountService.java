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
package com.qaprosoft.zafira.service.scm;

import com.qaprosoft.zafira.dbaccess.dao.mysql.application.ScmAccountMapper;
import com.qaprosoft.zafira.models.db.ScmAccount;
import com.qaprosoft.zafira.models.dto.scm.Repository;
import com.qaprosoft.zafira.service.CryptoService;
import com.qaprosoft.zafira.service.exception.ForbiddenOperationException;
import com.qaprosoft.zafira.service.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static com.qaprosoft.zafira.service.exception.ResourceNotFoundException.ResourceNotFoundErrorDetail.SCM_ACCOUNT_NOT_FOUND;

@Service
public class ScmAccountService {

    private static final String ERR_MSG_SCM_ACCOUNT_NOT_FOUND = "SCM account with id %s can not be found";
    private static final String ERR_MSG_SCM_ACCOUNT_NOT_FOUND_FOR_REPO = "SCM account for repo %s can not be found";

    private final ScmAccountMapper scmAccountMapper;
    private final GitHubService gitHubService;
    private final CryptoService cryptoService;

    public ScmAccountService(ScmAccountMapper scmAccountMapper, GitHubService gitHubService, CryptoService cryptoService) {
        this.scmAccountMapper = scmAccountMapper;
        this.gitHubService = gitHubService;
        this.cryptoService = cryptoService;
    }

    @Transactional(rollbackFor = Exception.class)
    public ScmAccount createScmAccount(ScmAccount scmAccount) {
        if (scmAccount.getAccessToken() != null && !scmAccount.getAccessToken().isBlank()) {
            String encryptedToken = cryptoService.encrypt(scmAccount.getAccessToken());
            scmAccount.setAccessToken(encryptedToken);
        }
        scmAccountMapper.createScmAccount(scmAccount);
        return scmAccount;
    }

    @Transactional(readOnly = true)
    public ScmAccount getScmAccountById(Long id) {
        ScmAccount scmAccount = scmAccountMapper.getScmAccountById(id);
        if (scmAccount == null) {
            throw new ResourceNotFoundException(SCM_ACCOUNT_NOT_FOUND, ERR_MSG_SCM_ACCOUNT_NOT_FOUND, id);
        }
        return scmAccount;
    }

    @Transactional(readOnly = true)
    public ScmAccount getScmAccountByRepo(String repo) {
        ScmAccount scmAccount = scmAccountMapper.getScmAccountByRepo(repo);
        if (scmAccount == null) {
            throw new ResourceNotFoundException(SCM_ACCOUNT_NOT_FOUND, ERR_MSG_SCM_ACCOUNT_NOT_FOUND_FOR_REPO, repo);
        }
        return scmAccount;
    }

    @Transactional(readOnly = true)
    public List<ScmAccount> getAllScmAccounts() {
        return scmAccountMapper.getAllScmAccounts();
    }

    @Transactional(rollbackFor = Exception.class)
    public ScmAccount updateScmAccount(ScmAccount scmAccount) {
        scmAccountMapper.updateScmAccount(scmAccount);
        return scmAccount;
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteScmAccountById(Long id) {
        scmAccountMapper.deleteScmAccountById(id);
    }

    @Transactional(readOnly = true)
    public String getDefaultBranch(Long id) {
        ScmAccount scmAccount = getScmAccountById(id);
        if(scmAccount == null) {
            throw new ForbiddenOperationException("Unable to retrieve scm account default branch name");
        }
        Repository repository = gitHubService.getRepository(scmAccount);
        if(repository == null) {
            throw new ForbiddenOperationException("Unable to retrieve scm account default branch name");
        }
        return repository.getDefaultBranch();
    }

    public void reEncryptTokens() {
        List<ScmAccount> scmAccounts = getAllScmAccounts();
        scmAccounts.forEach(scmAccount -> {
            String token = scmAccount.getAccessToken();
            String encryptedToken = cryptoService.encrypt(token);
            scmAccount.setAccessToken(encryptedToken);
            updateScmAccount(scmAccount);
        });
    }

}