#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/root/server_analysis_$(date +%Y%m%d_%H%M%S).log"

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

# Function to print subsection
print_subsection() {
    echo -e "\n${CYAN}--- $1 ---${NC}" | tee -a "$LOG_FILE"
}

# Function to print info
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to print error
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check command availability
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1" | tee -a "$LOG_FILE"
        return 0
    else
        echo "✗ $1" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Start analysis
echo "Starting comprehensive server analysis..." | tee "$LOG_FILE"
echo "Analysis started at: $(date)" | tee -a "$LOG_FILE"

# 1. SYSTEM INFORMATION
print_section "1. SYSTEM INFORMATION"
print_info "Hostname: $(hostname)"
print_info "Uptime: $(uptime -p)"
cat /etc/os-release >> "$LOG_FILE"
echo "Kernel: $(uname -r)" | tee -a "$LOG_FILE"
echo "Architecture: $(uname -m)" | tee -a "$LOG_FILE"
echo "Timezone: $(timedatectl status 2>/dev/null | grep "Time zone" | cut -d: -f2- || date +%Z)" | tee -a "$LOG_FILE"

# 2. HARDWARE INFORMATION
print_section "2. HARDWARE INFORMATION"
echo "CPU cores: $(nproc)" | tee -a "$LOG_FILE"
echo "CPU model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)" | tee -a "$LOG_FILE"
echo "Memory: $(free -h | grep Mem: | awk '{print $2}') total" | tee -a "$LOG_FILE"
echo "Swap: $(free -h | grep Swap: | awk '{print $2}') total" | tee -a "$LOG_FILE"

# 3. DISK USAGE
print_section "3. DISK USAGE"
lsblk >> "$LOG_FILE"
df -h >> "$LOG_FILE"

