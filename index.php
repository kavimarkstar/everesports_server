<?php
// PHP equivalent of the Express server
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
$PORT = 3000;
$MONGO_URI = 'mongodb://kavimark:kavimark@192.168.43.227:27017/';
$DB_NAME = 'everesports';

// Constants
$UPLOAD_DIR = 'uploads';
$PROFILE_DIR = $UPLOAD_DIR . '/profiles';
$COVER_DIR = $UPLOAD_DIR . '/coverphotos';
$POSTS_DIR = $UPLOAD_DIR . '/posts';
$STORIES_DIR = $UPLOAD_DIR . '/stories';

// Create necessary directories
$directories = [$UPLOAD_DIR, $PROFILE_DIR, $COVER_DIR, $POSTS_DIR, $STORIES_DIR];
foreach ($directories as $dir) {
    if (!file_exists($dir)) {
        mkdir($dir, 0777, true);
    }
}

// MongoDB connection
function connectMongoDB() {
    global $MONGO_URI, $DB_NAME;
    try {
        $manager = new MongoDB\Driver\Manager($MONGO_URI . $DB_NAME);
        return $manager;
    } catch (Exception $e) {
        error_log("MongoDB connection failed: " . $e->getMessage());
        return null;
    }
}

// Helper functions
function getLocalIP() {
    $interfaces = array();
    $output = shell_exec('ipconfig');
    preg_match_all('/IPv4 Address.*?:\s*(\d+\.\d+\.\d+\.\d+)/', $output, $matches);
    foreach ($matches[1] as $ip) {
        if ($ip !== '127.0.0.1' && $ip !== '0.0.0.0') {
            return $ip;
        }
    }
    return 'localhost';
}

function deleteFile($filePath) {
    $fullPath = __DIR__ . '/' . ltrim($filePath, '/');
    if (file_exists($fullPath)) {
        if (unlink($fullPath)) {
            error_log("🗑️ Deleted: $filePath");
        } else {
            error_log("❌ Error deleting $filePath");
        }
    }
}

function generateUniqueId() {
    return uniqid() . '_' . rand(100000000, 999999999);
}

function uploadFile($file, $destination, $allowedTypes = null) {
    if (!isset($file) || $file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => 'No file uploaded or upload error'];
    }

    if ($allowedTypes && !in_array($file['type'], $allowedTypes)) {
        return ['success' => false, 'error' => 'File type not allowed'];
    }

    $filename = time() . '-' . $file['name'];
    $filepath = $destination . '/' . $filename;

    if (!file_exists($destination)) {
        mkdir($destination, 0777, true);
    }

    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        return ['success' => true, 'filename' => $filename, 'filepath' => $filepath];
    } else {
        return ['success' => false, 'error' => 'Failed to move uploaded file'];
    }
}

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Route handling
switch ($method) {
    case 'GET':
        handleGetRequest($path);
        break;
    case 'POST':
        handlePostRequest($path);
        break;
    case 'PUT':
        handlePutRequest($path);
        break;
    case 'DELETE':
        handleDeleteRequest($path);
        break;
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
}

function handleGetRequest($path) {
    switch ($path) {
        case '/api/health':
            echo json_encode([
                'status' => 'ok',
                'timestamp' => date('c'),
                'server' => 'EverEsports Server',
                'version' => '1.0.0',
                'mongodb' => 'connected',
                'uptime' => time()
            ]);
            break;
            
        case '/api/stories':
            getStories();
            break;
            
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Endpoint not found']);
    }
}

function handlePostRequest($path) {
    switch ($path) {
        case '/uploads':
            uploadGeneral();
            break;
            
        case '/upload/weapon':
            uploadWeapon();
            break;
            
        case '/upload/maps':
            uploadMaps();
            break;
            
        case '/upload/tournament':
            uploadTournament();
            break;
            
        case '/uploads/banner':
            uploadBanner();
            break;
            
        case '/upload':
            uploadProfile();
            break;
            
        case '/upload-cover':
            uploadCover();
            break;
            
        case '/upload-post-media':
            uploadPostMedia();
            break;
            
        case '/create-post':
            createPost();
            break;
            
        case '/delete-image':
            deleteProfileImage();
            break;
            
        case '/delete-cover':
            deleteCoverImage();
            break;
            
        case '/api/stories':
            createStory();
            break;
            
        case '/api/shutdown':
            echo json_encode(['message' => 'Server shutting down gracefully']);
            exit(0);
            break;
            
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Endpoint not found']);
    }
}

