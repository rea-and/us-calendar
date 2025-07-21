import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import os

def send_event_notification(event_data, action="created"):
    """
    Send email notification to Andrea when Angel creates or updates an event
    
    Args:
        event_data (dict): Event data including title, description, dates, etc.
        action (str): Either "created" or "updated"
    """
    
    # Email configuration
    sender_email = "noreply@carlevato.net"  # You'll need to configure this
    receiver_email = "andrea.carlevato@gmail.com"
    
    # Email content
    subject = f"Calendar Update: {event_data['title']} {action}"
    
    # Format dates for better readability
    start_date = datetime.fromisoformat(event_data['start_date'].replace('Z', '+00:00'))
    end_date = datetime.fromisoformat(event_data['end_date'].replace('Z', '+00:00'))
    
    # Format dates in a readable way
    start_str = start_date.strftime("%B %d, %Y at %I:%M %p")
    end_str = end_date.strftime("%B %d, %Y at %I:%M %p")
    
    # Create email body
    body = f"""
Hi Andrea! 👋

Angel has {action} an event in your shared calendar:

📅 **Event Details:**
• Title: {event_data['title']}
• Type: {event_data['event_type'].title()}
• Start: {start_str}
• End: {end_str}
• Shared: {'Yes' if event_data.get('applies_to_both') else 'No'}

"""
    
    if event_data.get('description'):
        body += f"📝 **Description:**\n{event_data['description']}\n\n"
    
    body += f"""
You can view and manage this event in your calendar at: https://carlevato.net

Best regards,
Your Calendar System 🤖

---
This is an automated notification. Please do not reply to this email.
"""
    
    # Create message
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = receiver_email
    message["Subject"] = subject
    
    # Add body to email
    message.attach(MIMEText(body, "plain"))
    
    try:
        # For now, we'll use a simple SMTP configuration
        # In production, you'd want to use a proper email service like SendGrid, Mailgun, etc.
        
        # Create SMTP session
        context = ssl.create_default_context()
        
        # For development/testing, we'll just log the email
        # In production, you'd send it via SMTP
        print(f"📧 EMAIL NOTIFICATION (would send to {receiver_email}):")
        print(f"Subject: {subject}")
        print(f"Body:\n{body}")
        print("-" * 50)
        
        # TODO: Uncomment and configure for production
        # with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        #     server.login(sender_email, "your-app-password")
        #     server.sendmail(sender_email, receiver_email, message.as_string())
        
        return True
        
    except Exception as e:
        print(f"❌ Error sending email notification: {e}")
        return False

def should_send_notification(event_data, user_name):
    """
    Determine if we should send a notification based on the event and user
    
    Args:
        event_data (dict): Event data
        user_name (str): Name of the user who created/updated the event
    
    Returns:
        bool: True if notification should be sent
    """
    # Only send notifications when Angel creates or updates events
    return user_name.lower() == "angel" 