print_subsection "Largest Directories"
du -sh /* 2>/dev/null | sort -hr | head -15 >> "$LOG_FILE"

print_subsection "Inode Usage"
df -i >> "$LOG_FILE"

# 4. NETWORK INFORMATION
print_section "4. NETWORK INFORMATION"
ip addr show >> "$LOG_FILE"

print_subsection "Listening Ports"
ss -tulpn | head -30 >> "$LOG_FILE"

print_subsection "Network Statistics"
ss -s >> "$LOG_FILE"

# 5. DOCKER ANALYSIS
print_section "5. DOCKER ANALYSIS"

if command -v docker &> /dev/null; then
    print_info "Docker is installed"
    echo "Docker version: $(docker --version)" | tee -a "$LOG_FILE"
    
    print_subsection "Docker Containers"
    docker ps -a >> "$LOG_FILE"
    
    print_subsection "Docker Images"
    docker images >> "$LOG_FILE"
    
    print_subsection "Docker Networks"
    docker network ls >> "$LOG_FILE"
    
    print_subsection "Docker Volumes"
    docker volume ls >> "$LOG_FILE"
    
    print_subsection "Docker System Info"
    docker system df >> "$LOG_FILE"
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose is installed"
        echo "Docker Compose version: $(docker-compose --version)" | tee -a "$LOG_FILE"
    fi
    
    # Check for docker-compose.yml files
    print_subsection "Docker Compose Files"
    find / -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null | head -10 >> "$LOG_FILE"
    
else
    print_info "Docker is not installed"
fi

# 6. DEPENDENCIES AND PACKAGES
print_section "6. DEPENDENCIES AND PACKAGES"

print_subsection "Package Managers"
check_command apt
check_command yum
check_command dpkg
check_command rpm

print_subsection "Development Tools"
check_command git
check_command curl
check_command wget
check_command make
check_command gcc
check_command python3
check_command pip3
check_command node
check_command npm
check_command composer

print_subsection "System Tools"
check_command cron
check_command systemctl
check_command journalctl
check_command ufw
check_command iptables
check_command fail2ban-server

print_subsection "Web Servers"
check_command nginx
check_command apache2
check_command httpd

print_subsection "Databases"
check_command mysql
check_command mysqldump
check_command psql
check_command pg_dump
check_command mongod

print_subsection "Programming Languages"
echo "PHP versions:" | tee -a "$LOG_FILE"
find /usr/bin -name "php*" -type f 2>/dev/null | grep -E "php[0-9]" | sort >> "$LOG_FILE"

echo "Python versions:" | tee -a "$LOG_FILE"
find /usr/bin -name "python*" -type f 2>/dev/null | grep -E "python[0-9]" | sort >> "$LOG_FILE"

echo "Node.js version:" | tee -a "$LOG_FILE"
node --version 2>/dev/null || echo "Not installed" | tee -a "$LOG_FILE"

# 7. RUNNING SERVICES
print_section "7. RUNNING SERVICES"
systemctl list-units --type=service --state=running >> "$LOG_FILE"

print_subsection "Failed Services"
systemctl --failed >> "$LOG_FILE"

# 8. INSTALLED SOFTWARE
print_section "8. INSTALLED SOFTWARE"
echo "Total packages: $(dpkg -l 2>/dev/null | wc -l || rpm -qa 2>/dev/null | wc -l)" | tee -a "$LOG_FILE"

print_subsection "Key Software Packages"
{
    dpkg -l 2>/dev/null | grep -E "(nginx|apache|mysql|mariadb|postgresql|php|python|docker|node|git)" | head -20 || 
    rpm -qa 2>/dev/null | grep -E "(nginx|apache|mysql|mariadb|postgresql|php|python|docker|node|git)" | head -20
} >> "$LOG_FILE"

# 9. WEB APPLICATIONS
print_section "9. WEB APPLICATIONS"
find /var/www /home -name "index.php" -o -name "index.html" -o -name "composer.json" -o -name "package.json" 2>/dev/null | head -20 >> "$LOG_FILE"

print_subsection "Web Roots"
find /var/www /home -type d -name "public_html" -o -name "www" -o -name "web" 2>/dev/null | head -10 >> "$LOG_FILE"

# 10. CRON JOBS
print_section "10. CRON JOBS"
ls /etc/cron.* 2>/dev/null >> "$LOG_FILE"
crontab -l 2>/dev/null >> "$LOG_FILE"

# 11. USERS
print_section "11. USER ACCOUNTS"
cat /etc/passwd | grep -E "/(bash|zsh|sh)$" >> "$LOG_FILE"

print_subsection "Sudo Users"
getent group sudo | cut -d: -f4 2>/dev/null || getent group wheel | cut -d: -f4 2>/dev/null >> "$LOG_FILE"

# 12. SECURITY
print_section "12. SECURITY"

print_subsection "Firewall Status"
iptables -L -n 2>/dev/null >> "$LOG_FILE" || ufw status 2>/dev/null >> "$LOG_FILE"

print_subsection "SSH Configuration"
grep -E "(PermitRootLogin|PasswordAuthentication|Port)" /etc/ssh/sshd_config 2>/dev/null | head -10 >> "$LOG_FILE"

print_subsection "Fail2Ban Status"
systemctl status fail2ban 2>/dev/null | head -10 >> "$LOG_FILE"

# 13. LOGS
print_section "13. LOG FILES"
ls -la /var/log/*.log 2>/dev/null | head -10 >> "$LOG_FILE"

print_subsection "Recent Security Logs"
tail -20 /var/log/auth.log 2>/dev/null || tail -20 /var/log/secure 2>/dev/null >> "$LOG_FILE"

# 14. ENVIRONMENT VARIABLES
print_section "14. ENVIRONMENT"
echo "PATH: $PATH" | tee -a "$LOG_FILE"
echo "SHELL: $SHELL" | tee -a "$LOG_FILE"

print_subsection "Environment Files"
find / -name ".env" -o -name ".env.local" -o -name ".env.production" 2>/dev/null | head -10 >> "$LOG_FILE"

# 15. BACKUP CONFIGURATIONS
print_section "15. BACKUP CONFIGURATIONS"
find / -name "*backup*" -type f -name "*.sh" -o -name "*.conf" 2>/dev/null | head -10 >> "$LOG_FILE"

print_subsection "Cron Backup Jobs"
grep -r "backup" /etc/cron* 2>/dev/null | head -10 >> "$LOG_FILE"

# 16. PERFORMANCE MONITORING
print_section "16. PERFORMANCE"

print_subsection "Load Average"
uptime | awk -F'load average:' '{print $2}' | tee -a "$LOG_FILE"

print_subsection "Memory Usage"
free -h >> "$LOG_FILE"

print_subsection "Disk I/O"
iostat -x 1 1 2>/dev/null || echo "iostat not available" | tee -a "$LOG_FILE"

# 17. SSL CERTIFICATES
print_section "17. SSL CERTIFICATES"
find /etc /home -name "*.crt" -o -name "*.key" -o -name "*.pem" 2>/dev/null | head -10 >> "$LOG_FILE"

# 18. SUMMARY
print_section "18. SUMMARY REPORT"
echo "System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')" | tee -a "$LOG_FILE"
echo "Kernel: $(uname -r)" | tee -a "$LOG_FILE"
echo "Uptime: $(uptime -p)" | tee -a "$LOG_FILE"
echo "Memory usage: $(free -h | grep Mem: | awk '{print $3 "/" $2 " (" $4 " free)"}')" | tee -a "$LOG_FILE"
echo "Disk usage: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')" | tee -a "$LOG_FILE"
echo "Running services: $(systemctl list-units --type=service --state=running | wc -l)" | tee -a "$LOG_FILE"
echo "Active connections: $(ss -tulpn | wc -l)" | tee -a "$LOG_FILE"

if command -v docker &> /dev/null; then
    echo "Docker containers: $(docker ps -q | wc -l) running, $(docker ps -a -q | wc -l) total" | tee -a "$LOG_FILE"
    echo "Docker images: $(docker images -q | wc -l)" | tee -a "$LOG_FILE"
fi

# 19. POTENTIAL ISSUES
print_section "19. POTENTIAL ISSUES"

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    print_warning "High disk usage: ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEM_USAGE" -gt 90 ]; then
    print_warning "High memory usage: ${MEM_USAGE}%"
fi

# Check load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)
CPU_CORES=$(nproc)
if (( $(echo "$LOAD_AVG > $CPU_CORES" | bc -l 2>/dev/null || echo "$LOAD_AVG > $CPU_CORES" | awk '{print ($1 > $2)}') )); then
    print_warning "High load average: ${LOAD_AVG} (CPUs: ${CPU_CORES})"
fi

# Check failed services
FAILED_SERVICES=$(systemctl --failed 2>/dev/null | grep -c "failed")
if [ "$FAILED_SERVICES" -gt 0 ]; then
    print_error "Failed services detected: $FAILED_SERVICES"
    systemctl --failed >> "$LOG_FILE"
fi

# Check Docker resources
if command -v docker &> /dev/null; then
    DOCKER_DISK_USAGE=$(docker system df 2>/dev/null | grep "Local Volumes" | awk '{print $5}' | sed 's/%//')
    if [ ! -z "$DOCKER_DISK_USAGE" ] && [ "$DOCKER_DISK_USAGE" -gt 80 ]; then
        print_warning "High Docker disk usage: ${DOCKER_DISK_USAGE}%"
    fi
fi

echo -e "\n${GREEN}Analysis complete!${NC}" | tee -a "$LOG_FILE"
echo "Full report saved to: $LOG_FILE" | tee -a "$LOG_FILE"

# Display important findings
echo -e "\n${YELLOW}=== QUICK SUMMARY ===${NC}"
tail -30 "$LOG_FILE" | grep -E "(SUMMARY|POTENTIAL|WARNING|ERROR|FAILED)" | head -20