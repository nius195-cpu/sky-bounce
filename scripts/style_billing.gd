class_name StyleBilling
extends Node

# Official Godot plugin 3.3.0 / Google Play Billing 9.1.0. No purchase is
# started automatically, and this non-consumable is NEVER consumed.
const Client = preload("res://addons/GodotGooglePlayBilling/BillingClient.gd")
const PRODUCT_ID := "sky_bounce_style_pack"
const PACKAGE_ID := "org.skybounce.keepitup"
const OK := 0
const CANCELED := 1
const ALREADY_OWNED := 7
const PURCHASED := 1
const PENDING := 2
signal changed
signal entitlement_changed(owned: bool)
var client: Node
var entitled := false
var store_ready := false
var reconciled := false
var pending := false
var busy := false
var querying := false
var price_label := ""
var purchase_option := ""
var status := "Purchases are available through Google Play on Android."
# Optional async Callable(receipt) -> bool for a future trusted backend.
# Empty means client SDK result validation only, not fraud-proof verification.
var server_verifier := Callable()
var _processed := {}
var _validating := {}
var _acknowledging := {}
var _ack_done := {}
var _retry_ack := {}
var _deadline := 0.0
var _reconnect_at := 0.0

func configure(cached_owned: bool, test_client: Node = null) -> void:
	entitled = cached_owned
	if test_client != null:
		client = test_client
	elif OS.has_feature("Android") and Engine.has_singleton("GodotGooglePlayBilling"):
		client = Client.new()
		add_child(client)
	else:
		return
	client.connected.connect(_connected)
	client.disconnected.connect(_disconnected)
	client.connect_error.connect(_connection_error)
	client.query_product_details_response.connect(_products)
	client.query_purchases_response.connect(_purchases)
	client.on_purchase_updated.connect(_updates)
	client.acknowledge_purchase_response.connect(_acknowledged)
	connect_store()

func connect_store() -> void:
	if client == null:
		changed.emit()
		return
	status = "Connecting to Google Play…"
	_deadline = Time.get_ticks_msec() / 1000.0 + 45
	client.start_connection()
	changed.emit()

func _connected() -> void:
	store_ready = true
	status = "Checking your purchases…"
	restore()

func _disconnected() -> void:
	store_ready = false
	busy = false
	querying = false
	price_label = ""
	status = "Store connection lost. You can keep playing offline."
	_reconnect_at = Time.get_ticks_msec() / 1000.0 + 10
	changed.emit()

func _connection_error(_code: int, _message: String) -> void:
	_disconnected()

func refresh() -> void:
	if store_ready:
		restore()
	elif client != null:
		connect_store()

func restore() -> void:
	if client == null:
		status = "Restore purchases from the Google Play version on Android."
		changed.emit()
		return
	if not store_ready:
		connect_store()
		return
	if querying:
		return
	querying = true
	status = "Restoring purchases…"
	_deadline = Time.get_ticks_msec() / 1000.0 + 45
	client.query_product_details(PackedStringArray([PRODUCT_ID]), Client.ProductType.INAPP)
	client.query_purchases(Client.ProductType.INAPP)
	changed.emit()

func can_buy() -> bool:
	return client != null and store_ready and reconciled and not entitled and not pending and not busy and not querying and not price_label.is_empty() and not purchase_option.is_empty() and _validating.is_empty()

func buy() -> void:
	if entitled:
		status = "You already own the Ultimate Style Pack."
		changed.emit()
		return
	if not can_buy():
		status = "The store is not ready. Try Restore Purchases or check your connection."
		changed.emit()
		return
	busy = true
	status = "Complete or cancel the purchase in Google Play."
	_deadline = Time.get_ticks_msec() / 1000.0 + 90
	var result: Dictionary = client.purchase(PRODUCT_ID, purchase_option)
	# OK only means the Play screen launched. It never grants an entitlement.
	if int(result.get("response_code", -999)) != OK:
		_handle_error(int(result.get("response_code", -999)))
	changed.emit()

func _products(response: Dictionary) -> void:
	price_label = ""
	purchase_option = ""
	if int(response.get("response_code", -999)) == OK:
		var details = response.get("product_details", [])
		if details is Array:
			for item in details:
				if not item is Dictionary or item.get("product_id") != PRODUCT_ID or item.get("product_type") != "inapp":
					continue
				var offers = item.get("one_time_purchase_offer_details_list", [])
				if offers is Array:
					for offer in offers:
						# The pack is a permanent buy option, never a rental or subscription.
						if offer is Dictionary and offer.get("rental_details") == null and offer.get("offer_id") == null and not str(offer.get("purchase_option_id", "")).is_empty():
							price_label = str(offer.get("formatted_price", ""))
							purchase_option = str(offer.purchase_option_id)
							break
	if price_label.is_empty():
		status = "This pack is not available from the store right now. You can still play and earn free styles."
	changed.emit()

