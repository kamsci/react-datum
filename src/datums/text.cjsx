
React = require('react')
_ = require('underscore')

Datum = require('./datum')


###
  see ./text.md
###
module.exports = class Text extends Datum
  @displayName: "react-datum.Text"

  
  @propTypes: _.extend {}, Datum.propTypes,
    # set to true if rendering known, safe, html.  
    # see https://facebook.github.io/react/tips/dangerously-set-inner-html.html. 
    displayAsHtml: React.PropTypes.bool
    
    # set ellipsizeAt to false to display whole value. Only effects 'readonly' display
    # values displayed in 'edit' mode are never truncated.
    ellipsizeAt: React.PropTypes.oneOfType([
      React.PropTypes.number
      React.PropTypes.bool
    ])
    # If we want the ellipsis to be like ...Long Name we need to make this true
    reverseEllipsis: React.PropTypes.bool
    
    # when displaying array values, only show unique
    uniqueArrayMembers: React.PropTypes.bool


  @defaultProps: _.extend {}, Datum.defaultProps,
    # ellipsizeAt is defaulted to prevent really long strings from breaking layouts
    ellipsizeAt: 35
    reverseEllipsis: false

  constructor: ->
    super
    

  render: ->
    super    # for breakpoint debugging


  renderValueForDisplay: ->
    superValue = super
    value = switch
      when _.isArray(superValue) 
        values = _.compact(_.flatten(superValue))
        values = _.unique(values) if @props.uniqueArrayMembers
        values.join(', ')
      when _.isObject(superValue) then JSON.stringify(superValue)
      else superValue.toString()
    
    @renderEllipsizedValue value

  
  ### 
    Extends Datum#renderWrappedDisplayValue to provide support for displayAsHtml
    option.
  ###
  renderWrappedDisplayValue: (value)->
    if @props.displayAsHtml
      <span className="datum-display-value" dangerouslySetInnerHTML={@getMarkup(value)}/>
    else
      super
      

  getMarkup: (value) ->
    return {__html: value}