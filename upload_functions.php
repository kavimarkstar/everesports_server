<?php
// Upload functions for the PHP server

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
?> 