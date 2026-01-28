//
//  Emails.swift
//  Service Center
//
//  Created by Alan Lam on 1/22/25.
//

import SwiftUI
import Foundation

func sendLoginAttemptEmail(to email: String) {
    // Get the current date and time
    let currentDate = Date()
    
    // Format the date to a readable string (e.g., "January 22, 2025 10:45 AM")
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    let formattedDate = dateFormatter.string(from: currentDate)
    
    // Create the subject and content
    let subject = "Login Attempt"
    let content = "A login attempt was made with the email: \(email) on \(formattedDate)."
    
    sendEmail(to: email, subject: subject, content: content)
}

func sendRegistrationEmail(to email: String, _ fullname: String) {
    // Create the subject and content
    let subject = "Welcome to Service Center!"
    let content = """
    Hi \(fullname),

    Welcome to Service Center! We're excited to have you join our community.

    We're here to help if you need anything!

    Best regards,
    Service Center Team
    """
    
    sendEmail(to: email, subject: subject, content: content)
}

func sendJobRequestAcceptedEmail(to email: String, _ fullname: String, _ jobTitle: String) {
    let subject = "You have been accepted for \(jobTitle)!"
    let content = """
    Dear \(fullname),
    
    Your request for \(jobTitle) has been accepted!
    
    Time to get to work!
    
    Best regards,
    Service Center Team
    """
    sendEmail(to: email, subject: subject, content: content)
}

func sendJobCompletedEmail(to email: String, _ fullname: String, _ jobTitle: String, _ acceptedUserFullname: String) {
    let subject = "Your post for \"\(jobTitle)\" is complete!"
    let content = """
    Dear \(fullname),
    
    \(acceptedUserFullname) has marked your job as complete.
    Give them a rating!
    
    Best regards,
    Service Center Team
    """
    sendEmail(to: email, subject: subject, content: content)
}

func sendEmail(to email: String, subject: String, content: String) {
    guard let apiKey = Secrets.sendGridAPIKey else {
        print("Missing SendGrid API key — set it in Secrets.swift (see Secrets.swift.example)")
        return
    }

    // URL for the SendGrid email API endpoint
    guard let url = URL(string: "https://api.sendgrid.com/v3/mail/send") else {
        print("Invalid URL")
        return
    }
    
    // Create the headers for the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // Create the body of the request
    let emailData: [String: Any] = [
        "personalizations": [
            [
                "to": [
                    ["email": email] // Change to desired email recipient
                                     // replace email with a gmail surrounded by quotes
                ],
                "subject": subject
            ]
        ],
        "from": [
            "email": "servicecenterorgcontact@gmail.com" // Sender's email
        ],
        "content": [
            [
                "type": "text/plain",
                "value": content // Email body content
            ]
        ]
    ]
    
    do {
        // Convert the email data dictionary to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: emailData, options: [])
        request.httpBody = jsonData
        
        // Perform the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send email: \(error.localizedDescription)")
                return
            }
            print("Attempting to send email to: \(email)")
            
            // Check the HTTP response status code
            if let response = response as? HTTPURLResponse, response.statusCode == 202 {
                print("Email sent successfully!")
            } else {
                print("Failed to send email. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        }.resume()
    } catch {
        print("Error serializing JSON data: \(error.localizedDescription)")
    }
}
