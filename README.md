# **Server Analysis Script** 🔍

## **Description**

`server_analysis.sh` is a comprehensive script for diagnosing and analyzing Linux-based servers. The script provides detailed information about the system, installed software, configurations, and potential issues.

## **Quick Check**

For quick server inspection, use `quick_check.sh`:

```bash
wget -O quick_check.sh https://raw.githubusercontent.com/13winged/server-analysis/main/quick_check.sh
chmod +x quick_check.sh
./quick_check.sh
```

### **Differences from full version:**
- ⚡ **Faster** - completes in 10-30 seconds
- 🔍 **Essential checks** - system, services, Docker, resources
- 🚨 **Critical issues only** - warnings and errors
- 📊 **Brief summary** - key information on one screen

## **Features**

### **📊 System Information**
- Uptime, kernel version, architecture
- CPU and memory information
- Disk space and inode usage
- Network interfaces and open ports

### **🐳 Docker Analysis**
- Containers (running/stopped)
- Images and their sizes
- Docker networks and volumes
- Docker Compose files
- Docker system information

### **📦 Dependencies and Packages**
- Package manager checks (apt, yum, dpkg, rpm)
- Development tools (git, curl, make, gcc)
- Web servers (nginx, apache)
- Databases (MySQL, PostgreSQL, MongoDB)
- Programming languages (PHP, Python, Node.js)

### **🔧 Services and Applications**
- Running and failed services
- Web applications and their structure
- Cron jobs
- Users and permissions

### **🛡️ Security**
- Firewall status (iptables/ufw)
- SSH configuration
- Fail2Ban status
- Authentication logs

### **📈 Performance**
- Load average
- Memory usage
- Disk I/O statistics
- Resource monitoring

### **⚡ Additional Checks**
- SSL certificates
- Environment variables
- Configuration files (.env)
- Backup configurations

## **Installation and Usage**

### **Quick Start**
```bash
# Download the script
wget -O server_analysis.sh https://raw.githubusercontent.com/13winged/server-analysis/main/server_analysis.sh

# Make it executable
chmod +x server_analysis.sh

# Run it
./server_analysis.sh
```

### **Install as System Utility**
```bash
# Download and install to PATH
sudo wget -O /usr/local/bin/server-analysis https://raw.githubusercontent.com/13winged/server-analysis/main/server_analysis.sh
sudo chmod +x /usr/local/bin/server-analysis

# Now you can run from anywhere
server-analysis
```

## **Output**

### **Log File**
The script creates a detailed log in the format:
```
/root/server_analysis_YYYYMMDD_HHMMSS.log
```

### **Console Output**
- Color-coded messages
- Quick summary at the end
- Warnings and errors highlighted

## **Color Scheme**
- 🔵 **Blue** - sections and subsections
- 🟢 **Green** - informational messages
- 🟡 **Yellow** - warnings
- 🔴 **Red** - errors and critical issues
- 🟣 **Purple** - additional sections
- 🔵 **Cyan** - subsections

## **Usage Examples**

```bash
# Full server analysis
./server_analysis.sh

# Check only Docker environment
./server_analysis.sh | grep -A 20 "DOCKER ANALYSIS"

# Search for problems
./server_analysis.sh | grep -E "(WARNING|ERROR)"
```

## **Requirements**

- **OS**: Linux (Debian, Ubuntu, CentOS, RHEL)
- **Permissions**: root or sudo access
- **Utilities**: bash, coreutils
- **Optional**: docker, docker-compose for full analysis

## **Repository Structure**

```
server-analysis/
├── server_analysis.sh          # Main script
├── quick_check.sh              # Quick version
├── README.md                   # Documentation (English)
├── README_RU.md                # Documentation (Russian)
├── LICENSE                     # License
└── examples/                   # Usage examples
```

## **Script Comparison**

| Feature | server_analysis.sh | quick_check.sh |
|---------|-------------------|----------------|
| Execution Time | 1-2 minutes | 10-30 seconds |
| Detail Level | Comprehensive | Essential |
| Docker Analysis | Detailed | Quick check |
| Output | Detailed log | Brief summary |
| Use Case | Audit, migration | Daily monitoring |

## **License**

MIT License - see [LICENSE](LICENSE) file for details.