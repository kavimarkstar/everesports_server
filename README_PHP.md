# EverEsports PHP Server

This is the PHP equivalent of the Express.js server for the EverEsports application.

## Prerequisites

- PHP 7.4 or higher
- MongoDB PHP extension
- Composer
- Apache/Nginx web server (or use PHP built-in server)

## Installation

1. **Install PHP MongoDB extension:**
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install php-mongodb
   
   # On Windows with XAMPP/WAMP
   # Enable the mongodb extension in php.ini
   ```

2. **Install Composer dependencies:**
   ```bash
   composer install
   ```

3. **Configure MongoDB connection:**
   Edit `server.php` and update the MongoDB connection string:
   ```php
   $MONGO_URI = 'mongodb://username:password@host:port/';
   ```

## Running the Server

### Option 1: Using PHP Built-in Server
```bash
php -S localhost:3000 server.php
```

### Option 2: Using Apache/Nginx
1. Place files in your web server directory
2. Ensure `.htaccess` is enabled
3. Access via your web server URL

## API Endpoints

The PHP server provides the same endpoints as the Express server:

### File Uploads
- `POST /uploads` - General file upload
- `POST /upload/weapon` - Weapon image upload
- `POST /upload/maps` - Map image upload
- `POST /upload/tournament` - Tournament image upload
- `POST /uploads/banner` - Banner image upload
- `POST /upload` - Profile image upload
- `POST /upload-cover` - Cover photo upload

### Stories
- `POST /api/stories` - Create a new story
- `GET /api/stories` - Get all stories

### Health & Management
- `GET /api/health` - Server health check
- `DELETE /delete?path=filepath` - Delete a file

### Updates
- `PUT /update/:id` - Update a game record
- `PUT /tournament-preset/:id` - Update tournament preset

## File Structure

```
everesports_server/
├── server.php          # Main PHP server file
├── .htaccess          # URL rewriting rules
├── composer.json      # PHP dependencies
├── uploads/           # Upload directories
│   ├── profiles/
│   ├── coverphotos/
│   ├── posts/
│   ├── stories/
│   ├── weapon/
│   ├── maps/
│   ├── tournament/
│   └── banner/
└── README_PHP.md     # This file
```

## Key Differences from Express Version

1. **No middleware system** - PHP handles requests differently
2. **File uploads** - Uses PHP's `$_FILES` superglobal
3. **Database operations** - Uses MongoDB PHP driver instead of Mongoose
4. **Error handling** - PHP error handling instead of Express middleware
5. **Static file serving** - Handled by web server or `.htaccess`

## Configuration

### MongoDB Connection
Update the connection string in `server.php`:
```php
$MONGO_URI = 'mongodb://username:password@host:port/';
$DB_NAME = 'everesports';
```

### Upload Limits
Configure PHP upload limits in `php.ini`:
```ini
upload_max_filesize = 100M
post_max_size = 100M
max_execution_time = 300
memory_limit = 256M
```

## Troubleshooting

### Common Issues

1. **MongoDB connection failed**
   - Check if MongoDB PHP extension is installed
   - Verify connection string
   - Ensure MongoDB server is running

2. **File upload errors**
   - Check upload directory permissions
   - Verify PHP upload limits
   - Ensure directories exist

3. **404 errors**
   - Check `.htaccess` configuration
   - Ensure mod_rewrite is enabled
   - Verify file paths

### Debug Mode
Add this to the top of `server.php` for debugging:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

## Migration from Express

To migrate from the Express server:

1. **Update client URLs** - Point to PHP server instead of Node.js
2. **File uploads** - Use `$_FILES` instead of `multer`
3. **Database queries** - Update to MongoDB PHP driver syntax
4. **Error handling** - Adapt to PHP error handling patterns

## Performance

- PHP is generally faster for simple operations
- MongoDB PHP driver is optimized for performance
- File uploads are handled efficiently by PHP
- Consider using OPcache for production

## Security

- Input validation is handled in PHP
- File upload security is built-in
- CORS headers are properly set
- SQL injection is not applicable (MongoDB) 