func _matching(receipt: Dictionary) -> bool:
	var ids = receipt.get("product_ids", [])
	return (ids is Array or ids is PackedStringArray) and PRODUCT_ID in ids

func valid_completed(receipt: Dictionary) -> bool:
	return _matching(receipt) and int(receipt.get("purchase_state", 0)) == PURCHASED and receipt.get("package_name") == PACKAGE_ID and int(receipt.get("quantity", 0)) == 1 and not str(receipt.get("purchase_token", "")).is_empty() and not str(receipt.get("signature", "")).is_empty() and not str(receipt.get("original_json", "")).is_empty() and not bool(receipt.get("is_suspended", false))

func _grant(receipt: Dictionary) -> bool:
	if not valid_completed(receipt):
		return false
	var token: String = receipt.purchase_token
	if _validating.has(token):
		return false
	if not _processed.has(token):
		_validating[token] = true
		if server_verifier.is_valid() and not bool(await server_verifier.call(receipt)):
			_validating.erase(token)
			status = "Purchase verification did not complete. Try Restore Purchases."
			return false
		_validating.erase(token)
		_processed[token] = true
	_set_owned(true)
	if bool(receipt.get("is_acknowledged", false)):
		_ack_done[token] = true
	else:
		_ack(token)
	return true

func _set_owned(owned: bool) -> void:
	if entitled != owned:
		entitled = owned
		entitlement_changed.emit(owned)

func _purchases(response: Dictionary) -> void:
	_deadline = 0
	if int(response.get("response_code", -999)) != OK or not response.get("purchases") is Array:
		querying = false
		status = "Could not restore purchases. Check your connection and try again."
		changed.emit()
		return # Keep cached offline ownership on transient errors.
	var owns_pack := false
	var valid_snapshot := true
	pending = false
	for receipt in response.purchases:
		if not receipt is Dictionary or not _matching(receipt):
			continue
		if int(receipt.get("purchase_state", 0)) == PENDING:
			pending = true
		elif valid_completed(receipt):
			var verified: bool = await _grant(receipt)
			owns_pack = owns_pack or verified
			valid_snapshot = valid_snapshot and verified
		else:
			valid_snapshot = false
	if valid_snapshot:
		_set_owned(owns_pack) # Empty successful query reconciles refund/account changes.
		reconciled = true
	querying = false
	busy = false
	status = "Ultimate Style Pack owned." if owns_pack else ("Payment pending. Styles unlock after Google Play confirms payment." if pending else "Purchases restored. No pack is owned by this Play account.")
	changed.emit()

func _updates(response: Dictionary) -> void:
	_deadline = 0
	var code := int(response.get("response_code", -999))
	if code != OK:
		_handle_error(code)
		return
	busy = false
	var receipts = response.get("purchases", [])
	if not receipts is Array:
		return
	for receipt in receipts:
		if not receipt is Dictionary or not _matching(receipt):
			continue
		if int(receipt.get("purchase_state", 0)) == PENDING:
			pending = true
			status = "Payment pending. Styles unlock after Google Play confirms payment."
		elif await _grant(receipt):
			pending = false
			status = "Ultimate Style Pack unlocked. Enjoy your new styles!"
		else:
			status = "Purchase could not be validated. Try Restore Purchases."
	changed.emit()

func _handle_error(code: int) -> void:
	busy = false
	if code == ALREADY_OWNED:
		restore() # Do not charge again or grant merely from an error code.
	else:
		status = "Purchase cancelled. You have not unlocked the pack." if code == CANCELED else "Purchase unavailable. Check Google Play and try again."
	changed.emit()

func _ack(token: String) -> void:
	if client == null or _acknowledging.has(token) or _ack_done.has(token):
		return
	_acknowledging[token] = Time.get_ticks_msec() / 1000.0 + 30
	client.acknowledge_purchase(token)

func _acknowledged(response: Dictionary) -> void:
	var token := str(response.get("token", ""))
	if not _acknowledging.has(token):
		return
	_acknowledging.erase(token)
	if int(response.get("response_code", -999)) == OK:
		_retry_ack.erase(token)
		_ack_done[token] = true
	else:
		_retry_ack[token] = Time.get_ticks_msec() / 1000.0 + 15
		status = "Pack unlocked; store confirmation will retry when connected."
	changed.emit()

func _process(_dt: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if client != null and not store_ready and _reconnect_at > 0 and now >= _reconnect_at:
		_reconnect_at = 0
		connect_store()
	if store_ready:
		for token in _acknowledging.keys():
			if now >= float(_acknowledging[token]):
				_acknowledging.erase(token)
				_retry_ack[token] = now + 15
		for token in _retry_ack.keys():
			if now >= float(_retry_ack[token]):
				_retry_ack.erase(token)
				_ack(token)
	if _deadline > 0 and now >= _deadline:
		_deadline = 0
		busy = false
		querying = false
		status = "The store is taking longer than expected. Try Restore Purchases."
		changed.emit()

func _exit_tree() -> void:
	if client != null and is_instance_valid(client):
		client.end_connection()
