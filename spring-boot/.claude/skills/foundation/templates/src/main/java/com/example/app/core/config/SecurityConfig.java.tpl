package com.example.app.core.config;

import com.example.app.core.security.ApiSecurityErrorHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Stateless API security. The authentication mechanism itself is the project's choice
 * (recommended: JWT resource server) and is added where marked.
 */
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain apiSecurity(HttpSecurity http, ApiSecurityErrorHandler errors) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(handling -> handling.authenticationEntryPoint(errors).accessDeniedHandler(errors))
                .authorizeHttpRequests(requests -> requests
                        // Public endpoints are listed here explicitly, e.g. .requestMatchers("/api/v1/auth/**").permitAll()
                        .anyRequest().authenticated());
        // Authentication mechanism, e.g.: http.oauth2ResourceServer(server -> server.jwt(Customizer.withDefaults()));

        return http.build();
    }
}
