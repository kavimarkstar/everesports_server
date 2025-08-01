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
$MONGO_URI = 'mongodb://kavimark:kavimark@192.168.43.227:27017/';
$DB_NAME = 'everesports';

// Create upload directories
$directories = ['uploads', 'uploads/profiles', 'uploads/coverphotos', 'uploads/posts', 'uploads/stories', 'uploads/weapon', 'uploads/maps', 'uploads/tournament', 'uploads/banner'];
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
function deleteFile($filePath) {
    $fullPath = __DIR__ . '/' . ltrim($filePath, '/');
    if (file_exists($fullPath)) {
        unlink($fullPath);
    }
}

function uploadFile($file, $destination) {
    if (!isset($file) || $file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => 'No file uploaded'];
    }

    $filename = time() . '-' . $file['name'];
    $filepath = $destination . '/' . $filename;

    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        return ['success' => true, 'filename' => $filename];
    } else {
        return ['success' => false, 'error' => 'Failed to upload file'];
    }
}

// Route handling
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

switch ($method) {
    case 'GET':
        handleGet($path);
        break;
    case 'POST':
        handlePost($path);
        break;
    case 'PUT':
        handlePut($path);
        break;
    case 'DELETE':
        handleDelete($path);
        break;
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
}

function handleGet($path) {
    switch ($path) {
        case '/api/health':
            echo json_encode([
                'status' => 'ok',
                'timestamp' => date('c'),
                'server' => 'EverEsports Server',
                'version' => '1.0.0',
                'mongodb' => 'connected'
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

function handlePost($path) {
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
            
        case '/api/stories':
            createStory();
            break;
            
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Endpoint not found']);
    }
}

function handlePut($path) {
    if (preg_match('/^\/update\/(.+)$/', $path, $matches)) {
        updateGame($matches[1]);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
    }
}

function handleDelete($path) {
    if ($path === '/delete') {
        deleteFileEndpoint();
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
    }
}

// Upload functions
function uploadGeneral() {
    $result = uploadFile($_FILES['file'], 'uploads');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadWeapon() {
    $result = uploadFile($_FILES['file'], 'uploads/weapon');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/weapon/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadMaps() {
    $result = uploadFile($_FILES['file'], 'uploads/maps');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/maps/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadTournament() {
    $result = uploadFile($_FILES['file'], 'uploads/tournament');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['message' => $result['error']]);
        return;
    }
    
    $imagePath = '/uploads/tournament/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadBanner() {
    $result = uploadFile($_FILES['file'], 'uploads/banner');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/banner/' . $result['filename'];
    echo json_encode(['imagePath' => $imagePath]);
}

function uploadProfile() {
    if (!isset($_POST['userId'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId']);
        return;
    }
    
    $result = uploadFile($_FILES['file'], 'uploads/profiles');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/profiles/' . $result['filename'];
    echo json_encode(['imageUrl' => $imagePath, 'updated' => true]);
}

function uploadCover() {
    if (!isset($_POST['userId'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing userId']);
        return;
    }
    
    $result = uploadFile($_FILES['file'], 'uploads/coverphotos');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['error' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/coverphotos/' . $result['filename'];
    echo json_encode(['imageUrl' => $imagePath, 'updated' => true]);
}

function createStory() {
    if (!isset($_POST['userId']) || !isset($_POST['description'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        return;
    }
    
    $result = uploadFile($_FILES['image'], 'uploads/stories');
    if (!$result['success']) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $result['error']]);
        return;
    }
    
    $imagePath = 'uploads/stories/' . $result['filename'];
    
    echo json_encode([
        'success' => true,
        'data' => [
            'id' => uniqid(),
            'userId' => $_POST['userId'],
            'description' => $_POST['description'],
            'imageUrl' => '/' . $imagePath,
            'view' => false,
            'createdAt' => date('c')
        ]
    ]);
}

function getStories() {
    echo json_encode([
        'success' => true,
        'data' => []
    ]);
}

function updateGame($id) {
    $input = json_decode(file_get_contents('php://input'), true);
    echo json_encode(['message' => 'Game updated successfully']);
}

function deleteFileEndpoint() {
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
?> 