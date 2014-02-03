###
Stolen from: http://forrst.com/posts/Longest_Common_Subsequence_in_JavaScript-mQB

Find a longest common subsenquence.
Note: this is not necessarily the only possible longest common subsequence though!
###
lcs = (listX, listY) ->
  lcsBackTrack lcsLengths(listX, listY), listX, listY, listX.length, listY.length

###
Iteratively memoize a matrix of longest common subsequence lengths.
###
lcsLengths = (listX, listY) ->
  lenX = listX.length
  lenY = listY.length
  
  # Initialize a lenX+1 x lenY+1 matrix
  memo = [lenX + 1]
  i = 0

  while i < lenX + 1
    memo[i] = [lenY + 1]
    j = 0

    while j < lenY + 1
      memo[i][j] = 0
      j++
    i++
  
  # Memoize the lcs length at each position in the matrix
  i = 1

  while i < lenX + 1
    j = 1

    while j < lenY + 1
      if listX[i - 1] is listY[j - 1]
        memo[i][j] = memo[i - 1][j - 1] + 1
      else
        memo[i][j] = Math.max(memo[i][j - 1], memo[i - 1][j])
      j++
    i++
  memo

lcsLength = (listX, listY) ->
  lengths = lcsLengths(listX, listY)
  x = lengths.length - 1
  lengths[x][lengths[x].length - 1]

###
Recursively read back a memoized matrix of longest common subsequence lengths
to find a longest common subsequence.
###
lcsBackTrack = (memo, listX, listY, posX, posY) ->
  # base case
  if posX is 0 or posY is 0
    ""
  # matcth => go up and left
  else if listX[posX - 1] is listY[posY - 1]
    lcsBackTrack(memo, listX, listY, posX - 1, posY - 1) + listX[posX - 1]
  else
    # go up
    if memo[posX][posY - 1] > memo[posX - 1][posY]
      lcsBackTrack memo, listX, listY, posX, posY - 1
    # go left
    else
      lcsBackTrack memo, listX, listY, posX - 1, posY

exports.lcsLength  = lcsLength