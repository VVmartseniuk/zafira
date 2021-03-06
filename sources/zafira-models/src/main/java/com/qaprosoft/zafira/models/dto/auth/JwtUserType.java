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
package com.qaprosoft.zafira.models.dto.auth;

import com.qaprosoft.zafira.models.db.Group;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.stream.Collectors;

/**
 * All user information handled by the JWT token
 */
public class JwtUserType implements UserDetails {
    private static final long serialVersionUID = 2105145272583220476L;

    private long id;

    private String username;

    private String password;

    private List<GrantedAuthority> authorities;

    public JwtUserType(long id, String username, List<Group> groups) {
        this.id = id;
        this.username = username;
        this.authorities = groups.stream().map(group -> new UserGrantedAuthority(group.getRole().name(), group.getPermissionNames()))
                .collect(Collectors.toList());
        // TODO: removed when default role populated for all
        if (this.authorities.isEmpty()) {
            this.authorities.add(new UserGrantedAuthority("ROLE_USER", new HashSet<>()));
        }
    }

    public JwtUserType(long id, String username, String password, List<Group> groups) {
        this(id, username, groups);
        this.password = password;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    public long getId() {
        return id;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}