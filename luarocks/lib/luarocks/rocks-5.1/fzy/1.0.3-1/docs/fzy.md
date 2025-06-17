# fzy-lua

A Lua module for the [fzy][] fuzzy string matching algorithm.

[fzy]: https://github.com/jhawthorn/fzy


## Summary

| function                      | description                                       |
|-------------------------------|---------------------------------------------------|
| `has_match(needle, haystack)` | Check if `needle` is a subsequence of `haystack`. |
| `score(needle, haystack)`     | Compute a score for a matching `needle`.          |
| `positions(needle, haystack)` | Compute the locations where fzy matches a string. |
| `filter(needle, haystacks)`   | Match many strings at once.                       |


## Functions

### `fzy.has_match(needle, haystack[, case_sensitive])`

Check if `needle` is a subsequence of `haystack.`

``` lua
> fzy.has_match("ab", "acB")
true
> fzy.has_match("ab", "ac")
false
> fzy.has_match("ab", "acB", true)
false
```

**Parameters**
* **needle** (*string*)
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *bool*


### `fzy.score(needle, haystack[, case_sensitive])`

Get a score for a needle that matches a haystack.

> **Warning**
> The `needle` must be a subsequence of the `haystack`! This is verified by
> using the `has_match` function. These functions are split for performance
> reasons. Either use `has_match` before each use of `score`, or use the
> `filter` function to do it automatically.

**Parameters**
* **needle** (*string*): must be a subsequence of `haystack`, or the result is
  undefined.
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *number*, where higher numbers indicate better matches.

``` lua
> fzy.score("amuser", "app/models/user.rb")
5.595
> fzy.score("amuser", "app/models/customer.rb")
3.655
```


### `fzy.positions(needle, haystack[, case_sensitive])`

Determine where each character of the `needle` is matched to the `haystack` in
the optimal match.

> **Warning**
> The `needle` must be a subsequence of the `haystack`! This is verified by
> using the `has_match` function. These functions are split for performance
> reasons. Either use `has_match` before each use of `positions`, or use the
> `filter` function to do it automatically.

**Parameters**
* **needle** (*string*): must be a subsequence of `haystack`, or the result is
  undefined.
* **haystack** (*string*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* **indices** (*{int, ...}*), where `indices[n]` is the location of the `n`th
  character of `needle` in `haystack`.
* **score**  (*number*): the same matching score returned by `score`

``` lua
> fzy.positions("amuser", "app/models/user.rb")     -- { 1, 5, 12, 13, 14, 15 }
--                         ^   ^      ^^^^
> fzy.positions("amuser", "app/models/customer.rb") -- { 1, 5, 13, 14, 18, 19 }
--                         ^   ^       ^^   ^^
```


### `fzy.filter(needle, haystacks[, case_sensitive])`

Apply the `has_match` and `positions` functions to an array of `haystacks`.
For large numbers of haystacks, this will have better performance than
iterating over the `haystacks` and calling those functions for each string.

``` lua
> a = fzy.filter('ab', {'*ab', 'b', 'a*b'})
> require'pl.pretty'.write(a, '')
{{1,{2,3},0.995},{3,{1,3},0.89}}
```

**Parameters**
* **needle** (*string*): unlike the other functions, the `needle` need not be
  a subsequence of any of the strings in the `haystack`.
* **haystacks** (*{string, ...}*)
* **case_sensitive** (*bool, optional*) – defaults to false

**Returns**
* *{{idx, positions, score}, ...}*, an array with one entry per matching line
  in `haystacks`, each entry giving the index of the line in `haystacks` as
  well as the equivalent to the return value of `positions` for that line.

``` lua
> haystacks = {'cab', 'ant/bat/cat', 'ant/bat/ace'}
> needle = 'abc'
> fzy.filter(needle, haystacks)
-- { {2, {1, 5, 9}, 2.63}, {3, {1, 5, 10}, 1.725} }
```


## Special Values

`fzy.get_score_min()`: The lowest value returned by `score`, which is only returned
for an empty `needle`, or a `haystack` longer than than `get_max_length`.

`fzy.get_score_max()`: The score returned for exact matches. This is the
highest possible score.

`fzy.get_max_length()`: The maximum length of a `haystack` for which `fzy` will
evaluate scores.

`fzy.get_score_floor()`: For matches that don't return `get_score_min`, their
score will be greater than than this value.

`fzy.get_score_ceiling()`: For matches that don't return `get_score_max`, their
score will be less than this value.

`fzy.get_implementation_name()`: The name of the currently-running
implementation, "lua" or "native".


## Implementations

The lua implementation of fzy is in `fzy_lua`, and the C implementation is in
`fzy_native`. When you `require('fzy')`, it automatically loads the native
version. If that fails, it will fall back on the lua version. This is transparent;
in either case, all functions will be available as `fzy.*`.


## FAQ

This library isn't popular enough to have *frequently* asked questions, but this
has come up:

> Why not just call `has_match` inside `score` and `positions`?

This implementation of `fzy` was originally written for use in text editors.
When you visually update the results of fuzzy finding across a large codebase
with every keypress, every nanosecond counts. Those applications want to
separate the matching, scoring, and position highlighting functions. Unless you
know you have reason to do otherwise, I recommend using the `filter` function.
