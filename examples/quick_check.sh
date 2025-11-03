#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
LOG_FILE="/root/quick_check_$(date +%Y%m%d_%H%M%S).log"

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

check_service() {
    if systemctl is-active --quiet $1; then
        echo "✓ $1" | tee -a "$LOG_FILE"
    else
        echo "✗ $1" | tee -a "$LOG_FILE"
    fi
}

check_command() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1" | tee -a "$LOG_FILE"
    else
        echo "✗ $1" | tee -a "$LOG_FILE"
    fi
}

echo "Starting quick server check..." | tee "$LOG_FILE"
echo "Started at: $(date)" | tee -a "$LOG_FILE"

# 1. SYSTEM OVERVIEW
print_section "SYSTEM OVERVIEW"
echo "Hostname: $(hostname)" | tee -a "$LOG_FILE"
echo "Uptime: $(uptime -p)" | tee -a "$LOG_FILE"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')" | tee -a "$LOG_FILE"
echo "Kernel: $(uname -r)" | tee -a "$LOG_FILE"

# 2. RESOURCES
print_section "RESOURCES"
echo "CPU: $(nproc) cores, Load: $(uptime | awk -F'load average:' '{print $2}')" | tee -a "$LOG_FILE"
echo "Memory: $(free -h | grep Mem: | awk '{print $3 "/" $2 " (" $4 " free)"}')" | tee -a "$LOG_FILE"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')" | tee -a "$LOG_FILE"

# 3. CRITICAL SERVICES
print_section "CRITICAL SERVICES"
check_service ssh
check_service nginx
check_service apache2
check_service mariadb
check_service mysql
check_service postgresql
check_service docker
check_service fail2ban

# 4. DOCKER QUICK CHECK
print_section "DOCKER STATUS"
if command -v docker &> /dev/null; then
    echo "Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)" | tee -a "$LOG_FILE"
    echo "Containers: $(docker ps -q 2>/dev/null | wc -l) running, $(docker ps -a -q 2>/dev/null | wc -l) total" | tee -a "$LOG_FILE"
    echo "Images: $(docker images -q 2>/dev/null | wc -l)" | tee -a "$LOG_FILE"
    
    # Show running containers
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | tee -a "$LOG_FILE"
else
    echo "Docker: Not installed" | tee -a "$LOG_FILE"
fi

# 5. NETWORK
print_section "NETWORK"
echo "IP Address: $(hostname -I 2>/dev/null || ip addr show 2>/dev/null | grep -oP 'inet \K[\d.]+' | grep -v 127.0.0.1 | head -1)" | tee -a "$LOG_FILE"
echo "Open Ports:" | tee -a "$LOG_FILE"
ss -tulpn | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -nu | head -10 | tee -a "$LOG_FILE"

# 6. WEB APPLICATIONS
print_section "WEB APPLICATIONS"
find /var/www /home -maxdepth 3 -name "index.php" -o -name "index.html" 2>/dev/null | head -5 | tee -a "$LOG_FILE"

# 7. DATABASES
print_section "DATABASES"
if command -v mysql &> /dev/null; then
    echo "MySQL databases: $(mysql -e "SHOW DATABASES;" 2>/dev/null | wc -l)" | tee -a "$LOG_FILE"
fi

if command -v psql &> /dev/null; then
    echo "PostgreSQL databases: $(psql -l 2>/dev/null | wc -l)" | tee -a "$LOG_FILE"
fi

# 8. SECURITY
print_section "SECURITY"
# Check fail2ban status
if systemctl is-active --quiet fail2ban; then
    echo "Fail2Ban: Active" | tee -a "$LOG_FILE"
    echo "Banned IPs: $(fail2ban-client status 2>/dev/null | grep "Total banned" | awk '{print $4}')" | tee -a "$LOG_FILE"
fi

# Check firewall
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
    echo "UFW: Active" | tee -a "$LOG_FILE"
elif iptables -L -n 2>/dev/null | grep -q "ACCEPT"; then
    echo "IPTables: Active" | tee -a "$LOG_FILE"
else
    echo "Firewall: Not detected" | tee -a "$LOG_FILE"
fi

# 9. ESSENTIAL COMMANDS
print_section "ESSENTIAL TOOLS"
check_command curl
check_command wget
check_command git
check_command cron
check_command systemctl
check_command rsync
check_command tar

# 10. QUICK ISSUE CHECK
print_section "ISSUE CHECK"

# Disk space check
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    print_warning "High disk usage: ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -gt 80 ]; then
    print_warning "Disk usage: ${DISK_USAGE}%"
else
    print_info "Disk usage: ${DISK_USAGE}% (OK)"
fi

# Memory check
MEM_FREE=$(free | awk 'NR==2{printf "%.1f", $4/$2 * 100}')
if (( $(echo "$MEM_FREE < 10" | bc -l 2>/dev/null || echo "0") )); then
    print_warning "Low free memory: ${MEM_FREE}%"
else
    print_info "Free memory: ${MEM_FREE}%"
fi

# Failed services
FAILED_SERVICES=$(systemctl --failed 2>/dev/null | grep "failed" | wc -l)
if [ "$FAILED_SERVICES" -gt 0 ]; then
    print_error "Failed services: $FAILED_SERVICES"
    systemctl --failed 2>/dev/null | tee -a "$LOG_FILE"
fi

# Zombie processes
ZOMBIES=$(ps aux | awk '{print $8}' | grep -c Z)
if [ "$ZOMBIES" -gt 0 ]; then
    print_warning "Zombie processes: $ZOMBIES"
fi

# 11. SUMMARY
print_section "QUICK SUMMARY"
echo "System: $(hostname)" | tee -a "$LOG_FILE"
echo "Uptime: $(uptime -p)" | tee -a "$LOG_FILE"
echo "Resources: CPU $(nproc) cores, Memory $(free -h | grep Mem: | awk '{print $3 "/" $2}'), Disk $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')" | tee -a "$LOG_FILE"
echo "Services: $(systemctl list-units --type=service --state=running 2>/dev/null | wc -l) running" | tee -a "$LOG_FILE"

if command -v docker &> /dev/null; then
    echo "Docker: $(docker ps -q 2>/dev/null | wc -l) containers running" | tee -a "$LOG_FILE"
fi

echo -e "\n${GREEN}Quick check complete!${NC}" | tee -a "$LOG_FILE"
echo "Full log: $LOG_FILE" | tee -a "$LOG_FILE"

# Display critical warnings
echo -e "\n${YELLOW}=== CRITICAL CHECK ===${NC}"
tail -20 "$LOG_FILE" | grep -E "(WARNING|ERROR)" | head -10