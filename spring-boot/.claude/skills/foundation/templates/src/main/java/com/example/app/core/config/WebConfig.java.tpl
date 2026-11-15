package com.example.app.core.config;

import com.example.app.core.security.ActorIdArgumentResolver;
import java.util.List;
import java.util.Locale;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.core.convert.converter.ConverterFactory;
import org.springframework.format.FormatterRegistry;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web layer wiring of the shared kernel.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(new ActorIdArgumentResolver());
    }

    /** Query and path parameters accept enums in lowercase, as the JSON API writes them. */
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverterFactory(new LowercaseEnumConverterFactory());
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static final class LowercaseEnumConverterFactory implements ConverterFactory<String, Enum> {

        @Override
        public <T extends Enum> Converter<String, T> getConverter(Class<T> targetType) {
            return source -> source.isBlank()
                    ? null
                    : (T) Enum.valueOf(targetType, source.trim().toUpperCase(Locale.ROOT));
        }
    }
}
