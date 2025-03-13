# Dockerized PHP Environment

A Docker-based development environment for multiple PHP projects (Laravel and WordPress) with support for different PHP and MySQL versions.

## Features

- Support for multiple PHP versions (7.4, 8.0, 8.1, 8.2)
- Support for multiple MySQL versions (5.7, 8.0)
- Nginx as a web server
- phpMyAdmin for database management
- Project isolation with separate configurations
- Easy to add new projects

## Using as a Boilerplate

You can use this repository as a boilerplate for your own projects:

1. Clone the repository:

   ```
   git clone https://github.com/yourusername/dockerized-php.git my-php-environment
   cd my-php-environment
   ```

2. Remove the existing Git history and initialize a new repository:

   ```
   rm -rf .git
   git init
   git add .
   git commit -m "Initial commit"
   ```

3. Create a new repository on GitHub or another Git hosting service

4. Add your remote repository and push:

   ```
   git remote add origin https://github.com/yourusername/your-new-repo.git
   git push -u origin main
   ```

5. Customize the environment variables in `.env` file and start using it!

## Directory Structure

```
.
├── docker-compose.yml
├── .env
├── nginx
│   ├── conf.d
│   │   ├── default.conf
│   │   ├── project-template.conf
│   │   └── wordpress-template.conf
│   └── ssl
├── php
│   ├── 7.4
│   │   └── Dockerfile
│   ├── 8.0
│   │   └── Dockerfile
│   ├── 8.1
│   │   └── Dockerfile
│   └── 8.2
│       └── Dockerfile
└── projects
    ├── project1
    ├── project2
    └── ...
```

## Getting Started

1. Clone this repository:

   ```
   git clone https://github.com/yourusername/dockerized-php.git
   cd dockerized-php
   ```

2. Configure environment variables in `.env` file (optional):

   ```
   # MySQL Settings
   MYSQL_ROOT_PASSWORD=your_root_password
   MYSQL_USER=your_db_user
   MYSQL_PASSWORD=your_db_password
   ```

3. Start the Docker containers:

   ```
   docker-compose up -d
   ```

4. Access phpMyAdmin at http://localhost:8080

## Adding a New Project

### Using the Helper Script

The easiest way to add a new project is to use the included helper script:

1. Make the script executable:

   ```
   chmod +x add-project.sh
   ```

2. For a Laravel project:

   ```
   ./add-project.sh --type laravel --name my-laravel-project --domain myapp.local --php 80 --mysql 80
   ```

3. For a WordPress project:

   ```
   ./add-project.sh --type wordpress --name my-wordpress-site --domain wpsite.local --php 74 --mysql 57
   ```

4. If you want to automatically update your hosts file (requires sudo):

   ```
   sudo ./add-project.sh --type laravel --name my-laravel-project --domain myapp.local --php 80 --mysql 80 --update-hosts
   ```

5. Follow the instructions provided by the script to complete the setup.

### Manual Setup for Laravel Projects

1. Create a new project directory in the `projects` folder:

   ```
   mkdir -p projects/my-laravel-project
   ```

2. Install Laravel in the project directory:

   ```
   docker-compose exec php80 bash -c "cd /var/www/html/my-laravel-project && composer create-project laravel/laravel ."
   ```

3. Create a Nginx configuration file for the project:

   ```
   cp nginx/conf.d/project-template.conf nginx/conf.d/my-laravel-project.conf
   ```

4. Edit the configuration file to match your project:

   ```
   # Replace these placeholders in the file
   # PROJECT_DOMAIN -> your-domain.local
   # PROJECT_NAME -> my-laravel-project
   # PHP_VERSION -> php80 (or php74, php81, php82)
   ```

5. Add the domain to your hosts file:

   ```
   sudo echo "127.0.0.1 your-domain.local" >> /etc/hosts
   ```

6. Restart Nginx:
   ```
   docker-compose restart nginx
   ```

### Manual Setup for WordPress Projects

1. Create a new project directory in the `projects` folder:

   ```
   mkdir -p projects/my-wordpress-site
   ```

2. Download WordPress:

   ```
   docker-compose exec php74 bash -c "cd /var/www/html/my-wordpress-site && curl -O https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz"
   ```

