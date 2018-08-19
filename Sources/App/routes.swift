import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
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
}
