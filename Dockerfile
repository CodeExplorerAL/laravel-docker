FROM php:8.2-apache

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
  libpng-dev \
  libjpeg-dev \
  libfreetype6-dev \
  zip \
  unzip

# 清理 apt 緩存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 安裝 PHP 擴展
RUN docker-php-ext-install pdo pdo_mysql
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 設置 Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 啟用 Apache 模塊
RUN a2enmod rewrite

# 複製專案文件
COPY . /var/www/html

# 設置工作目錄
WORKDIR /var/www/html

# 安裝 PHP 依賴
RUN composer install --no-interaction --no-plugins --no-scripts

# 設置權限
RUN chown -R www-data:www-data /var/www/html \
  && chmod -R 755 /var/www/html/storage

# 開放端口
EXPOSE 80

# 啟動 Apache
CMD ["apache2-foreground"]