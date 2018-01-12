React = require('react')
Backbone = require('backbone')
_ = require('underscore')
Strhelp = require('bumble-strings')

Datum = require('../datum')

Select = require('react-select')

# See ./collectionPicker.md 
module.exports = class CollectionPicker extends Datum
  @displayName: "react-datum.CollectionPicker"
  
  @propTypes: _.extend {}, Datum.propTypes,
    #  TBD: Can also be the string name of a shared collection (see ../sharedCollection.cjsx)
    #  TBD: Can also accept an array of [{lable: "option 1", id: 1}, ...]
    #  
    #  Can also accept collection instance as context var via ReactDatum.Collection component. 
    #    prop has precendence
    collection: React.PropTypes.oneOfType([
      React.PropTypes.instanceOf(Backbone.Collection)
      React.PropTypes.string
      React.PropTypes.array
    ])
    
    # The selected values from the collection when in in display mode, can be individually
    # ellipsized. Set ellipsizeAt to false to display whole value. Only effects 'readonly' 
    # display; values displayed in 'edit' mode are never truncated.
    ellipsizeAt: React.PropTypes.oneOfType([
      React.PropTypes.number
      React.PropTypes.bool
    ])

    # If we want the ellipsis to be like ...Long Name we need to make this true
    reverseEllipsis: React.PropTypes.bool
    
    # Component for rendering the custom options
    optionComponent: React.PropTypes.func

    # Component for rendering the value options
    valueComponent: React.PropTypes.func

    # Attribute which indicates if we need to fetch the model if not found in collection.
    fetchUnknownModelsInCollection: React.PropTypes.bool

    #  Attribute value from model in lookup collection to render in inputMode='readonly'.
    #  if not specified, model.toString() will be displayed
    displayAttr: React.PropTypes.string
    
    #  attribute value from model in lookup collection to set as value on props.attr
    #  in props.model. If not specified, displayAttr is used
    optionSaveAttr: React.PropTypes.string.isRequired

    # react component to render when in inputMode='readonly'. 
    displayComponent: React.PropTypes.any

    # This is to be set if the loading need not happen asynchronously for every search.
    # External/collection fetch loading can happen for the first time.
    # If loading externally/using collection fetch, set loading prop to true until external load is complete.
    synchronousLoading: React.PropTypes.bool

    # This makes sense only in conjunction with synchronousLoading.
    # Set to true if loading externally until loading is complete.
    isLoading: React.PropTypes.bool
    
    #  Specify a callback to load suggestions asynchronously.  
    #  The callback method  should accept the following arguments: 
    #    `(collection, userInput, ayncOptions, doneCallback)` 
    #  where 
    #    `collection` is the value of the collection prop
    #    `userInput` is the what the user has entered so far  
    #    `doneCallback` is a method to be called with `(error, data)` when data is ready.
    #        the first argument, `error` should be false or an error that will be thrown
    #        `data` argument should be an array of Backbone.Models or array of 
    #              {label: "string", value: "string"} pairs
    #    `asyncOptions` is the options object passed via prop to CollectionPicker
    #
    #  Note that internally, CollectionPicker always renders a Select.Async when inputMode='edit' 
    #  and provides an internal loadOptions method to pull suggestions from the models in 
    #  the lookup collection. 
    #  
    #  *Where do they all come from?*  
    #  
    #  We will use the returned filtered set of models from the first of following chain (in order) 
    #  to exist:
    #    **props.asyncSuggestionCallback** - this prop
    #    **Collection.filterForPicker()**  - if we find a method on the collection called 
    #      'filterForPicker' - it will be called with `(userInput, doneCallback, asyncOptions)`
    #      and should return an array of models to render suggestions from 
    #    **Internal filter** (this.filterOptions(userInput, doneCallback)) seaches through the 
    #      props.optionDisplayAttr of models currently in the collection to find suggestions based on 
    #      userInput and groups results
    #  TODO : tests!
    asyncSuggestionCallback: React.PropTypes.func
    
    #  Options above are proprietary to the CollectionPicker component.
    #  
    #  Remaining options are passed through to react-select, see # [react-select](https://github.com/JedWatson/react-select)
    #  
    #  You can use any of the options supported by react-select Select and Select.Async, 
    #  *except for the loadOptions prop* of Select.Async.  
    #
    #  see # [react-select](https://github.com/JedWatson/react-select) for additional props    
    #   
    #  can accept and display multiple values.  If this prop is set, we assume that 
    #  value of our @props.model.get(@props.attr) returns the IDs either as an
    #  array or comma separated value.  
    multi: React.PropTypes.bool
    
    # Ignored unless multi==true, display value as comma separated values instead of tags when inputMode='readonly'
    csvDisplay: React.PropTypes.bool

    # editPlaceholder will be useful in inlineEdit mode when you want to display a 
    # placeholder text which is different from the placeholder which you display before the select editor is displayed
    editPlaceholder: React.PropTypes.string
    
    # if setAsString and multi, set the value of the model as a comma delimited string instead of array of values
    setAsString: React.PropTypes.bool
    
    # if true, displays the model value in when in display mode without collection lookup  
    displayModelValue: React.PropTypes.bool
     

  @defaultProps: _.extend {}, Datum.defaultProps,
    # ellipsizeAt is defaulted to prevent really long strings from breaking layouts
    ellipsizeAt: 35
    fetchUnknownModelsInCollection: true
    loading: false
    # This is required as this is used to set the value to model which is shown on the picker.
    attr: 'value'


  @contextTypes: _.extend {}, Datum.contextTypes,
    # see @proptypes.collection above 
    collection: React.PropTypes.oneOfType([
      React.PropTypes.instanceOf(Backbone.Collection)
      React.PropTypes.string
    ])  

  subClassName: "collection-picker"
  selectRef: "reactSelect"


  constructor: ->
    super
    

  initializeState: ->
    @state = {
      value: @getModelValue()
      errors: []
    }


  render: ->
    super
    

  #override - if multi, returns an array of values that renderEllipsizeValue wraps in spans
  renderValueForDisplay: ->
    collection = @getCollection() 
    modelValues = @getModelValue()
    # A CSV model value return is also accepted.
    # TODO : consider expanding this to include non numeric 
    if _.isString(modelValues) and modelValues.match(/\d+\,\s*\d+/)
      modelValues = modelValues.split(/\,\s?/)
      
    modelValues = [modelValues] unless _.isArray modelValues
    modelValues = _.compact(_.unique(_.flatten(modelValues)))
    if @props.csvDisplay
      collectionValues = modelValues.map (modelId) => 
        @getCollectionModelDisplayValue(modelId, collection) ? modelId
      @renderEllipsizedValue(collectionValues.join(', ')) 
    else
      modelValues.map (modelValue) =>
        @renderCollectionDisplayValue(modelValue, collection)
  
  
  renderCollectionDisplayValue: (modelId, collection=@getCollection()) ->
    modelValue = @getCollectionModelDisplayValue(modelId, collection)
    modelValue = @renderEllipsizedValue(modelValue) if modelValue

    valueProps = {
      key: modelValue
      className: "collection-picker-display-value"
    }

    if @props.displayComponent?
       valueProps.value = @_getCollectionModelById(modelId)
       return <@props.displayComponent {... valueProps}/>

    return <span  {... valueProps}>
      {modelValue || @renderPlaceholder() || "unknown"}
    </span>
    

  #override
  renderInput: ->
    if @props.synchronousLoading
      <Select {... @getSelectOptions()}/>
    else
      <Select.Async {... @getSelectAsyncOptions()}>
        {
          (props) => 
            collection = @getCollection()
            # if the user provided a filter method don't allow react-select to filter
            props.filterOptions = null if collection.filterForPicker? || @props.asyncLoadCallback? 
            # prevent react-select from blanking the value while the user types
            props.value = @getValueForInput()  
            props.ref = 'select'
            return <Select {... props}/>
        }
      </Select.Async>


  getCollection: ->
    collection = @props.collection || @context.collection
    console.warn(@constructor.displayName + " requires a collection prop or context. attr=#{@props.attr}") unless collection?
    unless collection instanceof Backbone.Collection
      return new Backbone.Collection(collection)
    
    return collection
  
  ###
    TODO: make this method public.  useful for extensions and used by some
  ###
  _getCollectionModelById: (modelOrId) ->
    if _.isNumber(modelOrId) or _.isString(modelOrId)
      collectionModel = @getCollection()?.get modelOrId, add: @props.fetchUnknownModelsInCollection
      onSync = =>
        _.defer => @_onFirstCollectionModelSync(collectionModel)
        collectionModel?.off?('sync', onSync)
        
      collectionModel?.on?('sync', onSync)
      return collectionModel
      
    return modelOrId
    
  
  _onFirstCollectionModelSync: (collectionModel) =>
    @getModel()?.trigger?('invalidate')
    @forceUpdate()
    
  
  getCollectionModelDisplayValue: (modelId, collection) ->
    return null unless modelId 
    return modelId.toString() if @props.displayModelValue
    
    model = @_getCollectionModelById(modelId)
      
    if model? 
      if !_.isFunction(model.toString) && !@props.displayAttr?
        throw new Error(@constructor.displayName + ": You need to specify a displayAttr prop or model must have toString() method")
      
      displayValue = if @props.displayAttr? 
        model.get?(@props.displayAttr) ? model[@props.displayAttr] 
      else 
        model.toString?()
    
    else
      displayValue = null
    
    return displayValue
    

  getOptionSaveValue: (modelId, collection) ->
    model = @_getCollectionModelById(modelId)
    if model? && !@props.optionSaveAttr?
      return model.id 
    
    return model?.get?(@props.optionSaveAttr) ? model?[@props.optionSaveAttr] ? model?.id ? modelId
    

  # extends Datum - if multi mode, always returns an array
  getModelValue: (newProps = @props) ->
    modelValue = super
    if newProps.multi
      modelValue = switch 
        when (not modelValue?) then []
        when _.isString(modelValue) then modelValue.split(',')
        when _.isArray(modelValue) then modelValue
        else 
          [modelValue]
      
      modelValue = _.compact(_.unique(_.flatten(modelValue)))
    
    return modelValue


  getSelectOptions: () ->
    collection = @getCollection()
    return _.extend {}, @props,
      placeholder: @props.editPlaceholder || @getPropOrMetadata('placeholder') || @renderPlaceholder()
      value: @getValueForInput()
      onChange: @onChange
      onBlur: @onBlur
      options: @getOptionValuesForReactSelect(collection.models)
      labelKey: "label"
      valueKey: "value"
      ref: @selectRef


  getSelectAsyncOptions: () ->
    collection = @getCollection()
    selectOptions = @getSelectOptions()
    if @props.asyncSuggestionCallback?
      delete selectOptions.options
      
    return _.extend selectOptions,
      loadOptions: @onLoadOptions


  # TODO : explain this override
  hasInputValueChanged: ->
    @getInputValue() != @getModelValue()
      

  getInputComponent: () =>
    @refs?[@selectRef]

  
  getSelectedModels: () ->
    return @getCollection()?.get(@getInputValue())


  focus: () =>
    @getInputComponent()?.focus?()


  getOptionValuesForReactSelect: (models = []) =>
    return _.map models, (m) => return {
      label: @getCollectionModelDisplayValue(m) 
      value: @getOptionSaveValue(m)
      model: m # We need this data if we have optionRenderes or optionComponents
    }    
      
  
  ###
   Extends Datum class - react-select returns array of options and not a synth event 
   super expects a synth event but only uses value.
   
   Also note that the value passed back to the usage through @props.onChange is
   the option object(s) for the currently selected option(s) 
  ###
  onChange: (optionsSelected) =>
    if @props.multi
      values = _.pluck(optionsSelected, 'value')
      # this works around an issue in react-select where when searching with already
      # selected values react-select would blank out the selections and leave with nothing
      if values.length == 1 && @state.value?.length > 0 && values[0] not in @state.value
        values = @state.value.concat values
        optionsSelected = @getOptionValuesForReactSelect(@getSelectedModels())
      values = values.join(',') if @props.setAsString
      super values, propsOnChangeValue: optionsSelected
    else
      value = if optionsSelected == null then null else optionsSelected?.value
      super value, propsOnChangeValue: optionsSelected
      
    

  # async callback for react-select      
  onLoadOptions: (userInput, callback) =>
    collection = @getCollection()
    selectedModels = _.compact(@getSelectedModels() ? [])
    
    # TODO : consider debouncing in here 
    # we may be debounce in the filtering methods below or they may take longer than 
    # then how fast the user can type.   ReactSelect will ignore calling anything but the 
    # last callback passed to this method. 
    @lastAsyncCallback = callback

    chainedCallback = (error, models) =>
      if arguments.length < 2
        models = error
        error = false
      models = @groupSuggestionModels(userInput, models)
      if @props.multi
        models = models.concat(selectedModels) 
        collection.add selectedModels   # make sure they are still in the collection too
      optionsForReactSelect = @getOptionValuesForReactSelect(models)
      @lastAsyncCallback(null, {options: optionsForReactSelect})
  
    switch
      when @props.asyncSuggestionCallback? then @props.asyncSuggestionCallback.call(@, collection, userInput, chainedCallback, @props.asyncOptions)
      when collection.filterForPicker? then collection.filterForPicker.call(@, userInput, chainedCallback, @props.asyncOptions)
      else @filterSuggestionModels(collection, userInput, chainedCallback, @props.asyncOptions)
    
    return null   # ReactSelect Async expects this to be a promise or null
    
    
  ### weak string compare userInput to suggestion model's display value ###
  filterSuggestionModels: (collection, userInput, callback) =>
    # filter to just those with match anywhere
    filteredModels = _.filter collection.models, (model) => 
      displayValue = @getCollectionModelDisplayValue(model)
      displayValue? && Strhelp.weaklyHas(displayValue, userInput)

    # sort all by display value alpha, case insensitive
    filteredModels = filteredModels.sort (a, b) =>
      Strhelp.weaklyCompare(@getCollectionModelDisplayValue(a), @getCollectionModelDisplayValue(b))

    callback?(filteredModels)
    return filteredModels


  # TODO  - this should be optional to allow presorted or custom sorted collections 
  groupSuggestionModels: (userInput, models) =>
    topHits = []
    bottomHits = []
    for model in models
      displayValue = @getCollectionModelDisplayValue(model)
      if displayValue? && Strhelp.weaklyStartsWith(displayValue, userInput)
        topHits.push model
      else
        bottomHits.push model
      
    return topHits.concat(bottomHits)


  ###
    This is the model associated with the collectionPicker. This is required to exist because
    this is the model in which the value is saved. If this does not exist or re-created every time we
    will not be able to show the value option on the picker.
  ###
  getModel: (newProps = @props, newContext = @context)->
    @valueModel = newProps?.model || newContext?.model || @valueModel || new Backbone.Model()
    return @valueModel


      
      
    
        

    
