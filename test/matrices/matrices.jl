

A = [-2 3; 3 -4]
B = [4 3; 3 2]

# [-2 3] * [4,3]
# -2 * 4 + 3 * 3
# -8 + 9
# 1
assert(1 == ([-2 3] * [4,3])[1])

# [-2 3] * [3, 2]
# -2 * 3 + 3 * 2
# -6 + 6
# 0
assert(0 == ([-2 3] * [3, 2])[1])


# [3 -4] * [4, 3]
3 * 4 + -4 * 3
12 + -12
# 0
assert(0 == ([3 -4] * [4, 3])[1])


# [3 -4] * [3, 2]
# 3 * 3 + -4 * 2
# 9 + -8
# 1
assert(1 == ([3 -4] * [3, 2])[1])

A * B

#  not to confuse with pointwise matrix multiplication
A .* B

A' * (A * B)

# this is always possible
A' * A

A * A'
