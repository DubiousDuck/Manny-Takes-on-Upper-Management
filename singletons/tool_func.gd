extends Node

## Global class for useful tool functions

func get_permutations(arr: Array) -> Array:
	if arr.size() <= 1:
		return [arr.duplicate()]
	
	var result = []
	for i in arr.size():
		var rest = arr.duplicate()
		var elem = rest.pop_at(i)
		for perm in get_permutations(rest):
			result.append([elem] + perm)
	print("resulting permuations: " + str(result))
	return result
