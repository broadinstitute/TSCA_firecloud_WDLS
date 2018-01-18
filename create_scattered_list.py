def print_scattered_interval_list(num_intervals):
	for i in range(1, num_intervals+1):
		print ("\"scattered/temp_00%02d_of_%s/scattered.interval_list\"," %(i, num_intervals))

print_scattered_interval_list(20)