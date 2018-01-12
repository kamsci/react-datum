React = require 'react'
ReactTest = require 'react-addons-test-utils'

Backbone = require 'backbone'
$ = require 'jquery'

Th = require './lib/testHelpers'
Number = require '../src/datums/number'


describe 'Number datum', ->
  model = new Backbone.Model({foo: 10})
  
  describe 'as input', ->
    component = Th.render <Number attr='foo' model={model} inputMode='edit'/>
    input = Th.findByTag(component, 'input')
    
    it 'should allow change to blank', ->  Th.changeDatumAndTestValid(component, "")
    

  describe 'as input with minValue prop', ->
    component = Th.render <Number attr='foo' model={model} inputMode='edit' minValue={10}/>

    it 'should have one input', -> Th.findByTag(component, 'input').length.should.be.equal(1)
    it 'should show as valid when equal to minValue', -> Th.changeDatumAndTestValid(component, 10)
    it 'should show invalid when less than minValue', -> Th.changeDatumAndTestValid(component, 3, false)


  describe 'as input with maxValue prop', ->
    component = Th.render <Number attr='foo' model={model} inputMode='edit' maxValue={10}/>

    it 'should show as valid when equal to maxValue',  -> Th.changeDatumAndTestValid(component, 10)
    it 'should show as valid when less than maxValue', -> Th.changeDatumAndTestValid(component, 3)
    it 'should show invalid when greater than maxValue', -> Th.changeDatumAndTestValid(component, 11, false)


  describe 'as display with comma format', ->
    component = Th.render <Number attr='foo' model={model} format="comma"/>
    domNode = Th.domNode(component)

    it 'should not have an input', -> Th.findByTag(component, 'input').length.should.be.equal(0)

    it 'should have tres commas for one billion', ->
      model.set('foo', 1000000000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("1,000,000,000")

    it 'should have two commas for one million plus a lot of decimal places', ->
      model.set('foo', 1000000.9882794274)
      component.forceUpdate()       
      $(domNode).find('.datum-display-value').text().should.be.equal("1,000,000.9882794274")
      
      
  describe 'as display with money format', ->
    component = Th.render <Number attr='foo' model={model} format="money"/>
    domNode = Th.domNode(component)

    it 'should add $ and two decimal places for one thousand', ->
      model.set('foo', 1000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$1000.00")
      
    it 'should round decimal places to two digits', ->
      model.set('foo', 1000.015)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("$1000.01")
      model.set('foo', 1000.016)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("$1000.02")
      
    
    
  describe 'as display with money and comma formats', ->
    component = Th.render <Number attr='foo' model={model} format={["money", "comma"]}/>
    domNode = Th.domNode(component)

    it 'should accept multiple formats', ->
      model.set('foo', 1000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$1,000.00")
    
    
  describe 'as display with money and abbreviate formats', ->
    component = Th.render <Number attr='foo' model={model} format={["money", "abbreviate"]}/>
    domNode = Th.domNode(component)

    it 'should properly abbreviate on million as money', ->
      model.set('foo', 1000000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$1 M")
        
    it 'should properly abbreviate on 5.5 billion as money without zero filling decimal places', ->
      model.set('foo', 5500000000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$5.5 B")
    
    it 'should properly abbreviate on -1,000,000 as money', ->
      model.set('foo', -1000000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$-1 M")
        
    it 'should properly abbreviate on -5.5 billion as money without zero filling decimal places', ->
      model.set('foo', -5500000000)
      component.forceUpdate()        # doesn't automatically update because it's not in a <Model> context
      $(domNode).find('.datum-display-value').text().should.be.equal("$-5.5 B")
    

  describe 'as display with percent format', ->
    component = Th.render <Number attr='foo' model={model} format='percent'/>
    domNode = Th.domNode(component)

    it 'should properly abbreviate on million as money', ->
      model.set('foo', 0.127)
      component.forceUpdate()       
      $(domNode).find('.datum-display-value').text().should.be.equal("12.7%")
    
    
  describe 'as display with 4 decimalPlaces', ->
    component = Th.render <Number attr='foo' model={model} decimalPlaces={4}/>
    domNode = Th.domNode(component)

    it 'should not zero fill out to 4 decimal places unless asked', ->
      model.set('foo', 0.127)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("0.127")
    
    it 'should round to 4 decimal places', ->
      model.set('foo', 0.12715415)
      component.forceUpdate()       
      $(domNode).find('.datum-display-value').text().should.be.equal("0.1272")
      model.set('foo', 0.12714615)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("0.1271")
    
  describe 'as display with 4 decimalPlaces zero filled', ->
    component = Th.render <Number attr='foo' model={model} decimalPlaces={4} zeroFill={true}/>
    domNode = Th.domNode(component)

    it 'should zero fill out to 4 decimal places when asked nicely', ->
      model.set('foo', 0.127)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("0.1270")
      

  describe 'as display with 4 decimalPlaces abbreviated', ->
    component = Th.render <Number attr='foo' model={model} format='abbreviate' decimalPlaces={4}/>
    domNode = Th.domNode(component)
    
    it 'should respect decimal places with really large number', ->
      model.set('foo', 1012505178.57)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("1.0125 B")

  describe 'as display with 4 decimalPlaces, money, abbreviated, with commas; multiple formats as string', ->
    component = Th.render <Number attr='foo' model={model} format='abbreviate money comma' decimalPlaces={4}/>
    domNode = Th.domNode(component)
    
    it 'should respect decimal places with really large number, abbreviate it and add commas', ->
      model.set('foo', 1012505178000.57)
      component.forceUpdate()        
      $(domNode).find('.datum-display-value').text().should.be.equal("$1,012.5052 B")
  
  
  describe 'as display with non-numeric input value', ->
    testValue = 'whatever'
    component = Th.render <Number value={testValue} format='abbreviate money comma' decimalPlaces={4}/>
    domNode = Th.domNode(component)
    
    it 'should have rendered non-numeric value', ->
      $(domNode).find('.datum-display-value').text().should.equal testValue
      
      
  describe 'as display with negative number', ->
    testValue = -5.099
    component = Th.render <Number value={testValue}/>
    domNode = Th.domNode(component)
    
    it 'should have rendered non-numeric value', ->
      $(domNode).find('.datum-display-value').text().should.equal testValue.toString()
    
  
  ###  
                            Input Tests (inputMode='edit')
  ###

    
  describe 'as input with numeric value', ->
    testValue = 12.99
    component = Th.render <Number inputMode='edit' value={testValue}/>
    domNode = Th.domNode(component)
    
    it "should have rendered an input with value set to testValue (#{testValue})", ->
      Th.testDatumInput component, testValue.toString()
      
      
  describe 'as input with non-numeric value', ->
    testValue = 'whatever'
    component = Th.render <Number inputMode='edit' value={testValue}/>
    domNode = Th.domNode(component)
    
    it "should have rendered an input with value set to blank", ->
      Th.testDatumInput(component, '')
      
    it 'should allow input of numerics', ->
      testValue = 123.456
      Th.changeDatumValue(component, '123.456', blur: true)
      component.getInputValue().should.equal testValue
    
    it 'should allow input of numeric with trailing decimal', ->
      testValue = "123."
      Th.changeDatumValue(component, testValue, blur: false)
      component.state.value.should.equal testValue
      Th.testDatumInput(component, testValue)
    
    it 'should not allow input of non-numerics', ->
      testValue = 'whatever'
      Th.changeDatumValue(component, testValue, blur: true)
      component.getInputValue().should.not.equal testValue
      

  describe 'as input with numeric string spaces and symbols', ->
    it 'should handle big numbers with commas and dollar signs', ->
      testValue = '$4,009.95'
      component = Th.render <Number inputMode='edit' value={testValue}/>
      domNode = Th.domNode(component)
      Th.testDatumInput(component, '4009.95')
    
    it 'should handle spaces', ->
      testValue = ' $409.95 '
      component = Th.render <Number inputMode='edit' value={testValue}/>
      domNode = Th.domNode(component)
      Th.testDatumInput(component, '409.95')
      
  
  describe 'as input with negative number', ->
    testFromTo = (initialValue, testValue) ->
      component = Th.render <Number inputMode='edit' value={initialValue}/>
      domNode = Th.domNode(component)
      $(domNode).find('input').val().should.equal initialValue.toString(), 'failed to set initial value'
      Th.changeDatumValue(component, testValue, blur: true)
      Th.testDatumInput(component, testValue)
      
    it 'should handle negative value in model and negative input', ->
      testFromTo(-6.99, -5.99)
      
    it 'should handle negative value in model and positive input', ->
      testFromTo(-5.99, 5.99)
      
    it 'should handle positive value in model and negative input', ->
      testFromTo(5.99, -4.99)
    
    
