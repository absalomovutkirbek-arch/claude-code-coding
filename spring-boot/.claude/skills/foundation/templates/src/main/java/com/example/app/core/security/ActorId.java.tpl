package com.example.app.core.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Injects the ID of the authenticated user into a controller method: {@code @ActorId long actorId}.
 *
 * <p>Controllers pass it into the DTO. Services never read the security context.
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface ActorId {
}
