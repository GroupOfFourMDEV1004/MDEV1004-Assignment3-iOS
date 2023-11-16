

import UIKit

class APIRegisterViewController: UIViewController
{
    
    // Connect TextFields
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    @IBAction func registerButton_Pressed(_ sender: UIButton)
    {
        guard let username = usernameTextField.text,
              let emailAddress = emailTextField.text,
              let firstName = firstNameTextField.text,
              let lastName = lastNameTextField.text,
              let password = passwordTextField.text else
        {
                    print("Please enter all the required fields.")
                    return
        }
                
        let urlString = "http://10.0.0.91:3000/api/users/register"
        guard let url = URL(string: urlString) else
        {
            print("Invalid URL.")
            return
        }
        
        // Configure Request
                
        let parameters = [
            "username": username,
            "emailAddress": emailAddress,
            "firstName": firstName,
            "lastName": lastName,
            "password": password
        ]
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Failed to encode parameters: \(error)")
            return
        }
        
        // Issue the Request
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error
            {
                print("Failed to send request: \(error)")
                return
            }
            
            guard let data = data else
            {
                print("Empty response.")
                return
            }
            
            // Response
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let username = json?["username"] as? String
                {
                    print("User registered successfully.")
                    
                    DispatchQueue.main.async
                    {
                        // Clear the username and password in the LoginViewController
                        APILoginViewController.shared?.ClearLoginTextFields()
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    let errorMessage = json?["msg"] as? String ?? "Unknown error"
                    print("Registration failed: \(errorMessage)")
                }
            } catch {
                print("Error decoding JSON response: \(error)")
            }
        }
        
        task.resume()
    }
    
    @IBAction func CancelButton_Pressed(_ sender: UIButton)
    {
        // Clear the username and password in the LoginViewController
        APILoginViewController.shared?.ClearLoginTextFields()
        dismiss(animated: true, completion: nil)
    }
}
