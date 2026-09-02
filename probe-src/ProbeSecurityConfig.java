/*
 * Licensed under the GPL License. You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
 *
 * THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE.
 */
package psiprobe;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.security.NoTypePermission;
import com.thoughtworks.xstream.security.NullPermission;
import com.thoughtworks.xstream.security.PrimitiveTypePermission;

import java.io.IOException;
import java.util.Collection;
import java.util.TreeMap;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.DefaultSecurityFilterChain;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.logout.LogoutFilter;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextHolderFilter;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.savedrequest.HttpSessionRequestCache;
import org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.web.filter.GenericFilterBean;

/**
 * No-auth version of ProbeSecurityConfig.
 *
 * <p>This replaces the original security config to allow open access when no password is set.
 * All J2EE pre-authentication, role-based access control, and FilterSecurityInterceptor
 * are removed. A passthrough filter is used instead, allowing all requests through.</p>
 */
@Configuration
@EnableWebSecurity
public class ProbeSecurityConfig {

  /**
   * Gets the filter chain proxy.
   * Uses a passthrough filter instead of FilterSecurityInterceptor.
   *
   * @return the filter chain proxy
   */
  @Bean(name = "filterChainProxy")
  public FilterChainProxy getFilterChainProxy() {
    SecurityFilterChain chain = new DefaultSecurityFilterChain(new AntPathRequestMatcher("/**"),
        securityContextHolderFilter(securityContextRepository()),
        getLogoutFilter(),
        new GenericFilterBean() {
          @Override
          public void doFilter(ServletRequest request, ServletResponse response,
              FilterChain filterChain) throws IOException, ServletException {
            filterChain.doFilter(request, response);
          }
        });
    return new FilterChainProxy(chain);
  }

  /**
   * Security context holder filter.
   *
   * @param repository the repository
   * @return the security context holder filter
   */
  @Bean
  public SecurityContextHolderFilter securityContextHolderFilter(
      SecurityContextRepository repository) {
    return new SecurityContextHolderFilter(repository);
  }

  /**
   * Security context repository.
   *
   * @return the security context repository
   */
  @Bean
  public SecurityContextRepository securityContextRepository() {
    return new HttpSessionSecurityContextRepository();
  }

  /**
   * Gets the logout filter.
   *
   * @return the logout filter
   */
  @Bean(name = "logoutFilter")
  public LogoutFilter getLogoutFilter() {
    return new LogoutFilter("/", getSecurityContextLogoutHandler());
  }

  /**
   * Gets the security context logout handler.
   *
   * @return the security context logout handler
   */
  @Bean(name = "securityContextLogoutHandler")
  public SecurityContextLogoutHandler getSecurityContextLogoutHandler() {
    return new SecurityContextLogoutHandler();
  }

  /**
   * Gets the security context holder aware request filter.
   *
   * @return the security context holder aware request filter
   */
  @Bean(name = "securityContextHolderAwareRequestFilter")
  public SecurityContextHolderAwareRequestFilter getSecurityContextHolderAwareRequestFilter() {
    return new SecurityContextHolderAwareRequestFilter();
  }

  /**
   * Gets the http session request cache.
   *
   * @return the http session request cache
   */
  @Bean(name = "httpSessionRequestCache")
  public HttpSessionRequestCache getHttpSessionRequestCache() {
    HttpSessionRequestCache cache = new HttpSessionRequestCache();
    cache.setCreateSessionAllowed(false);
    return cache;
  }

  /**
   * Gets the xstream.
   *
   * @return the xstream
   */
  @Bean(name = "xstream")
  public XStream getXstream() {
    XStream xstream = new XStream();
    // clear out existing permissions and start a whitelist
    xstream.addPermission(NoTypePermission.NONE);
    // allow some basics
    xstream.addPermission(NullPermission.NULL);
    xstream.addPermission(PrimitiveTypePermission.PRIMITIVES);
    xstream.allowTypeHierarchy(Collection.class);
    xstream.allowTypeHierarchy(String.class);
    xstream.allowTypeHierarchy(TreeMap.class);
    xstream.allowTypesByWildcard(new String[] {"org.jfree.data.xy.**", "psiprobe.controllers.**",
        "psiprobe.model.**", "psiprobe.model.stats.**"});
    return xstream;
  }

}