function handlePutRequest($path) {
    if (preg_match('/^\/update\/(.+)$/', $path, $matches)) {
        updateGame($matches[1]);
    } elseif (preg_match('/^\/tournament-preset\/(.+)$/', $path, $matches)) {
        updateTournamentPreset($matches[1]);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
    }
}

function handleDeleteRequest($path) {
    if ($path === '/delete') {
        deleteFile();
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
    }
}

// Upload functions
function uploadGeneral() {
    global $UPLOAD_DIR;
    
    $result = uploadFile($_FILES['file'], $UPLOAD_DIR);
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/' . $result['filename'];
    $gameName = $_POST['gameName'] ?? null;
    
    if ($gameName) {
        $manager = connectMongoDB();
        if ($manager) {
            $bulk = new MongoDB\Driver\BulkWrite();
            $bulk->insert(['gameName' => $gameName, 'imagePath' => $imagePath]);
            $manager->executeBulkWrite($DB_NAME . '.games', $bulk);
        }
    }
    
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadWeapon() {
    global $UPLOAD_DIR;
    
    $result = uploadFile($_FILES['file'], $UPLOAD_DIR . '/weapon');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/weapon/' . $result['filename'];
    $gameName = $_POST['gameName'] ?? null;
    
    if ($gameName) {
        $manager = connectMongoDB();
        if ($manager) {
            $bulk = new MongoDB\Driver\BulkWrite();
            $bulk->insert(['gameName' => $gameName, 'imagePath' => $imagePath]);
            $manager->executeBulkWrite($DB_NAME . '.games', $bulk);
        }
    }
    
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadMaps() {
    global $UPLOAD_DIR;
    
    $result = uploadFile($_FILES['file'], $UPLOAD_DIR . '/maps');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/maps/' . $result['filename'];
    $gameName = $_POST['gameName'] ?? null;
    
    if ($gameName) {
        $manager = connectMongoDB();
        if ($manager) {
            $bulk = new MongoDB\Driver\BulkWrite();
            $bulk->insert(['gameName' => $gameName, 'imagePath' => $imagePath]);
            $manager->executeBulkWrite($DB_NAME . '.games', $bulk);
        }
    }
    
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadTournament() {
    global $UPLOAD_DIR;
    
    $result = uploadFile($_FILES['file'], $UPLOAD_DIR . '/tournament');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/tournament/' . $result['filename'];
    $gameName = $_POST['gameName'] ?? null;
    
    if ($gameName) {
        $manager = connectMongoDB();
        if ($manager) {
            $bulk = new MongoDB\Driver\BulkWrite();
            $bulk->insert(['gameName' => $gameName, 'imagePath' => $imagePath]);
            $manager->executeBulkWrite($DB_NAME . '.games', $bulk);
        }
    }
    
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadBanner() {
    global $UPLOAD_DIR;
    
    $result = uploadFile($_FILES['file'], $UPLOAD_DIR . '/banner');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/banner/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadProfile() {
    global $PROFILE_DIR;
    
    if (!isset($_POST['userId'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId']);
        return;
    }
    
    $result = uploadFile($_FILES['file'], $PROFILE_DIR);
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/profiles/' . $result['filename'];
    $userId = $_POST['userId'];
    $oldImagePath = $_POST['oldImagePath'] ?? null;
    
    if ($oldImagePath) {
        deleteFile($oldImagePath);
    }
    
    $manager = connectMongoDB();
    if ($manager) {
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->update(
            ['userId' => $userId],
            ['$set' => ['profileImageUrl' => $imagePath]],
            ['multi' => false]
        );
        $manager->executeBulkWrite($DB_NAME . '.users', $bulk);
    }
    
    echo json_encode(['imageUrl' => $imagePath, 'updated' => true]);
}

function uploadCover() {
    global $COVER_DIR;
    
    if (!isset($_POST['userId'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId']);
        return;
    }
    
    $result = uploadFile($_FILES['file'], $COVER_DIR);
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/coverphotos/' . $result['filename'];
    $userId = $_POST['userId'];
    $oldCoverPath = $_POST['oldCoverPath'] ?? null;
    
    if ($oldCoverPath) {
        deleteFile($oldCoverPath);
    }
    
    $manager = connectMongoDB();
    if ($manager) {
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->update(
            ['userId' => $userId],
            ['$set' => ['coverImageUrl' => $imagePath]],
            ['multi' => false]
        );
        $manager->executeBulkWrite($DB_NAME . '.users', $bulk);
    }
    
    echo json_encode(['imageUrl' => $imagePath, 'updated' => true]);
}

function uploadPostMedia() {
    global $POSTS_DIR;
    
    if (!isset($_POST['userId'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId']);
        return;
    }
    
    $filePaths = [];
    foreach ($_FILES['files']['tmp_name'] as $key => $tmp_name) {
        $file = [
            'name' => $_FILES['files']['name'][$key],
            'type' => $_FILES['files']['type'][$key],
            'tmp_name' => $tmp_name,
            'error' => $_FILES['files']['error'][$key],
            'size' => $_FILES['files']['size'][$key]
        ];
        
        $type = strpos($file['type'], 'image') === 0 ? 'images' : 'videos';
        $destination = $POSTS_DIR . '/' . $type;
        
        $result = uploadFile($file, $destination);
        if ($result['success']) {
            $filePaths[] = 'uploads/posts/' . $type . '/' . $result['filename'];
        }
    }
    
    echo json_encode([
        'success' => true,
        'filePaths' => $filePaths,
        'message' => 'Files uploaded successfully'
    ]);
}

function createPost() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['userId']) || !isset($input['title']) || 
        !isset($input['description']) || !isset($input['filePaths'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        return;
    }
    
    $manager = connectMongoDB();
    if (!$manager) {
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed']);
        return;
    }
    
    $post = [
        'userId' => $input['userId'],
        'title' => $input['title'],
        'description' => $input['description'],
        'files' => $input['filePaths'],
        'mentions' => $input['mentions'] ?? [],
        'hashtags' => array_map(function($tag) {
            return strtolower(ltrim($tag, '#'));
        }, $input['hashtags'] ?? []),
        'createdAt' => new MongoDB\BSON\UTCDateTime(),
        'updatedAt' => new MongoDB\BSON\UTCDateTime()
    ];
    
    $bulk = new MongoDB\Driver\BulkWrite();
    $result = $bulk->insert($post);
    $manager->executeBulkWrite($DB_NAME . '.posts', $bulk);
    
    echo json_encode([
        'success' => true,
        'postId' => (string)$result,
        'message' => 'Post created successfully'
    ]);
}

function deleteProfileImage() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['userId']) || !isset($input['imagePath'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId or imagePath']);
        return;
    }
    
    deleteFile($input['imagePath']);
    
    $manager = connectMongoDB();
    if ($manager) {
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->update(
            ['userId' => $input['userId']],
            ['$set' => ['profileImageUrl' => '']],
            ['multi' => false]
        );
        $manager->executeBulkWrite($DB_NAME . '.users', $bulk);
    }
    
    echo json_encode(['message' => 'Profile image deleted', 'updated' => true]);
}

function deleteCoverImage() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['userId']) || !isset($input['imagePath'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId or imagePath']);
        return;
    }
    
    deleteFile($input['imagePath']);
    
    $manager = connectMongoDB();
    if ($manager) {
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->update(
            ['userId' => $input['userId']],
            ['$set' => ['coverImageUrl' => '']],
            ['multi' => false]
        );
        $manager->executeBulkWrite($DB_NAME . '.users', $bulk);
    }
    
    echo json_encode(['message' => 'Cover photo deleted', 'updated' => true]);
}

function createStory() {
    if (!isset($_POST['userId']) || !isset($_POST['description'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        return;
    }
    
    $result = uploadFile($_FILES['image'], $STORIES_DIR, ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']);
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/stories/' . $result['filename'];
    
    $manager = connectMongoDB();
    if ($manager) {
        $story = [
            'userId' => $_POST['userId'],
            'description' => $_POST['description'],
            'imagePath' => $imagePath,
            'view' => false,
            'createdAt' => new MongoDB\BSON\UTCDateTime()
        ];
        
        $bulk = new MongoDB\Driver\BulkWrite();
        $result = $bulk->insert($story);
        $manager->executeBulkWrite($DB_NAME . '.stories', $bulk);
        
        echo json_encode([
            'success' => true,
            'data' => [
                'id' => (string)$result,
                'userId' => $_POST['userId'],
                'description' => $_POST['description'],
                'imageUrl' => '/' . $imagePath,
                'view' => false,
                'createdAt' => $story['createdAt']->toDateTime()
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error']);
    }
}

function getStories() {
    $manager = connectMongoDB();
    if (!$manager) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error']);
        return;
    }
    
    $query = new MongoDB\Driver\Query([], ['sort' => ['createdAt' => -1], 'limit' => 20]);
    $cursor = $manager->executeQuery($DB_NAME . '.stories', $query);
    
    $stories = [];
    foreach ($cursor as $story) {
        $stories[] = [
            'id' => (string)$story->_id,
            'userId' => $story->userId,
            'description' => $story->description,
            'imageUrl' => '/' . $story->imagePath,
            'view' => $story->view ?? false,
            'createdAt' => $story->createdAt->toDateTime()
        ];
    }
    
    echo json_encode(['success' => true, 'data' => $stories]);
}

function updateGame($id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $manager = connectMongoDB();
    if (!$manager) {
        http_response_code(500);
        echo json_encode(['message' => 'Database error']);
        return;
    }
    
    $bulk = new MongoDB\Driver\BulkWrite();
    $bulk->update(
        ['_id' => new MongoDB\BSON\ObjectId($id)],
        ['$set' => $input],
        ['multi' => false]
    );
    
    $result = $manager->executeBulkWrite($DB_NAME . '.games', $bulk);
    
    if ($result->getModifiedCount() > 0) {
        echo json_encode(['message' => 'Game updated successfully']);
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'Record not found']);
    }
}

function updateTournamentPreset($id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $manager = connectMongoDB();
    if (!$manager) {
        http_response_code(500);
        echo json_encode(['message' => 'Database update error']);
        return;
    }
    
    $bulk = new MongoDB\Driver\BulkWrite();
    $bulk->update(
        ['_id' => new MongoDB\BSON\ObjectId($id)],
        ['$set' => $input],
        ['multi' => false]
    );
    
    $result = $manager->executeBulkWrite($DB_NAME . '.tournamentpresets', $bulk);
    
    if ($result->getMatchedCount() === 0) {
        http_response_code(404);
        echo json_encode(['message' => 'Preset not found']);
    } else {
        echo json_encode([
            'message' => 'Preset updated successfully',
            'updated' => $result->getModifiedCount() > 0
        ]);
    }
}

function deleteFile() {
    $relativePath = $_GET['path'] ?? null;
    if (!$relativePath) {
        http_response_code(400);
        echo json_encode(['message' => 'No path specified']);
        return;
    }
    
    $fullPath = __DIR__ . '/' . ltrim($relativePath, '/');
    
    if (file_exists($fullPath)) {
        if (unlink($fullPath)) {
            echo json_encode(['message' => 'File deleted']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Error deleting file']);
        }
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'File not found']);
    }
}

// Start server (this would typically be handled by a web server like Apache or Nginx)
if (php_sapi_name() === 'cli') {
    echo "✅ PHP Server running at: http://" . getLocalIP() . ":$PORT\n";
    echo "Press Ctrl+C to stop\n";
}
?> 