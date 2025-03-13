#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
UPDATE_HOSTS=false
USE_COMPOSER_DIRECTLY=false

# Function to display help
show_help() {
  echo -e "${BLUE}Usage:${NC} $0 [options]"
  echo ""
  echo "This script helps you set up a new PHP project in the dockerized environment."
  echo ""
  echo -e "${BLUE}Options:${NC}"
  echo "  -t, --type        Project type (laravel or wordpress)"
  echo "  -n, --name        Project name (folder name)"
  echo "  -d, --domain      Domain name for the project"
  echo "  -p, --php         PHP version to use (74, 80, 81, 82, 83, 84)"
  echo "  -m, --mysql       MySQL version to use (57, 80)"
  echo "  -u, --update-hosts Update hosts file (requires sudo)"
  echo "  -c, --use-composer Use composer directly for Laravel projects"
  echo "  -h, --help        Show this help message"
  echo ""
  echo -e "${BLUE}Example:${NC}"
  echo "  $0 --type laravel --name my-app --domain myapp.local --php 81 --mysql 80"
  echo "  $0 --type wordpress --name blog --domain blog.local --php 74 --mysql 57 --update-hosts"
  echo "  $0 --type laravel --name my-app --domain myapp.local --php 83 --mysql 80 --use-composer"
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -t|--type)
      PROJECT_TYPE="$2"
      shift
      shift
      ;;
    -n|--name)
      PROJECT_NAME="$2"
      shift
      shift
      ;;
    -d|--domain)
      DOMAIN="$2"
      shift
      shift
      ;;
    -p|--php)
      PHP_VERSION="$2"
      shift
      shift
      ;;
    -m|--mysql)
      MYSQL_VERSION="$2"
      shift
      shift
      ;;
    -u|--update-hosts)
      UPDATE_HOSTS=true
      shift
      ;;
    -c|--use-composer)
      USE_COMPOSER_DIRECTLY=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      ;;
  esac
done

# Validate inputs
if [ -z "$PROJECT_TYPE" ] || [ -z "$PROJECT_NAME" ] || [ -z "$DOMAIN" ] || [ -z "$PHP_VERSION" ] || [ -z "$MYSQL_VERSION" ]; then
  echo -e "${RED}Error: Missing required parameters${NC}"
  show_help
fi

# Validate project type
if [ "$PROJECT_TYPE" != "laravel" ] && [ "$PROJECT_TYPE" != "wordpress" ]; then
  echo -e "${RED}Error: Project type must be 'laravel' or 'wordpress'${NC}"
  exit 1
fi

# Validate PHP version
if [ "$PHP_VERSION" != "74" ] && [ "$PHP_VERSION" != "80" ] && [ "$PHP_VERSION" != "81" ] && [ "$PHP_VERSION" != "82" ] && [ "$PHP_VERSION" != "83" ] && [ "$PHP_VERSION" != "84" ]; then
  echo -e "${RED}Error: PHP version must be '74', '80', '81', '82', '83', or '84'${NC}"
  exit 1
fi

# Validate MySQL version
if [ "$MYSQL_VERSION" != "57" ] && [ "$MYSQL_VERSION" != "80" ]; then
  echo -e "${RED}Error: MySQL version must be '57' or '80'${NC}"
  exit 1
fi

# Create project directory
echo -e "${BLUE}Creating project directory...${NC}"
mkdir -p "projects/$PROJECT_NAME"
echo -e "${GREEN}✓ Project directory created${NC}"

# Create Nginx configuration
echo -e "${BLUE}Creating Nginx configuration...${NC}"
if [ "$PROJECT_TYPE" == "laravel" ]; then
  cp nginx/conf.d/project-template.conf "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PROJECT_DOMAIN/$DOMAIN/g" "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PHP_VERSION/php$PHP_VERSION/g" "nginx/conf.d/$PROJECT_NAME.conf"
else
  cp nginx/conf.d/wordpress-template.conf "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PROJECT_DOMAIN/$DOMAIN/g" "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" "nginx/conf.d/$PROJECT_NAME.conf"
  sed -i "s/PHP_VERSION/php$PHP_VERSION/g" "nginx/conf.d/$PROJECT_NAME.conf"
fi
echo -e "${GREEN}✓ Nginx configuration created${NC}"

# Add domain to hosts file if requested
if [ "$UPDATE_HOSTS" = true ]; then
  echo -e "${BLUE}Updating hosts file...${NC}"
  
  # Check if script is run with sudo when trying to update hosts
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Updating hosts file requires sudo privileges.${NC}"
    echo -e "${BLUE}Please run the following command manually:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 $DOMAIN\" >> /etc/hosts'"
  else
    if grep -q "$DOMAIN" /etc/hosts; then
      echo -e "${BLUE}Domain already exists in hosts file${NC}"
    else
      echo "127.0.0.1 $DOMAIN" >> /etc/hosts
      echo -e "${GREEN}✓ Domain added to hosts file${NC}"
    fi
  fi
else
  echo -e "${BLUE}Skipping hosts file update.${NC}"
  echo -e "${BLUE}To manually add the domain to your hosts file, run:${NC}"
  echo -e "sudo sh -c 'echo \"127.0.0.1 $DOMAIN\" >> /etc/hosts'"
