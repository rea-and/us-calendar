#!/bin/bash

# Monitor backend logs for email notifications
echo "📧 Monitoring email notification logs..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Follow the backend service logs
sudo journalctl -u us-calendar -f --no-pager 