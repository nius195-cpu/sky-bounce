extends Node
signal connected
signal disconnected
signal connect_error(code: int, message: String)
signal query_product_details_response(response: Dictionary)
signal query_purchases_response(response: Dictionary)
signal on_purchase_updated(response: Dictionary)
signal acknowledge_purchase_response(response: Dictionary)
var launches := 0
var acknowledgements: Array[String] = []
var owned_queries := 0
var product_queries := 0
var launch_result := {"response_code":0}
func start_connection() -> void: connected.emit()
func end_connection() -> void: pass
func query_product_details(_ids, _type) -> void: product_queries += 1
func query_purchases(_type) -> void: owned_queries += 1
func purchase(_id, _option) -> Dictionary:
	launches += 1
	return launch_result
func acknowledge_purchase(token: String) -> void: acknowledgements.append(token)
