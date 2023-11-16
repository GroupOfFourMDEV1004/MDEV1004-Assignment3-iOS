

import UIKit

struct UpdatedResponse: Codable
{
    let lastUpdated: Int
}

class MovieCRUDViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
        
    var movies: [Books] = []
    var timer: Timer?
    var lastUpdated: Int = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.lastUpdated = Int(Date().timeIntervalSince1970 * 1000)
        
        fetchMoviesAndUpdateUI()
        startPollingForUpdates()
    }
    
    func startPollingForUpdates() {
            stopPollingForUpdates() // Stop any existing timers
            
            // Schedule a timer to check for updates every 5 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.checkForUpdates()
            }
        }
        
    func stopPollingForUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchMoviesAndUpdateUI()
    {
        fetchMovies { [weak self] movies, error in
            DispatchQueue.main.async
            {
                if let movies = movies
                {
                    if movies.isEmpty
                    {
                        // Display a message for no data
                        self?.displayErrorMessage("No movies available.")
                    } else {
                        self?.movies = movies
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
    
    func checkForUpdates()
    {
        guard let url = URL(string: "https://mdev1001-m2023-api.onrender.com/api/has-updates") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Error checking for updates: \(error)")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                
                let response = try JSONDecoder().decode(UpdatedResponse.self, from: data)
                print ("Last Updated Locally: \(self?.lastUpdated) Last Updated Remotely: \(response.lastUpdated)")
                if self!.lastUpdated < response.lastUpdated {
                    self!.lastUpdated = response.lastUpdated
                    self?.fetchMoviesAndUpdateUI()
                }
            } catch {
                print("Error decoding update response: \(error)")
            }
        }.resume()
    }
    
    func displayErrorMessage(_ message: String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchMovies(completion: @escaping ([Books]?, Error?) -> Void)
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
        guard let url = URL(string: "http://10.0.0.91:3000/api/books") else
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
                print("Decoding JSON Data...")
                let books = try JSONDecoder().decode([Books].self, from: data)
                print(books.debugDescription, "Books")
//                let movies = try JSONDecoder().decode([Movie].self, from: data)
                completion(books, nil) // Success
            } catch {
                completion(nil, error) // Handle JSON decoding error
            }
        }.resume()
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieTableViewCell
                        
                
        let movie = movies[indexPath.row]
                        
        cell.titleLabel?.text = movie.BooksName
        cell.studioLabel?.text = movie.Genre
        cell.ratingLabel?.text = "\(movie.Rating)"
                
        // Set the background color of criticsRatingLabel based on the rating
        let rating = movie.Rating
                           
        if rating > 7
        {
            cell.ratingLabel.backgroundColor = UIColor.green
            cell.ratingLabel.textColor = UIColor.black
        } else if rating > 5 {
            cell.ratingLabel.backgroundColor = UIColor.yellow
            cell.ratingLabel.textColor = UIColor.black
        } else {
            cell.ratingLabel.backgroundColor = UIColor.red
            cell.ratingLabel.textColor = UIColor.white
        }
        return cell
    }
    
    // New for ICE8
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "AddEditSegue", sender: indexPath)
    }
        
    // Swipe Left Gesture
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
        {
            if editingStyle == .delete
                {
                    let movie = movies[indexPath.row]
                    ShowDeleteConfirmationAlert(for: movie) { confirmed in
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
            if let addEditVC = segue.destination as? AddEditMovieViewController
            {
                addEditVC.movieViewController = self
                if let indexPath = sender as? IndexPath
                {
                   // Editing existing movie
                   let movie = movies[indexPath.row]
//                   addEditVC.movie = movie// To be changed
                } else {
                    // Adding new movie
                    addEditVC.movie = nil
                }
                
                // Set the callback closure to reload movies
                addEditVC.movieUpdateCallback = { [weak self] in
                    self?.fetchMovies { movies, error in
                        if let movies = movies
                        {
                            self?.movies = movies
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        else if let error = error
                        {
                            print("Failed to fetch movies: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func ShowDeleteConfirmationAlert(for movie: Books, completion: @escaping (Bool) -> Void)
    {
        let alert = UIAlertController(title: "Delete Movie", message: "Are you sure you want to delete this movie?", preferredStyle: .alert)
        
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
        let movie = movies[indexPath.row]
        
        // New for ICE10
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available.")
            return
        }

        guard let url = URL(string: "https://mdev1001-m2023-api.onrender.com/api/delete/\(movie._id)") else {
            print("Invalid URL")
            return
        }

        // Configure Request
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        // New for ICE10
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Issue Request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Failed to delete movie: \(error)")
                return
            }

            DispatchQueue.main.async {
                self?.movies.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
            
        task.resume()
    }
    
    // New for ICE 10
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
