class_name SshService extends Service

func _init():
	super("ssh", 22, "tcp")

func start() -> String:
	is_running = true
	cpu_usage = 0.5
	ram_usage_mb = 20.0
	return "SSH Daemon started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "SSH Daemon stopped"

func handle_request(request_data: Dictionary) -> Dictionary:
	if is_running:
		return {"status": "connected", "body": "SSH connection established"}
	else:
		return {"status": "refused", "body": "Connection refused"}

func to_dict() -> Dictionary:
	return super.to_dict()
