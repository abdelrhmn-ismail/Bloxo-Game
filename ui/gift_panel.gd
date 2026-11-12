class_name GiftPanel
extends OverlayPanel
## Pop-up for daily / hourly gifts. Emits `closed` once, then removes itself.

signal closed

var _closed := false


func close() -> void:
	if _closed:
		return
	_closed = true
	closed.emit()
	queue_free()
