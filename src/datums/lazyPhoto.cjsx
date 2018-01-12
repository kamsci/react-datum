
React = require('react')
Datum = require('./datum')
Options = require('../options')


###
  This is a lazy loading image.

  To prevent a page heavily loaded with images preventing other content from loading, a small
  blank image is downloaded and rendered first and then onLoad the real image src is used and
  rerender.

  On error a notFoundUrl is set as the image src to prevent broken image display.

  The model attribute specified in @props.attr should return a fully qualified
  url.  The image is only rendered if it's visible and in view. Otherwise the placeholder
  image is rendered.
###
module.exports = class LazyPhoto extends Datum
  @displayName: "react-datum.LazyPhoto"

  subClassName: 'lazy-image'

  initialLoadComplete: false
  
  
  componentWillMount: () ->
    super
    @setState notFound: false
    
  
  isEditable: -> false
  
  
  # override
  renderForDisplay: () ->
    modelValue = @getModelValue()
    notFound = if !modelValue? then true else @state.notFound
    notFoundUrl = Options.get('LazyPhoto').notFoundUrl 
    source = if notFound then notFoundUrl else modelValue
    
    # console.log "LazyPhoto rendering: src=#{source} this=", this
    <img src={source}
         onLoad={@onLoad}
         onError={@onError}
    />


  onLoad: (evt) =>
    return if @initialLoadComplete || @notFound
    # TODO : should this be state?
    @initialLoadComplete = true


  onError: (evt) =>
    return if @state.notFound   
    @setState notFound: true
    
    
  onModelValueChange: () ->
    # force img tag to retry and find file
    @setState notFound: false
    super

