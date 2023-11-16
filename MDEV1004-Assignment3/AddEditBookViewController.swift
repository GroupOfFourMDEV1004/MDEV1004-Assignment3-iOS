

import UIKit

class AddEditBookViewController: UIViewController
{
    // UI References
    @IBOutlet weak var AddEditTitleLabel: UILabel!
    @IBOutlet weak var UpdateButton: UIButton!
    
    // Book Fields
    
    @IBOutlet weak var bookNameTextField: UITextField!
    @IBOutlet weak var ISBNTextField: UITextField!
    @IBOutlet weak var genresTextField: UITextField!
    @IBOutlet weak var authorsTextField: UITextField!
    @IBOutlet weak var ratingTextField: UITextField!
    
    var book: Book?
    var bookViewController: BookCRUDViewController? // Updated from BookViewController
    var bookUpdateCallback: (() -> Void)? // Updated from BookViewController
    var isEdit = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let book = book
        {
            // Editing existing book
            bookNameTextField.text = book.BooksName
            ISBNTextField.text = book.ISBN
            genresTextField.text = book.Genre
            authorsTextField.text = book.Author
            ratingTextField.text = "\(book.Rating)"
            
            AddEditTitleLabel.text = "Edit Book"
            UpdateButton.setTitle("Update", for: .normal)
        }
        else
        {
            AddEditTitleLabel.text = "Add Book"
            UpdateButton.setTitle("Add", for: .normal)
        }
    }
    
    @IBAction func CancelButton_Pressed(_ sender: UIButton)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func UpdateButton_Pressed(_ sender: UIButton)
    {
        
        // Retrieve AuthToken
//        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
//        {
//            print("AuthToken not available.")
//            return
//        }
        
        // Configure Request
        let urlString: String
        let requestType: String
        
        if let book = book, let id = book._id {
            requestType = "PUT"
            urlString = "http://10.0.0.91:3000/api/books/\(id)"
            isEdit = true
        } else {
            requestType = "POST"
            urlString = "http://10.0.0.91:3000/api/books"
            var isEdit = false
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        // Explicitly mention the types of the data
        let id: String = book?._id ?? UUID().uuidString
        let name: String = bookNameTextField.text ?? ""
        let isbn: String = ISBNTextField.text ?? ""
        let authors: String = authorsTextField.text ?? ""
        let genres: String = genresTextField.text ?? ""
        let rating: Float = Float(ratingTextField.text ?? "") ?? 0
        var parameter : [String : Any]
        // Create the book with the parsed data
        
        if isEdit == true {
             parameter = [
                "_id": id,
                "BooksName": name,
                "ISBN": isbn,
                "Rating": rating,
                "Author": authors,
                "Genre": genres // Wrap the value in an array
            ]
        } else {
            parameter = [
                "BooksName": name,
                "ISBN": isbn,
                "Rating": rating,
                "Author": authors,
                "Genre": genres // Wrap the value in an array
            ]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // New for ICE 10: Add the AuthToken to the request headers
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        // Request
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameter, options: [])
        } catch {
            print("Failed to encode book: \(error)")
            return
        }
        
        // Response
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error
            {
                print("Failed to send request: \(error)")
                return
            }
            
            DispatchQueue.main.async
            {
                self?.dismiss(animated: true)
                {
                    self?.bookUpdateCallback?()
                }
            }
        }
        
        task.resume()
    }
}
