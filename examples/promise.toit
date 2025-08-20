
main:
	print "Promise-like example in Toit using lists of function objects."
	actions := [
		fn:
			print "Step 1: Hello 1"
		end,
		fn:
			print "Step 2: Hello 2"
		end,
		fn:
			async_action "Step 3: Simulated async"
		end,
		fn:
			error_action "Step 4: Simulated error"
		end
	]
	await_all actions
	print "All actions complete."

async_action msg:
	# Simulate an async action (just prints after a delay)
	print msg + " (starting async...)"
	sleep --ms=200
	print msg + " (async done)"

error_action msg:
	# Simulate an action that throws an error
	print msg + " (about to throw error)"
	raise "Simulated error in: " + msg

await_all actions:
	for action in actions:
		try:
			action()
		catch err:
			print "Caught error: " + err.to_string