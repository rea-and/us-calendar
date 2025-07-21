# Gmail SMTP Setup Guide

## 📧 **Configure Gmail for Email Notifications**

### **Step 1: Set Up Gmail App Password**

1. **Go to your Google Account**: https://myaccount.google.com/
2. **Click on "Security"** in the left sidebar
3. **Enable 2-Factor Authentication** (if not already enabled)
4. **Go to "App passwords"** (under "Signing in to Google")
5. **Select "Mail"** from the dropdown
6. **Click "Generate"**
7. **Copy the 16-character password** (format: `abcd efgh ijkl mnop`)

### **Step 2: Update email_utils.py**

Edit the file `backend/email_utils.py` and replace these values:

```python
# Line 15: Replace with your Gmail address
sender_email = "your-actual-gmail@gmail.com"

# Line 89: Replace with your app password (remove spaces)
server.login(sender_email, "your16characterapppassword")
```

### **Step 3: Example Configuration**

```python
# Example with real values:
sender_email = "angel.calendar@gmail.com"  # Your Gmail address
# In the SMTP login line:
server.login(sender_email, "abcd efgh ijkl mnop")  # Your app password
```

### **Step 4: Deploy the Changes**

```bash
cd /opt/us-calendar
git add backend/email_utils.py
git commit -m "Configure Gmail SMTP for email notifications"
git push origin main

# On your server:
git pull origin main
sudo systemctl restart us-calendar
```

### **Step 5: Test Email Notifications**

1. **Monitor logs**: `sudo journalctl -u us-calendar -f`
2. **Create an event as Angel** in the calendar
3. **Check for success message**: `✅ Email sent successfully to andrea.carlevato@gmail.com`

### **⚠️ Important Notes:**

- **Never commit your app password** to Git
- **Use environment variables** for production
- **The app password is 16 characters** (remove spaces when using)
- **Gmail has sending limits** (500 emails/day for regular accounts)

### **🔧 Troubleshooting:**

If emails don't send, check the logs for:
- `❌ SMTP Error: [Username and Password not accepted]` → Wrong app password
- `❌ SMTP Error: [Authentication failed]` → 2FA not enabled
- `❌ SMTP Error: [Connection refused]` → Network/firewall issue

### **✅ Success Indicators:**

- `✅ Email sent successfully to andrea.carlevato@gmail.com`
- Andrea receives emails at `andrea.carlevato@gmail.com`
- Email content includes all event details 