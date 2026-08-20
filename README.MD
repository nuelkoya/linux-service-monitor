# Linux Service Monitor

A Bash-based Linux service monitoring tool that tracks CPU and memory usage for systemd services and logs results through journald.

## Features

- Monitor multiple systemd services
- Check CPU and memory usage
- Detect inactive services
- Automatically restart failed services
- Log monitoring results through systemd/journald

## Requirements

- Linux
- Bash
- systemd

## Usage

Make the script executable:
```bash
chmod +x monitor.sh
```

## Run with systemd
Copy the script and service file:
```bash
sudo cp monitor.sh /usr/local/bin/monitor.sh
sudo cp service-monitor.service /etc/systemd/system/
```

Reload systemd and enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now service-monitor
```

Check the service:
```bash
sudo systemctl status service-monitor
```

View logs:
```bash
sudo journalctl -u service-monitor -f
```