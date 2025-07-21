#!/bin/bash

# Database backup and restore script for us-calendar
# Usage: ./backup-database.sh [backup|restore|list] [backup_name]

BACKUP_DIR="backups"
DB_PATH="/var/www/us-calendar/backend/database.db"
DB_NAME="us-calendar"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        print_status "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Function to check if database exists
check_database() {
    if [ ! -f "$DB_PATH" ]; then
        print_error "Database not found at: $DB_PATH"
        exit 1
    fi
}

# Function to create a backup
create_backup() {
    print_header "Creating Database Backup"
    
    check_database
    create_backup_dir
    
    # Generate backup filename with timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_${TIMESTAMP}.db"
    
    print_status "Creating backup: $BACKUP_FILE"
    
    # Stop the service to ensure database is not being written to
    print_status "Stopping us-calendar service..."
    sudo systemctl stop us-calendar
    
    # Wait a moment for the service to stop
    sleep 2
    
    # Create the backup
    if sudo cp "$DB_PATH" "$BACKUP_FILE"; then
        print_status "Backup created successfully!"
        
        # Set proper permissions
        sudo chown www-data:www-data "$BACKUP_FILE"
        sudo chmod 644 "$BACKUP_FILE"
        
        # Show backup info
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        print_status "Backup size: $BACKUP_SIZE"
        print_status "Backup location: $BACKUP_FILE"
    else
        print_error "Failed to create backup!"
        exit 1
    fi
    
    # Restart the service
    print_status "Starting us-calendar service..."
    sudo systemctl start us-calendar
    
    # Wait for service to start
    sleep 3
    
    # Check service status
    if sudo systemctl is-active --quiet us-calendar; then
        print_status "Service started successfully!"
    else
        print_warning "Service may not have started properly. Check with: sudo systemctl status us-calendar"
    fi
}

# Function to list available backups
list_backups() {
    print_header "Available Database Backups"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Backup directory does not exist: $BACKUP_DIR"
        return
    fi
    
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.db" | wc -l)
    
    if [ "$BACKUP_COUNT" -eq 0 ]; then
        print_warning "No backups found in: $BACKUP_DIR"
        return
    fi
    
    print_status "Found $BACKUP_COUNT backup(s):"
    echo ""
    
    # List backups with details
    find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.db" -type f | sort | while read -r backup_file; do
        filename=$(basename "$backup_file")
        size=$(du -h "$backup_file" | cut -f1)
        date=$(stat -c %y "$backup_file" | cut -d' ' -f1)
        time=$(stat -c %y "$backup_file" | cut -d' ' -f2 | cut -d'.' -f1)
        
        echo -e "${GREEN}$filename${NC}"
        echo "  Size: $size"
        echo "  Date: $date $time"
        echo ""
    done
}

# Function to restore from backup
restore_backup() {
    local backup_name="$1"
    
    print_header "Restoring Database from Backup"
    
    if [ -z "$backup_name" ]; then
        print_error "Please specify a backup name to restore from."
        echo "Usage: $0 restore <backup_name>"
        echo ""
        print_status "Available backups:"
        list_backups
        exit 1
    fi
    
    # Construct full backup path
    if [[ "$backup_name" == *".db" ]]; then
        BACKUP_PATH="$BACKUP_DIR/$backup_name"
    else
        BACKUP_PATH="$BACKUP_DIR/${backup_name}.db"
    fi
    
    # Check if backup file exists
    if [ ! -f "$BACKUP_PATH" ]; then
        print_error "Backup file not found: $BACKUP_PATH"
        echo ""
        print_status "Available backups:"
        list_backups
        exit 1
    fi
    
    print_status "Restoring from: $BACKUP_PATH"
    
    # Confirm restoration
    echo ""
    print_warning "This will overwrite the current database!"
    echo "Current database: $DB_PATH"
    echo "Backup file: $BACKUP_PATH"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restoration cancelled."
        exit 0
    fi
    
    # Stop the service
    print_status "Stopping us-calendar service..."
    sudo systemctl stop us-calendar
    
    # Wait for service to stop
    sleep 2
    
    # Create a backup of current database before restoring
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    CURRENT_BACKUP="$BACKUP_DIR/${DB_NAME}_before_restore_${TIMESTAMP}.db"
    
    if [ -f "$DB_PATH" ]; then
        print_status "Creating backup of current database before restore..."
        sudo cp "$DB_PATH" "$CURRENT_BACKUP"
        sudo chown www-data:www-data "$CURRENT_BACKUP"
        sudo chmod 644 "$CURRENT_BACKUP"
    fi
    
    # Restore the database
    print_status "Restoring database..."
    if sudo cp "$BACKUP_PATH" "$DB_PATH"; then
        sudo chown www-data:www-data "$DB_PATH"
        sudo chmod 644 "$DB_PATH"
        print_status "Database restored successfully!"
    else
        print_error "Failed to restore database!"
        exit 1
    fi
    
    # Start the service
    print_status "Starting us-calendar service..."
    sudo systemctl start us-calendar
    
    # Wait for service to start
    sleep 3
    
    # Check service status
    if sudo systemctl is-active --quiet us-calendar; then
        print_status "Service started successfully!"
    else
        print_warning "Service may not have started properly. Check with: sudo systemctl status us-calendar"
    fi
    
    # Test API endpoints
    print_status "Testing API endpoints..."
    sleep 2
    
    if curl -s http://localhost:5001/api/health >/dev/null; then
        print_status "Health endpoint: OK"
    else
        print_warning "Health endpoint: Not responding"
    fi
    
    if curl -s http://localhost:5001/api/users >/dev/null; then
        print_status "Users endpoint: OK"
    else
        print_warning "Users endpoint: Not responding"
    fi
    
    if curl -s http://localhost:5001/api/events >/dev/null; then
        print_status "Events endpoint: OK"
    else
        print_warning "Events endpoint: Not responding"
    fi
}

# Function to show usage
show_usage() {
    echo "Database Backup and Restore Script for us-calendar"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup              Create a new backup of the database"
    echo "  restore <name>      Restore database from a backup"
    echo "  list                List all available backups"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup                                    # Create a new backup"
    echo "  $0 list                                      # List all backups"
    echo "  $0 restore us-calendar_backup_20250721_143022.db  # Restore specific backup"
    echo "  $0 restore us-calendar_backup_20250721_143022     # Restore (without .db extension)"
    echo ""
    echo "Backup location: $BACKUP_DIR/"
    echo "Database location: $DB_PATH"
}

# Main script logic
case "$1" in
    "backup")
        create_backup
        ;;
    "restore")
        restore_backup "$2"
        ;;
    "list")
        list_backups
        ;;
    "help"|"--help"|"-h"|"")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac 