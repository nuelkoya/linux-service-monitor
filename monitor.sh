#!/bin/bash

if [ $# -eq 0 ]; then
    echo "No service provided"
    exit 1
fi

services=("$@")
service=$1
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/var/log/service-monitor.log"
IFS='.' read -ra parts <<< "$service"
CPU_THRESHOLD=80
MEM_THRESHOLD=80

if [ ! -f "$LOG_FILE" ]; then
    	touch "$LOG_FILE"
	chmod u+rw,go+r "$LOG_FILE"
	echo "Log file created - $LOG_FILE"
fi

enrich_service() {
	local service=$1
	IFS='.' read -ra parts <<< "$service"
	if [[ -z "${parts[1]}" ]]; then
        	service+=".service"
	fi
	echo $service
}

log_status() {
	local timestamp=$1
	local service_name=$2
	local message=$3
	echo "[$timestamp] $message $service_name"  | tee -a "$LOG_FILE"
}

log_status "$TIMESTAMP" "$service" "Monitoring" 

check_service_status() {
	local service_name=$1
	local LOG_FILE=$2
	local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
	if systemctl is-active --quiet "$service_name"; then
                PID=$(systemctl show --property=MainPID --value "$service_name")
                CPU_USAGE=$(ps -p "$PID" -o %cpu=)
                MEM_USAGE=$(ps -p "$PID" -o %mem=)
                echo "PID=$PID"

                if awk "BEGIN {exit !($CPU_USAGE > $CPU_THRESHOLD)}"; then
			log_status "$TIMESTAMP" "$service_name" "[$PID] WARNING CPU usage is high - $CPU_USAGE"
                else
			log_status "$TIMESTAMP" "$service_name" "[$PID] CPU usage is normal - $CPU_USAGE"
                fi

                if awk "BEGIN {exit !($MEM_USAGE > $MEM_THRESHOLD)}"; then
                        log_status "$TIMESTAMP" "$service_name" "[$PID] WARNING MEM usage is high - $MEM_USAGE"
                else
                        log_status "$TIMESTAMP" "$service_name" "[$PID] MEM usage is normal - $MEM_USAGE"
                fi
        else
                log_status "$TIMESTAMP" "$service_name" "Serivce is inactive"
                log_status "$TIMESTAMP" "$service_name" "Starting"
                systemctl start "$service_name"
                if systemctl is-active --quiet "$service_name"; then
                        log_status "$TIMESTAMP" "$service_name" "Restart successful"
                else
			for attempt in {1..3}; do
				log_status "$TIMESTAMP" "$service_name" "Restart attempt $attempt"
				systemctl start "$service_name"
				if  systemctl is-active --quiet "$service_name";  then
					log_status "$TIMESTAMP" "$service_name" "Restart successful"
					break
				fi

				log_status "$TIMESTAMP" "$service_name" "Restart unsuccesful"

			 	if [[ "$attempt" -eq 3 ]]; then
					log_status "$TIMESTAMP" "$service_name" "Service failed after 3 restart attempts"
					exit 1
				fi
                        done
                fi
        fi
}

#service_exist=$(systemctl list-unit-files "$service" | awk 'NR==2 {print $1}')



while true; do
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
	for service in "${services[@]}"; do
		service_name=$(enrich_service "$service")
		service_exist=$(systemctl list-unit-files "$service_name" | awk 'NR==2 {print $1}')
		
		if [[ -z "$service_exist" ]]; then
        		log_status "$TIMESTAMP" "$service_name" "ERROR: service does not exist - "
		else
        		check_service_status "$service_name" "$LOG_FILE" "$TIMESTAMP"
		fi
	done

sleep 7s

done
