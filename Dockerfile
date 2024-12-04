FROM drupal:11 AS builder

# Set timezone to Australia/Sydney by default
RUN ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime

# Install required packages and PHP extensions
RUN \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends libicu-dev vim mariadb-client git unzip rsync sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl

# Configure PHP settings
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini && \
    echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/docker-php-upload-limit.ini && \
    echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/docker-php-upload-limit.ini

# Set working directory
WORKDIR /app

# Copy only the necessary files for dependency installation
COPY composer.json ./

# Install Composer dependencies
RUN \
    --mount=type=cache,mode=0777,target=/root/.composer/cache \
    composer update --no-scripts --no-autoloader

# Create a symbolic link
RUN rm -rf /opt/drupal && \
    ln -sf /app/web /var/www/html

# Stage 2: Final application image
FROM builder AS site

# Set the working directory
WORKDIR /app

# Copy the rest of the application files
# COPY ./themes/custom/jwrf /app/web/themes/custom/jwrf

# Configure Composer
RUN \
    --mount=type=cache,mode=0777,target=/root/.composer/cache \
    composer install

# Adjust ownership
RUN chown -R www-data:www-data web/sites web/modules web/themes

# Set the PATH environment variable
ENV PATH=${PATH}:/app/bin:/app/vendor/bin
