extends Object

class_name PriorityQueue

const INT_MAX = 9223372036854775807
const INT_MIN = -INT_MAX

var elements : Array = []
var size : int = 0

func swap(arr : Array, a : int, b : int):
	var temp = arr[a]
	arr[a] = arr[b]
	arr[b] = temp

func get_parent(index : int):
	return (index - 1) / 2

func get_left_child(index : int):
	return 2 * index + 1

func get_right_child(index : int):
	return 2 * index + 2

# Pushes a new entry onto the PQ
func push(element : PQEntry):
	size += 1
	var index = size - 1
	if elements.size() > index:
		elements[index] = element
	else:
		elements.append(element)
	while index != 0 && elements[get_parent(index)].priority > elements[index].priority:
		swap(elements, index, get_parent(index))
		index = get_parent(index)

func decrease_key(index : int, value : int):
	if value >= elements[index].priority:
		return
	elements[index].priority = value
	while index != 0 && elements[get_parent(index)].priority > elements[index].priority:
		swap(elements, index, get_parent(index))
		index = get_parent(index)

# Extract the minimal entry (aka the root)
func pop():
	if size <= 0:
		return INT_MAX
	if size == 1:
		size -= 1
		return elements[0]
	var root = elements[0]
	elements[0] = elements[size - 1]
	size -= 1
	min_heapify(0)
	return root

func delete_key(index : int):
	decrease_key(index, INT_MIN)
	pop()

func min_heapify(index : int):
	var left_child = get_left_child(index)
	var right_child = get_right_child(index)
	var right_index = index
	if left_child < size && elements[left_child].priority < elements[index].priority:
		right_index = left_child
	if right_child < size && elements[right_child].priority < elements[right_index].priority:
		right_index = right_child
	if right_index != index:
		swap(elements, index, right_index)
		min_heapify(right_index)

func empty() -> bool:
	return size <= 0

# Returns the top of the PQ (aka the root) without removing it
func top():
	if size <= 0:
		return INT_MAX
	return elements[0]
