
React = require('react')
Number = require('./number')

###
  For whole numbers (no decimal input allowed).
###
module.exports = class WholeNumber extends Number
  
  @displayName: "react-datum.WholeNumber"

  charactersMustMatch: /^\-?[0-9]*$/

  getInputValue: ->
  	return parseInt(@state.value, 10)
