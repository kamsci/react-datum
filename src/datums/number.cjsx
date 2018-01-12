
React = require('react')
_ = require('underscore')

Datum = require('./datum')


ONE_BILLION = 1000000000
ONE_MILLION = 1000000
ONE_THOUSAND = 1000

RECOGNIZED_FORMATS = ['abbreviate','money','comma', 'percent']

###
  For real numbers.

  Only allows `/^\-?[0-9]*\.?[0-9]*$/` on input
###
module.exports = class Number extends Datum
  @displayName: "react-datum.Number"

  @propTypes: _.extend {}, Datum.propTypes,
    
    # format only effects display, not input.  Possible values:
    #
    # 'abbreviate' - Add M and K to numbers greater than 1 million and 1 thousand respectively
    # 'money' - display dollar sign and two decimal places zero filled
    # 'comma' - add comma separators at thousands
    # 'percent' - multiply by 100 and postfix '%'
    #
    # can be an array of formats or a single string format
    format: React.PropTypes.oneOfType [
      React.PropTypes.array
      React.PropTypes.string
    ]
    
    # rounds value to n decimal places
    decimalPlaces: React.PropTypes.number
    
    # if decimalPlaces, zeroFill={true} will round out to n places 
    zeroFill: React.PropTypes.bool
    
    # when input, validate value is at least this value on change. 
    # Can also be specified via metadata.
    minValue: React.PropTypes.number
    
    # when input, validate value is at most this value on change
    # Can also be specified via metadata.
    maxValue: React.PropTypes.number
    
  
  @defaultProps: _.extend {}, Datum.defaultProps,
    # Exceptional case: when format='money' is used without format='abbreviate',
    # this defaults to 2
    decimalPlaces: null
    
    # Exceptional case: when format='money' is used without format='abbreviate',
    # this defaults to 2, you can however change the money behavior by explicitly
    # setting zerofill to false
    zeroFill: null
    
    # This might be controversial, but our standard here at the zoo is to always use
    # thousand ticks
    format: ['comma']
    

  # TODO : push down this feature to Datum? with default to all   
  # will not allow characters to be entered that do not match this pattern
  charactersMustMatch: /^\-?[0-9]*\.?[0-9]*$/


  @getComaAddedValue: (value) ->
    # add thousands separater
    [wholeNumber, decimal] = value.toString().split('.')
    value = wholeNumber.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    value += '.' + decimal if decimal?

    return value
    
    
  ###
    fail proof conversion from sting to float that will never return NaN
  ###
  @safelyFloat: (value) ->
    return 0 unless value?
    try
      floatValue = parseFloat(value)
    catch
      console.error "unparseable float #{value}"
      return 0
      
    return if _.isNaN(floatValue) then 0 else floatValue
    



  constructor: (props) ->
    super
    @addValidations [
      # even though we don't allow key entry of non numeric patterns, Datum exposes
      # setValue() which can be called from outside to set the value of the datum
      @validateNumeric
      @validateMin
      @validateMax
    ]

  isAcceptableInput: (value) ->
    return value.match(@charactersMustMatch)

  ###
    overrides super - adds formatting
  ###
  renderValueForDisplay: ->
    modelValue = @getModelValue()
    value = parseFloat(modelValue)
    return modelValue if _.isNaN value
      
    formats = @getFormats()

    if 'percent' in formats
      value *= 100
      
    # we are going to convert the value to a string now.  All 
    # numberic processing should precede this comment
    value = @roundToDecimalPlaces(value, formats: formats)

    # at this point, value is a string with 4 decimal places zero filled
    # all formatting that works on the text value goes after here
    value = @abbreviate(value, formats)
    value = @addCommas(value, formats)
    value = @monetize(value, formats)

    if 'percent' in formats
      value += "%"

    return value


  # extends super
  renderPlaceHolder: ->
    if @getPropOrMetadata('placeholder')?
      super
    # if we don't have a placeholder, render zero by default without the placeholder classes
    return <span>0</span>
    
    
  getValueForInput: ->
    value = super
    value = value.replace(/[\s\$\,]/g, '') if value? && _.isString(value)
    return value if value in ['-', '+']
    floatVal = parseFloat(value)
    # note that we don't return the floatVal because when user is typing and gets to say, 55.
    # that would get floated to just 55 and the . would never get to the input.
    return if _.isNaN floatVal then '' else value

    
  getFormats: ->
    if _.isArray(@props.format) 
      return @props.format 
    else 
      return @props.format?.toString().split(' ') || []
      
      
  # extend super, ignore invalid input characters
  onChange: (event) =>
    inputValue = event.target.value
    if @isAcceptableInput(inputValue)
      super


  validateNumeric: (value) =>
    return true if @charactersMustMatch.test(value)
    if value.length > 25
      value = value.slice(0, 25) + '...'
    return "The value must be numeric. \"#{value}\" is not valid"
  
  
  validateMin: (value) =>
    minValue = @getPropOrMetadata('minValue')
    return true unless minValue?
    return true if value >= minValue
    return "The value must be greater than or equal to #{minValue}"


  validateMax: (value) =>
    maxValue = @getPropOrMetadata('maxValue')
    return true unless maxValue?
    return true if value <= maxValue
    return "The value must be less than or equal to #{maxValue}"
    
    
  ###  
    returns a string with number value input rounded to user requested props.decimalPlaces 
      and optionally zeroFilled if @props.zeroFill == true
    note that 'money', when not 'abbreviate'd should zero fill out to two decimal places 
    unless props indicate otherwise
  ###
  roundToDecimalPlaces: (value, options={}) ->
    options = _.defaults options,
      formats:  @getFormats()
      decimalPlaces: @props.decimalPlaces
      zeroFill: @props.zeroFill
    
    if 'money' in options.formats
      options.decimalPlaces ?= 2
      options.zeroFill ?= !('abbreviate' in options.formats)
      
    if options.decimalPlaces?
      value = parseFloat(value).toFixed(options.decimalPlaces)
      unless options.zeroFill
        value = parseFloat(value).toString()
        
    return value
    
  ###  
    returns a string with number value abbreviated and rounded to user 
    requested props.decimalPlaces 
  ###  
  abbreviate: (value, formats=@getFormats()) ->
    if 'abbreviate' in formats
      value = parseFloat(value)
      absValue = Math.abs(value)
      [value, affix] = if absValue >= ONE_BILLION
        [value / ONE_BILLION, "B" ]
      else if absValue >= ONE_MILLION
        [value / ONE_MILLION, "M" ]
      else if absValue >= ONE_THOUSAND
        [value / ONE_THOUSAND, "K"]
      else
        [value, ""]

      value = "#{@roundToDecimalPlaces(value, formats: formats)}"
      value += " #{affix}" if affix?.length > 0
        
    return value
        
        
  addCommas: (value, formats=@getFormats()) ->
    if 'comma' in formats
      value = Number.getComaAddedValue(value)

    return value

  ###
    If props.formats includes 'money', this method prepends the value
    displayed with '$'
    
    Override this method to do things like create an internationalized
    display of money value for another currency. 
  ###
  monetize: (value, formats=@getFormats()) ->
    if 'money' in formats
      value = "$#{value}"
    return value
    
    
  getInputValue: ->
    if isNaN(parseFloat(@state.value)) then return null
    return parseFloat(@state.value)

    
  
    