import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import os
import logging
import threading

# Set up logging
logger = logging.getLogger(__name__)

def send_event_notification(event_data, action="created"):
    """Send email notification asynchronously"""
    # Start email sending in a separate thread to avoid blocking the UI
    email_thread = threading.Thread(
        target=_send_email_sync,
        args=(event_data, action),
        daemon=True
    )
    email_thread.start()
    logger.info(f"📧 Email notification queued for async sending")
    return True

def _send_email_sync(event_data, action="created"):
    """Synchronous email sending function (runs in background thread)"""
    try:
        sender_email = "your-gmail@gmail.com"  # Replace with your Gmail address
        receiver_email = "andrea.carlevato@gmail.com"
        
        # Create message
        message = MIMEMultipart()
        message["From"] = sender_email
        message["To"] = receiver_email
        message["Subject"] = f"Calendar Update: {event_data['title']} {action}"
        
        # Create the body of the message
        start_date = datetime.fromisoformat(event_data['start_date'].replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(event_data['end_date'].replace('Z', '+00:00'))
        
        body = f"""Hi Andrea! 👋

{event_data['user_name']} has {action} an event in your shared calendar:

📅 **Event Details:**
• Title: {event_data['title']}
• Type: {event_data['event_type'].title()}
• Start: {start_date.strftime('%B %d, %Y at %I:%M %p')}
• End: {end_date.strftime('%B %d, %Y at %I:%M %p')}
• Shared: {'Yes' if event_data['applies_to_both'] else 'No'}

You can view and manage this event in your calendar at: https://carlevato.net

Best regards,
Your Calendar System 🤖

---
This is an automated notification. Please do not reply to this email."""

        message.attach(MIMEText(body, "plain"))

        try:
            # Send email via Gmail SMTP
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
                server.login(sender_email, "your-app-password-here")  # Replace with your app password
                server.sendmail(sender_email, receiver_email, message.as_string())
                logger.info(f"✅ Email sent successfully to {receiver_email}")
        except Exception as smtp_error:
            logger.error(f"❌ SMTP Error: {smtp_error}")
            # Fallback to logging if SMTP fails
            logger.info(f"📧 EMAIL NOTIFICATION (would send to {receiver_email}):")
            logger.info(f"Subject: {message['Subject']}")
            logger.info(f"Body:\n{body}")
            logger.info("-" * 50)
            
    except Exception as e:
        logger.error(f"❌ Email notification error: {e}")

def should_send_notification(event_data, user_name):
    """Check if email notification should be sent"""
    logger.info(f"🔍 Checking notification for user: '{user_name}' (type: {type(user_name)})")
    logger.info(f"🔍 User name comparison: '{user_name.lower()}' == 'angel'")
    should_send = user_name.lower() == "angel"
    logger.info(f"🔍 Should send notification: {should_send}")
    return should_send 