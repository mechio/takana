/*
Source: http://forrst.com/posts/Longest_Common_Subsequence_in_JavaScript-mQB

Find a longest common subsenquence.
Note: this is not necessarily the only possible longest common subsequence though!
*/
let lcs = (listX, listY) => lcsBackTrack(lcsLengths(listX, listY), listX, listY, listX.length, listY.length);

/*
Iteratively memoize a matrix of longest common subsequence lengths.
*/
var lcsLengths = function(listX, listY) {
  let lenX = listX.length;
  let lenY = listY.length;
  
  // Initialize a lenX+1 x lenY+1 matrix
  let memo = [lenX + 1];
  let i = 0;

  while (i < lenX + 1) {
    memo[i] = [lenY + 1];
    var j = 0;

    while (j < lenY + 1) {
      memo[i][j] = 0;
      j++;
    }
    i++;
  }
  
  // Memoize the lcs length at each position in the matrix
  i = 1;

  while (i < lenX + 1) {
    var j = 1;

    while (j < lenY + 1) {
      if (listX[i - 1] === listY[j - 1]) {
        memo[i][j] = memo[i - 1][j - 1] + 1;
      } else {
        memo[i][j] = Math.max(memo[i][j - 1], memo[i - 1][j]);
      }
      j++;
    }
    i++;
  }
  return memo;
};

let lcsLength = function(listX, listY) {
  let lengths = lcsLengths(listX, listY);
  let x = lengths.length - 1;
  return lengths[x][lengths[x].length - 1];
};

/*
Recursively read back a memoized matrix of longest common subsequence lengths
to find a longest common subsequence.
*/
var lcsBackTrack = function(memo, listX, listY, posX, posY) {
  // base case
  if (posX === 0 || posY === 0) {
    return "";
  // matcth => go up and left
  } else if (listX[posX - 1] === listY[posY - 1]) {
    return lcsBackTrack(memo, listX, listY, posX - 1, posY - 1) + listX[posX - 1];
  } else {
    // go up
    if (memo[posX][posY - 1] > memo[posX - 1][posY]) {
      return lcsBackTrack(memo, listX, listY, posX, posY - 1);
    // go left
    } else {
      return lcsBackTrack(memo, listX, listY, posX - 1, posY);
    }
  }
};

module.exports = { lcsLength: lcsLength };