3. Create a Nginx configuration file for the project:

   ```
   cp nginx/conf.d/wordpress-template.conf nginx/conf.d/my-wordpress-site.conf
   ```

4. Edit the configuration file to match your project:

   ```
   # Replace these placeholders in the file
   # PROJECT_DOMAIN -> your-wp-domain.local
   # PROJECT_NAME -> my-wordpress-site
   # PHP_VERSION -> php74 (or php80, php81, php82)
   ```

5. Add the domain to your hosts file:

   ```
   sudo echo "127.0.0.1 your-wp-domain.local" >> /etc/hosts
   ```

6. Restart Nginx:

   ```
   docker-compose restart nginx
   ```

7. Visit your WordPress site at http://your-wp-domain.local and complete the installation.

## Creating a Database for Your Project

1. Access phpMyAdmin at http://localhost:8080
2. Log in with the MySQL credentials from your `.env` file
3. Create a new database for your project

## Connecting to MySQL from Your Project

### For Laravel Projects

Update your `.env` file in your Laravel project:

```
DB_CONNECTION=mysql
DB_HOST=mysql80  # or mysql57 depending on your needs
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=dbuser  # from .env file
DB_PASSWORD=dbpassword  # from .env file
```

### For WordPress Projects

Update your `wp-config.php` file:

```php
define('DB_NAME', 'your_database_name');
define('DB_USER', 'dbuser');  // from .env file
define('DB_PASSWORD', 'dbpassword');  // from .env file
define('DB_HOST', 'mysql57');  // or mysql80 depending on your needs
```

## Customizing PHP Versions

If you need to use a different PHP version for a specific project, simply update the `fastcgi_pass` directive in your project's Nginx configuration file:

```
fastcgi_pass php74:9000;  # For PHP 7.4
fastcgi_pass php80:9000;  # For PHP 8.0
fastcgi_pass php81:9000;  # For PHP 8.1
fastcgi_pass php82:9000;  # For PHP 8.2
```

## Adding a New PHP Version

1. Create a new directory for the PHP version:

   ```
   mkdir -p php/8.3
   ```

2. Create a Dockerfile for the new PHP version:

   ```
   # php/8.3/Dockerfile
   FROM php:8.3-fpm
   # ... (copy from an existing Dockerfile and adjust as needed)
   ```

3. Add the new service to `docker-compose.yml`:

   ```yaml
   php83:
     build:
       context: ./php/8.3
       dockerfile: Dockerfile
     container_name: php83
     volumes:
       - ./projects:/var/www/html
     networks:
       - app-network
     restart: unless-stopped
   ```

4. Update the `depends_on` section in the Nginx service to include the new PHP version.

5. Rebuild and restart the containers:
   ```
   docker-compose up -d --build
   ```

## Adding a New MySQL Version

1. Add the new service to `docker-compose.yml`:

   ```yaml
   mysql81:
     image: mysql:8.1
     container_name: mysql81
     environment:
       MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-rootpassword}
       MYSQL_USER: ${MYSQL_USER:-dbuser}
       MYSQL_PASSWORD: ${MYSQL_PASSWORD:-dbpassword}
     volumes:
       - mysql81_data:/var/lib/mysql
     networks:
       - app-network
     restart: unless-stopped
   ```

2. Add the new volume to the `volumes` section:

   ```yaml
   volumes:
     mysql57_data:
     mysql80_data:
     mysql81_data:
   ```

3. Update the `PMA_HOSTS` environment variable in the phpMyAdmin service:

   ```yaml
   phpmyadmin:
     # ...
     environment:
       PMA_HOSTS: mysql57,mysql80,mysql81
       # ...
   ```

4. Rebuild and restart the containers:
   ```
   docker-compose up -d
   ```

## Troubleshooting

### Permission Issues

If you encounter permission issues, make sure the user in the PHP containers has the correct permissions:

```
docker-compose exec php80 bash -c "chown -R www:www /var/www/html/your-project"
```

### Nginx Configuration

If your Nginx configuration is not working, check the logs:

```
docker-compose logs nginx
```

### PHP Errors

To check PHP logs:

```
docker-compose logs php80  # or php74, php81, php82
```

## License

MIT
