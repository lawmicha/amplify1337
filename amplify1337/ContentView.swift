//
//  ContentView.swift
//  amplify1337
//
//  Created by Law, Michael on 9/24/21.
//

import SwiftUI
import Amplify
import AmplifyPlugins
import Combine

class ContentViewModel: ObservableObject {
    
    @Published var commentId: String? = nil
    @Published var comment: Comment? = nil
    @Published var user: User? = nil
    @Published var userComment: UserComment? = nil
    
    var commentSink: AnyCancellable?
    var userSink: AnyCancellable?
    var userCommentSink: AnyCancellable?
    
    func saveComment() {
        let comment = Comment(title: "title", content: "content")
        Amplify.DataStore.save(comment) { result in
            switch result {
            case .success(let comment):
                print("Saved comment")
                DispatchQueue.main.async {
                    self.comment = comment
                }
            case .failure(let error):
                print("Error \(error.errorDescription)")
            }
        }
    
    }
    
    func saveUser() {
        let user = User(username: "michael")
        
        Amplify.DataStore.save(user) { result in
            switch result {
            case .success(let user):
                print("Saved user")
                DispatchQueue.main.async {
                    self.user = user
                }
            case .failure(let error):
                print("Error \(error.errorDescription)")
            }
        }
    }
    
    func saveUserComment() {
        guard let user = self.user, let comment = self.comment else {
            print("Cannot save without a user and comment")
            return
        }
        let userComment = UserComment(liked: true, user: user, comment: comment)
        
        Amplify.DataStore.save(userComment) { result in
            switch result {
            case .success(let userComment):
                print("Saved userComment")
                DispatchQueue.main.async {
                    self.userComment = userComment
                }
            case .failure(let error):
                print("Error \(error.errorDescription)")
            }
        }
    }
    
    func queryUserAndGetComments() {
        guard let user = self.user else {
            print("Missing user to query")
            return
        }
        Amplify.DataStore.query(User.self, byId: user.id) { result in
            switch result {
            case .success(let user):
                guard let user = user, let comments = user.comments else {
                    print("Failed to get user back")
                    return
                }
                print("Comment count \(comments.count)")
                
                for comment in comments {
                    print(comment)
                }
            case .failure(let error):
                print("Error \(error.errorDescription)")
            }
        }
    }
    
    func queryCommentAndGetUsers() {
        guard let comment = self.comment else {
            print("Missing comment to query")
            return
        }
        Amplify.DataStore.query(Comment.self, byId: comment.id) { result in
            switch result {
            case .success(let comment):
                guard let comment = comment, let users = comment.users else {
                    print("Failed to get comment back")
                    return
                }
                print("User count \(users.count)")
                
                for user in users {
                    print(user)
                }
            case .failure(let error):
                print("Error \(error.errorDescription)")
            }
        }
    }
    
    func signIn() {
        // this user was created and confirmed via AWS CLI, see README.md for more details
        Amplify.Auth.signIn(username: "michael", password: "password") { result in
            switch result {
            case .success(let result):
                print(result)
            case .failure(let error):
                print("\(error)")
            }
        }
    }
    
    func signOut() {
        Amplify.Auth.signOut { result in
            switch result {
            case .success:
                print("signed out")
            case .failure(let error):
                print("\(error)")
            }
        }
    }
    
    func subscribe() {
        self.commentSink = Amplify.DataStore.publisher(for: Comment.self).sink { completion in
            
        } receiveValue: { mutationEvent in
            print("MutationEvent Comment \(mutationEvent.modelId) version \(mutationEvent.version)")
        }
        
        self.userSink = Amplify.DataStore.publisher(for: User.self).sink { completion in
            
        } receiveValue: { mutationEvent in
            print("MutationEvent User \(mutationEvent.modelId) version \(mutationEvent.version)")
        }
        
        self.userCommentSink = Amplify.DataStore.publisher(for: UserComment.self).sink { completion in
            
        } receiveValue: { mutationEvent in
            print("MutationEvent UserComment \(mutationEvent.modelId) version \(mutationEvent.version)")
        }

    }
}
struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    
    var body: some View {
        VStack {
            VStack {
                Text("Latest Comment:")
                Text(self.vm.comment?.id ?? "None")
                Text("Latest User:")
                Text(self.vm.user?.id ?? "None")
                Text("Latest UserComment:")
                Text(self.vm.userComment?.id ?? "None")
            }
            VStack {
                Button("Sign in", action: self.vm.signIn)
                Button("Sign out", action: self.vm.signOut)
                Button("save comment", action: self.vm.saveComment)
                Button("save user", action: self.vm.saveUser)
                Button("Save user comment", action: self.vm.saveUserComment)
                
                Button("Query for user and get comments", action: self.vm.queryUserAndGetComments)
                Button("Query for comment and get user", action: self.vm.queryCommentAndGetUsers)
            }
            
        }.onAppear(perform: self.vm.subscribe)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
