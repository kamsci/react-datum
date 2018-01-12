React = require 'react'
Backbone = require 'backbone'
$ = require 'jquery'
_ = require 'underscore'

Th = require '../lib/testHelpers'
CollectionPicker = require '../../src/datums/collectionPicker/collectionPicker'

NameCollection = require('../lib/nameCollection')
nameCollection = new NameCollection()


addToStringAndTest = (component, nameModelId, shouldUseToString=true) ->
  nameModel = nameCollection.get(nameModelId)
  nameModel.toString = () -> return "Test of toString()"
  component.forceUpdate()
  domNode = Th.domNode(component)
  nameModel.toString = null
  if shouldUseToString
    $(domNode).find('.datum-display-value').text().should.be.equal "Test of toString()"
  else
    $(domNode).find('.datum-display-value').text().should.be.equal nameModel.get('name')


getRenderedNames = (domNode) ->
  renderedNames = ($(el).text() for el in $(domNode).find('.collection-picker-display-value'))


renderComponentAndTestNames = (model, extraProps, expectedNumberOfNames, expectedMaxNameLength) ->
  component = Th.render <CollectionPicker attr='nameId' displayAttr='name'
    model={model} collection={nameCollection} {... extraProps}/>
  domNode = Th.domNode(component)
  names = getRenderedNames(domNode)
  names.length.should.equal expectedNumberOfNames, 
    "wasn't expecting more than #{expectedNumberOfNames} rendered names: #{JSON.stringify(names)}"
  for name in names
    name.length.should.be.at.most expectedMaxNameLength
  return names



describe 'CollectionPicker inputMode=readonly as single select', ->
  
  describe 'without display attr prop', ->
    model = new Backbone.Model({nameId: 11})
    component = Th.render <CollectionPicker attr='nameId' model={model} collection={nameCollection}/>
    domNode = Th.domNode(component)

    it 'should not have an input', -> 
      Th.findByTag(component, 'input').length.should.be.equal(0)
    
    it 'should not have rendered "unknown"', ->
      $(domNode).find('.datum-display-value').text().should.not.be.equal("unknown")
    
    # default behavior when no nameAttr and no model.toString() is to render up the model
    it 'should render [object Object] without model.toString', -> 
      $(domNode).find('.datum-display-value').text().should.be.equal("[object Object]")
    it 'should render return of model.toString() when available', ->
      addToStringAndTest(component, 11)
    
    
  describe 'with display attr prop', ->
    model = new Backbone.Model({nameId: 22})
    component = Th.render <CollectionPicker attr='nameId' displayAttr='name'
      model={model} collection={nameCollection}    />
    domNode = Th.domNode(component)
    
    it 'should render name from model in nameCollection without model.toString', -> 
      $(domNode).find('.datum-display-value').text().should.be.equal(nameCollection.get(22).get('name'))
    # model.get(@prop.displayAttr) should have precedence over model to string
    it 'should not use model.toString() (props.attr should have precedence)', ->
      addToStringAndTest(component, 22, false)
      
      
  describe 'with really really long name', ->
    model = new Backbone.Model({nameId: 23})
    it 'should ellipsize at 35 by default', ->
      renderComponentAndTestNames(model, {}, 1, 35)
    it 'should respect ellipsizeAt=55 prop', ->
      renderComponentAndTestNames(model, {ellipsizeAt: 50}, 1, 50)
    it 'should respect ellipsizeAt=false prop', ->
      names = renderComponentAndTestNames(model, {ellipsizeAt: false}, 1, 999)
      maxNameLength = Math.max.apply(null, _.map(names, (name) -> name.length))
      maxNameLength.should.equal nameCollection.get(23).get('name').length
  

  describe 'with displayComponent prop', ->
    model = new Backbone.Model({nameId: 22})
    displayComponent = React.createClass 
      render: -> 
        <h3>Hello</h3>
        
    component = Th.render <CollectionPicker attr='nameId' displayAttr='name'
      model={model} collection={nameCollection} displayComponent={displayComponent}   />
    domNode = Th.domNode(component)
    
    it 'should render displayComponent', -> 
      $(domNode).find('.datum-display-value h3').text().should.equal('Hello')
      
      
      
describe 'CollectionPicker inputMode=readonly as multi select', ->
  model = new Backbone.Model({nameIds: [11, 22]})
  modelNames = (nameCollection.get(id).get('name') for id in [11, 22])
  component = Th.render <CollectionPicker attr='nameIds' displayAttr='name' multi
    model={model} collection={nameCollection}/>
  domNode = Th.domNode(component)

  it 'should not have an input', -> 
    Th.findByTag(component, 'input').length.should.be.equal(0)
  it 'should render names from models in nameCollection', -> 
    getRenderedNames(domNode).should.deep.equal(modelNames)
      
      
  describe 'with id not in name collection', ->
    before ->
      model.set 'nameIds', [11,22,99999]
      component.forceUpdate()
      
    it 'should render "unknown" for id not in nameCollection without placeholder prop', -> 
      getRenderedNames(domNode).should.deep.equal(modelNames.concat(['unknown']))
    it 'should render placeholder prop for id not in nameCollection', -> 
      placeholder = "long lost kitten"
      _domNode = Th.domNode(Th.render(<CollectionPicker attr='nameIds' displayAttr='name' multi
        placeholder={placeholder}
        model={model} collection={nameCollection}/>))
      getRenderedNames(_domNode).should.deep.equal(modelNames.concat([placeholder]))
      
      
  describe 'with really really long name', ->
    _model = new Backbone.Model({nameId: [22,23,1,2]})

    it 'should ellipsize at 35 by default', ->
      renderComponentAndTestNames(_model, {multi: true}, 4, 35)
    it 'should respect ellipsizeAt=55 prop', ->
      renderComponentAndTestNames(_model, {multi: true, ellipsizeAt: 50}, 4, 50)
    it 'should respect ellipsizeAt=false prop', ->
      names = renderComponentAndTestNames(_model, {multi: true, ellipsizeAt: false}, 4, 999)
      maxNameLength = Math.max.apply(null, _.map(names, (name) -> name.length))
      maxNameLength.should.equal nameCollection.get(23).get('name').length


describe 'CollectionPicker inputMode=readonly without a collection', ->
  model = new Backbone.Model({nameIds: [11, 22]})
  
  # TODO : we should probably add test and feature that the component at least displays the model attr value
  
  ## We don't throw an error any more; just a console warning. 
  # it 'should throw an error', ->
  #   fn = -> Th.render <CollectionPicker attr='nameIds' displayAttr='name' multi model={model}/>
  #   expect(fn).to.throw(Error)
    
    
describe 'CollectionPicker inputMode=readonly without a displayAttr or model.toString', ->
  model = new Backbone.Model({nameIds: [11, 22]})
  fn = -> Th.render <CollectionPicker attr='nameIds' multi model={model} collection={nameCollection}/>
  
  it 'should throw an error', ->
    expect(fn).to.throw(Error)
    
                
describe 'CollectionPicker with array as collection', ->
  model = new Backbone.Model({nameId: 22})
  arrayOfObjects = [
    {id: 11, name: "Mr. Cuddles" }
    {id: 22, name: "Sebastian"}
  ]
  component = Th.render <CollectionPicker attr='nameId' displayAttr='name' model={model} collection={arrayOfObjects}/>
  domNode = Th.domNode(component)
  names = getRenderedNames(domNode)

  it 'should have rendered display value', ->
    names.length.should.equal 1
    names[0].should.equal "Sebastian" 

        
    
      
      
      
      


