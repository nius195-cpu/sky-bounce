extends RefCounted
const Billing = preload("res://scripts/style_billing.gd")
const Fake = preload("res://tests/fake_billing_client.gd")
const Progress = preload("res://scripts/cosmetic_progress.gd")
const Catalog = preload("res://scripts/cosmetic_catalog.gd")

func receipt(token := "test-only-token", state := 1, acknowledged := false) -> Dictionary:
	return {"product_ids":PackedStringArray([Billing.PRODUCT_ID]), "purchase_token":token, "purchase_state":state, "is_acknowledged":acknowledged, "package_name":Billing.PACKAGE_ID, "quantity":1, "signature":"fake-test-signature-not-a-real-purchase", "original_json":"{\"test\":true}"}

func products() -> Dictionary:
	return {"response_code":0, "product_details":[{"product_id":Billing.PRODUCT_ID, "product_type":"inapp", "one_time_purchase_offer_details_list":[{"purchase_option_id":"buy", "offer_id":null, "rental_details":null, "formatted_price":"US$1.99"}]}]}

func reject_verification(_purchase: Dictionary) -> bool:
	return false

func run(tree: SceneTree, check: Callable) -> void:
	check.call(Catalog.PREMIUM.size() == 10, "Premium pack contains exactly ten exclusive styles")
	var profile := Progress.new()
	profile.load_config(ConfigFile.new(), 10000)
	var all_locked := true
	for item in Catalog.PREMIUM:
		all_locked = all_locked and not profile.is_unlocked(item.id) and not profile.equip(item.id)
	check.call(all_locked, "High scores never unlock or equip paid cosmetics")
	var service := Billing.new()
	var fake := Fake.new()
	tree.root.add_child(service)
	service.add_child(fake)
	service.entitlement_changed.connect(profile.apply_store_entitlement)
	service.configure(false, fake)
	check.call(fake.owned_queries == 1 and fake.product_queries == 1, "Startup queries products and existing purchases")
	fake.query_product_details_response.emit(products())
	check.call(not service.can_buy(), "Buy waits until account ownership is reconciled")
	fake.query_purchases_response.emit({"response_code":0,"purchases":[]})
	check.call(service.can_buy() and service.price_label == "US$1.99", "Store price and non-consumable buy option load")
	service.buy()
	check.call(fake.launches == 1 and not profile.premium_owned, "Launching a purchase does not unlock the pack")
	service.buy()
	check.call(fake.launches == 1, "Duplicate taps cannot start a second payment flow")
	fake.on_purchase_updated.emit({"response_code":1})
	check.call(not profile.premium_owned and not service.busy, "Cancelled purchase stays locked and releases busy state")
	service.buy()
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt("pending-test",2)]})
	check.call(not profile.premium_owned and service.pending and not service.can_buy(), "Pending purchase stays locked and cannot be repurchased")
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt()]})
	await tree.process_frame
	check.call(profile.premium_owned and not service.pending, "Completed SDK purchase unlocks premium cosmetics")
	check.call(fake.acknowledgements == ["test-only-token"], "Completed non-consumable is acknowledged, never consumed")
	fake.acknowledge_purchase_response.emit({"response_code":0,"token":"test-only-token"})
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt()]})
	await tree.process_frame
	check.call(fake.acknowledgements.size() == 1, "Duplicate purchase callbacks do not repeat acknowledgement")
	service.buy()
	check.call(fake.launches == 2, "Already-owned pack cannot be charged again")
	var all_owned := true
	for item in Catalog.PREMIUM:
		all_owned = all_owned and profile.is_unlocked(item.id) and profile.equip(item.id)
	check.call(all_owned, "One completed pack purchase unlocks all ten styles individually")
	var save := ConfigFile.new()
	profile.write_config(save)
	var restarted := Progress.new()
	restarted.load_config(save, 0)
	check.call(restarted.premium_owned and restarted.equipped == profile.equipped, "Cached ownership and equipped paid styles survive an offline restart")
	fake.query_purchases_response.emit({"response_code":12})
	check.call(profile.premium_owned, "Network restore errors preserve offline cached ownership")
	fake.query_purchases_response.emit({"response_code":0,"purchases":[]})
	check.call(not profile.premium_owned and profile.equipped == Catalog.DEFAULTS, "Successful empty ownership query revokes stale cache and resets premium equipment")
	service.restore()
	fake.query_purchases_response.emit({"response_code":0,"purchases":[receipt("restored-test",1,true)]})
	await tree.process_frame
	check.call(profile.premium_owned and fake.acknowledgements.size() == 1, "Restored acknowledged purchase unlocks without charging or acknowledging twice")
	fake.query_purchases_response.emit({"response_code":0,"purchases":[]})
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt("restored-test",1,true)]})
	await tree.process_frame
	check.call(profile.premium_owned, "A previously seen valid token can restore ownership after account reconciliation")
	fake.query_purchases_response.emit({"response_code":0,"purchases":[]})
	var bad := receipt("wrong-package")
	bad.package_name = "another.app"
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[bad]})
	await tree.process_frame
	check.call(not profile.premium_owned, "Wrong-package receipt cannot unlock content")
	bad = receipt("wrong-product")
	bad.product_ids = ["another_product"]
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[bad]})
	check.call(not profile.premium_owned, "Unrelated purchase cannot unlock the pack")
	bad = receipt("missing-fields")
	bad.erase("signature")
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[bad]})
	check.call(not profile.premium_owned, "Incomplete purchase result cannot unlock the pack")
	fake.on_purchase_updated.emit({"response_code":6})
	check.call(not profile.premium_owned and not service.busy, "Billing failure leaves paid content locked")
	var old_queries: int = fake.owned_queries
	fake.on_purchase_updated.emit({"response_code":7})
	check.call(fake.owned_queries == old_queries + 1 and not profile.premium_owned, "Already-owned error triggers restore rather than granting from an error code")
	fake.query_purchases_response.emit({"response_code":0,"purchases":[]})
	service.server_verifier = reject_verification
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt("backend-rejected")]})
	await tree.process_frame
	check.call(not profile.premium_owned, "Future server-verification hook can reject a completed SDK purchase")
	service.server_verifier = Callable()
	fake.on_purchase_updated.emit({"response_code":0,"purchases":[receipt("ack-retry")]})
	await tree.process_frame
	fake.acknowledge_purchase_response.emit({"response_code":12,"token":"ack-retry"})
	check.call(service._retry_ack.has("ack-retry") and profile.premium_owned, "Failed acknowledgement is retained for retry without charging again")
	service._retry_ack["ack-retry"] = 0.0
	service._process(0)
	check.call(fake.acknowledgements.count("ack-retry") == 2, "Acknowledgement retry uses the existing purchase token")
	fake.disconnected.emit()
	check.call(not service.can_buy() and profile.premium_owned, "Disconnection disables purchases but preserves existing offline styles")
	service.queue_free()
	await tree.process_frame
