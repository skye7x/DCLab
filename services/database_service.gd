class_name DatabaseService extends Service

var db_name: String = "app"
var db_type: String = "postgresql"
var tables: Dictionary = {} # table_name -> Array of column names

func _init():
	super("database", 5432, "tcp")

func start() -> String:
	is_running = true
	cpu_usage = 5.0
	ram_usage_mb = 500.0
	return "Database Server started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "Database Server stopped"

func add_table(table_name: String, columns: Array):
	tables[table_name] = columns

func remove_table(table_name: String):
	tables.erase(table_name)

func get_tables() -> Dictionary:
	return tables

func handle_request(request_data: Dictionary) -> Dictionary:
	if not is_running:
		return {"status": "error", "body": "Connection refused"}
	
	var query = request_data.get("query", "")
	if query == "":
		return {"status": "connected", "body": "Connected to " + db_name}
		
	return {"status": "success", "body": "Query executed (mocked)"}

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["db_name"] = db_name
	d["db_type"] = db_type
	d["tables"] = tables
	return d
