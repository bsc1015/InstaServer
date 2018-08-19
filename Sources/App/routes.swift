import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let userController = UserController()
    router.get("users", use: userController.getAllUsers)
    
    let postController = PostController()
    router.get("posts", use: postController.getAllPosts)
}

public func authRoutes(_ router: Router) throws {
    let userController = UserController()
    router.post("register", use: userController.registerUser)
    router.post("login", use: userController.loginUser)
    
    let postController = PostController()
    router.post("post", use: postController.createPost)
    router.delete("post", use: postController.deletePost)
}
