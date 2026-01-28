
# emails.swift documentation
——————————————————————————

## func sendEmail(to email: String, subject: String, content: String)

Purpose: Send email notifications

Parameters:
email - the recipient
subject - subject of email
content - body of email

Usage:
When the function sendEmail() is called with the appropriate parameters, an email will be sent to the specified user. 

Designer Notes:
Serializes email data and makes a request to Sendgrid.
For testing purposes, it is recommended to change the ‘email’ parameter to a test email YOU own to avoid emailing 3rd parties. Includes error handling printed to console. Does not support @ucsc.edu emails. Ability to send images not included.

——————————————————————————
## func sendLoginAttemptEmail(to email: String)

Purpose: Modifiable email template

Parameters:
email - the recipient

Usage:
A call to sendLoginAttemptEmail() will send a basic email.

Designer Notes: Configured to trigger when a new user is registered to the database upon clicking register button.

——————————————————————————
## func sendRegistrationEmail(to email: String, _ fullname: String)

Purpose: Modifiable email template

Parameters:
email - the recipient
fullname - owner of email address 

Usage: A call to sendRegistrationEmail() will send a basic email.

Designer Notes:
Configured to trigger whenever the login button is pressed. Consider removing this in final version.
