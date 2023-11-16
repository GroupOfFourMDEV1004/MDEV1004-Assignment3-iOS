

import UIKit

struct UpdatedResponse: Codable
{
    let lastUpdated: Int
}

class BookCRUDViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
        
    var books: [Book] = []
    var timer: Timer?
    var lastUpdated: Int = 0
    
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.lastUpdated = Int(Date().timeIntervalSince1970 * 1000)
        
        fetchBooksAndUpdateUI()
        startPollingForUpdates()
    }
    
    func startPollingForUpdates() {
            stopPollingForUpdates() // Stop any existing timers

            // Schedule a timer to check for updates every 5 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.fetchBooksAndUpdateUI()
            }
        }

    func stopPollingForUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchBooksAndUpdateUI()
    {
        fetchBooks { [weak self] books, error in
            DispatchQueue.main.async
            {
                if let books = books
                {
                    if books.isEmpty
                    {
                        // Display a message for no data
                        self?.displayErrorMessage("No books available.")
                    } else {
                        self?.books = books
                        self?.tableView.reloadData()
                    }
                } else if let error = error {
                    if let urlError = error as? URLError, urlError.code == .timedOut
                    {
                        // Handle timeout error
                        self?.displayErrorMessage("Request timed out.")
                    } else {
                        // Handle other errors
                        self?.displayErrorMessage(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    
    func displayErrorMessage(_ message: String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchBooks(completion: @escaping ([Book]?, Error?) -> Void)
    {
        // New for ICE10: Retrieve AuthToken from UserDefaults
//        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
//        {
//            print("AuthToken not available.")
//            completion(nil, nil)
//            return
//        }
//
        // Configure the Request
        guard let url = URL(string: "https://assigment3-mdev1004-api.onrender.com/api/books") else
        {
            completion(nil, nil) // Handle URL error
            return
        }
        
        // New for ICE 10
        var request = URLRequest(url: url)
            request.httpMethod = "GET"
//            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Issue Request
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Network Error")
                completion(nil, error) // Handle network error
                return
            }

            guard let data = data else {
                print("Empty Response")
                completion(nil, nil) // Handle empty response
                return
            }

            // Response
            do {
                let books = try JSONDecoder().decode([Book].self, from: data)
//                print(books.debugDescription, "Books")
                completion(books, nil) // Success
            } catch {
                completion(nil, error) // Handle JSON decoding error
            }
        }.resume()
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! BookTableViewCell
                        
                
        let book = books[indexPath.row]
                        
        cell.titleLabel?.text = book.BooksName
        cell.studioLabel?.text = book.Genre
        cell.ratingLabel?.text = "\(book.Rating)"
                
        // Set the background color of criticsRatingLabel based on the rating
        let rating = book.Rating
                           
        if rating > 4
        {
            cell.ratingLabel.backgroundColor = UIColor.green
            cell.ratingLabel.textColor = UIColor.black
        } else if rating > 3 {
            cell.ratingLabel.backgroundColor = UIColor.yellow
            cell.ratingLabel.textColor = UIColor.black
        } else {
            cell.ratingLabel.backgroundColor = UIColor.red
            cell.ratingLabel.textColor = UIColor.white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "AddEditSegue", sender: indexPath)
    }
        
    // Swipe Left Gesture
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
        {
            if editingStyle == .delete
                {
                    let book = books[indexPath.row]
                    ShowDeleteConfirmationAlert(for: book) { confirmed in
                        if confirmed
                        {
                            self.deleteMovie(at: indexPath)
                        }
                    }
                }
        }
    
    @IBAction func AddButton_Pressed(_ sender: UIButton)
    {
        performSegue(withIdentifier: "AddEditSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "AddEditSegue"
        {
            if let addEditVC = segue.destination as? AddEditBookViewController
            {
                addEditVC.bookViewController = self
                if let indexPath = sender as? IndexPath
                {
                   // Editing existing book
                   let book = books[indexPath.row]
                   addEditVC.book = book
                } else {
                    // Adding new book
                    addEditVC.book = nil
                }
                
                // Set the callback closure to reload books
                addEditVC.bookUpdateCallback = { [weak self] in
                    self?.fetchBooks { books, error in
                        if let books = books
                        {
                            self?.books = books
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        else if let error = error
                        {
                            print("Failed to fetch books: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func ShowDeleteConfirmationAlert(for book: Book, completion: @escaping (Bool) -> Void)
    {
        let alert = UIAlertController(title: "Delete Book", message: "Are you sure you want to delete this book?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteMovie(at indexPath: IndexPath)
    {
        let book = books[indexPath.row]
        if let id = book._id {
            // New for ICE10
            //        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
            //        {
            //            print("AuthToken not available.")
            //            return
            //        }
            
            guard let url = URL(string: "https://assigment3-mdev1004-api.onrender.com/api/books/\(id)") else {
                print("Invalid URL")
                return
            }
            
            // Configure Request
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            //        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            // Issue Request
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("Failed to delete book: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.books.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
            
            task.resume()
        }
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton)
    {
        // Remove the token from UserDefaults or local storage to indicate logout
        UserDefaults.standard.removeObject(forKey: "AuthToken")
        
        // Clear the username and password in the LoginViewController
        APILoginViewController.shared?.ClearLoginTextFields()
        
        // unwind
        performSegue(withIdentifier: "unwindToLogin", sender: self)
    }

}