fi

# Function to update Laravel .env file
update_laravel_env() {
  local env_file="projects/$PROJECT_NAME/.env"
  
  if [ -f "$env_file" ]; then
    echo -e "${BLUE}Updating Laravel .env file with Docker environment settings...${NC}"
    
    # Create a backup of the original .env file
    cp "$env_file" "${env_file}.backup"
    
    # Update database settings
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" "$env_file"
    sed -i "s/DB_HOST=.*/DB_HOST=mysql$MYSQL_VERSION/" "$env_file"
    sed -i "s/DB_PORT=.*/DB_PORT=3306/" "$env_file"
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${PROJECT_NAME//-/_}/" "$env_file"
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=dbuser/" "$env_file"
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=dbpassword/" "$env_file"
    
    # Update APP_URL
    sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|" "$env_file"
    
    echo -e "${GREEN}✓ Laravel .env file updated${NC}"
    echo -e "${BLUE}A backup of the original .env file has been saved as ${env_file}.backup${NC}"
  else
    echo -e "${RED}Warning: Laravel .env file not found. Skipping environment configuration.${NC}"
  fi
}

# Install project
echo -e "${BLUE}Setting up $PROJECT_TYPE project...${NC}"
if [ "$PROJECT_TYPE" == "laravel" ]; then
  echo -e "${BLUE}Installing Laravel...${NC}"
  
  if [ "$USE_COMPOSER_DIRECTLY" = true ]; then
    # Check if composer is installed
    if ! command -v composer &> /dev/null; then
      echo -e "${RED}Error: Composer is not installed or not in your PATH.${NC}"
      echo -e "${BLUE}Please install Composer or use the Docker container method instead.${NC}"
      echo -e "${BLUE}For Docker container method, run the script without the --use-composer flag.${NC}"
    else
      echo -e "${BLUE}Using Composer directly to create Laravel project...${NC}"
      echo -e "${BLUE}Running: composer create-project laravel/laravel projects/$PROJECT_NAME${NC}"
      
      # Navigate to the parent directory and run composer
      (cd projects && composer create-project laravel/laravel $PROJECT_NAME)
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Laravel project created successfully${NC}"
        
        # Update the Laravel .env file
        update_laravel_env
      else
        echo -e "${RED}Error: Failed to create Laravel project with Composer.${NC}"
        echo -e "${BLUE}You can try the Docker container method instead:${NC}"
        echo -e "docker-compose exec php$PHP_VERSION bash -c \"cd /var/www/html/$PROJECT_NAME && composer create-project laravel/laravel .\""
      fi
    fi
  else
    echo -e "${BLUE}Run the following command to install Laravel using Docker:${NC}"
    echo -e "docker-compose exec php$PHP_VERSION bash -c \"cd /var/www/html/$PROJECT_NAME && composer create-project laravel/laravel .\""
    echo -e "${BLUE}After installation, you should update the .env file with these database settings:${NC}"
    echo -e "DB_CONNECTION=mysql"
    echo -e "DB_HOST=mysql$MYSQL_VERSION"
    echo -e "DB_PORT=3306"
    echo -e "DB_DATABASE=${PROJECT_NAME//-/_}"
    echo -e "DB_USERNAME=dbuser"
    echo -e "DB_PASSWORD=dbpassword"
    echo -e "APP_URL=http://$DOMAIN"
    
    echo -e "${BLUE}Or run this command to automatically update the .env file:${NC}"
    echo -e "docker-compose exec php$PHP_VERSION bash -c \"cd /var/www/html/$PROJECT_NAME && sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && sed -i 's/DB_HOST=.*/DB_HOST=mysql$MYSQL_VERSION/' .env && sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && sed -i 's/DB_DATABASE=.*/DB_DATABASE=${PROJECT_NAME//-/_}/' .env && sed -i 's/DB_USERNAME=.*/DB_USERNAME=dbuser/' .env && sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=dbpassword/' .env && sed -i 's|APP_URL=.*|APP_URL=http://$DOMAIN|' .env\""
  fi
else
  echo -e "${BLUE}Installing WordPress...${NC}"
  echo -e "${BLUE}Run the following command to install WordPress:${NC}"
  echo -e "docker-compose exec php$PHP_VERSION bash -c \"cd /var/www/html/$PROJECT_NAME && curl -O https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz\""
  echo -e "${BLUE}After installation, create a wp-config.php file with these database settings:${NC}"
  echo -e "define('DB_NAME', '${PROJECT_NAME//-/_}');"
  echo -e "define('DB_USER', 'dbuser');"
  echo -e "define('DB_PASSWORD', 'dbpassword');"
  echo -e "define('DB_HOST', 'mysql$MYSQL_VERSION');"
fi

# Restart Nginx
echo -e "${BLUE}Restarting Nginx...${NC}"
echo -e "${BLUE}Run the following command to restart Nginx:${NC}"
echo -e "docker-compose restart nginx"

echo -e "${GREEN}✓ Project setup complete!${NC}"
echo -e "${BLUE}Your project will be available at:${NC} http://$DOMAIN"
echo -e "${BLUE}Don't forget to create a database named${NC} ${PROJECT_NAME//-/_} ${BLUE}using phpMyAdmin at${NC} http://localhost:8080" 